import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/database/database_helper.dart';

class SalesProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Sale> _sales = [];

  List<Sale> get sales => _sales;

  Future<void> loadSales() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sales');
    _sales = List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
    notifyListeners();
  }

  Future<void> addSale(Sale sale) async {
    final db = await _dbHelper.database;
    final id = await db.insert('sales', sale.toMap());
    final newSale = Sale(
      id: id,
      customerId: sale.customerId,
      customerName: sale.customerName,
      amount: sale.amount,
      date: sale.date,
      isPaid: sale.isPaid,
      productId: sale.productId,
      productName: sale.productName,
      quantity: sale.quantity,
      unit: sale.unit,
      unitPrice: sale.unitPrice,
      notes: sale.notes,
    );
    _sales.add(newSale);
    notifyListeners();
  }

  Future<void> updateSale(Sale sale) async {
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );

    final index = _sales.indexWhere((s) => s.id == sale.id);
    if (index != -1) {
      _sales[index] = sale;
      notifyListeners();
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('sales', where: 'id = ?', whereArgs: [id]);
      _sales.removeWhere((sale) => sale.id == id);
      notifyListeners();
    } catch (e) {
      print('Satış silinirken hata: $e');
      throw e; // Hatayı yukarıya ilet
    }
  }

  Future<List<Sale>> getCustomerSales(int customerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'customerId = ?',
      whereArgs: [customerId],
    );

    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  Future<double> getTotalSalesAmount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM sales',
      );
      if (result.isEmpty || result.first['total'] == null) {
        return 0.0;
      }

      // SQLite'da sayısal değerler bazen int olarak dönebiliyor
      final totalValue = result.first['total'];
      if (totalValue is int) {
        return totalValue.toDouble();
      } else if (totalValue is double) {
        return totalValue;
      } else {
        return 0.0;
      }
    } catch (e) {
      print('Toplam satış tutarı hesaplanırken hata: $e');
      return 0.0;
    }
  }
}
