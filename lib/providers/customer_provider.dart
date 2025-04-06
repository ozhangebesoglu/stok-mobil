import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database/database_helper.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Customer> _customers = [];

  List<Customer> get customers => _customers;

  Future<void> loadCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    _customers = List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final id = await db.insert('customers', customer.toMap());
    final newCustomer = Customer(
      id: id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      balance: customer.balance,
    );
    _customers.add(newCustomer);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      final db = await _dbHelper.database;

      // Müşterinin ilişkili satışlarını kontrol et
      final salesCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE customerId = ?',
        [id],
      );
      final int count = salesCount.first['count'] as int;

      // Müşteriyi veritabanından sil
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);

      // İlişkili satışları anonim hale getir
      if (count > 0) {
        await db.update(
          'sales',
          {'customerId': null, 'customerName': 'Silinmiş Müşteri'},
          where: 'customerId = ?',
          whereArgs: [id],
        );
      }

      // Lokal listeden de kaldır
      _customers.removeWhere((customer) => customer.id == id);
      notifyListeners();
    } catch (e) {
      print('Müşteri silinirken hata: $e');
      throw Exception('Müşteri silinirken bir hata oluştu: $e');
    }
  }

  Future<void> updateBalance(int customerId, double amount) async {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final newBalance = customer.balance + amount;

    final updatedCustomer = Customer(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      balance: newBalance,
    );

    await updateCustomer(updatedCustomer);
  }
}
