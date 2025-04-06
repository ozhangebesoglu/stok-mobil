import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database/database_helper.dart';

class StockProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    _products = List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final db = await _dbHelper.database;
    final id = await db.insert('products', product.toMap());
    final newProduct = Product(
      id: id,
      name: product.name,
      category: product.category,
      quantity: product.quantity,
      unit: product.unit,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
    );
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    _products.removeWhere((product) => product.id == id);
    notifyListeners();
  }

  Future<void> updateStock(int productId, double amount) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newQuantity = product.quantity + amount;

    if (newQuantity < 0) {
      throw Exception('Stok miktarı negatif olamaz!');
    }

    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      quantity: newQuantity,
      unit: product.unit,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
    );

    await updateProduct(updatedProduct);
  }
}
