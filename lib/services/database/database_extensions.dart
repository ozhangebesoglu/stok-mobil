import '../../../core/utils/logger.dart';
import 'database_helper.dart';
import '../../core/exceptions/database_exception.dart' as core;

/// ✅ YENİ: Database extensions for missing functionality
/// Eksik tablolar ve metodlar için extension
extension DatabaseExtensions on DatabaseHelper {
  // ===== EXPENSES CRUD OPERATIONS =====

  /// Get all expenses from database
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    return await query(table: 'expenses', orderBy: 'date DESC');
  }

  /// Insert new expense
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    return await insert(table: 'expenses', values: expense);
  }

  /// Update existing expense
  Future<int> updateExpense(Map<String, dynamic> expense) async {
    final id = expense['id'];
    if (id == null) {
      throw core.DatabaseException('Expense ID is required for update');
    }
    return await update(
      table: 'expenses',
      values: expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete expense by ID
  Future<int> deleteExpense(int expenseId) async {
    return await delete(
      table: 'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  /// Get expenses by category
  Future<List<Map<String, dynamic>>> getExpensesByCategory(
    String category,
  ) async {
    return await query(
      table: 'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }

  /// Get expenses by date range
  Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await query(
      table: 'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
  }

  // ===== STOCK TRANSACTIONS CRUD OPERATIONS =====

  /// Get all stock transactions
  Future<List<Map<String, dynamic>>> getAllStockTransactions() async {
    return await query(table: 'stock_transactions', orderBy: 'date DESC');
  }

  /// Get stock transactions by product
  Future<List<Map<String, dynamic>>> getStockTransactionsByProduct(
    int productId,
  ) async {
    return await query(
      table: 'stock_transactions',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
  }

  /// Insert stock transaction
  Future<int> insertStockTransaction(Map<String, dynamic> transaction) async {
    return await insert(table: 'stock_transactions', values: transaction);
  }

  /// Get stock transactions by type
  Future<List<Map<String, dynamic>>> getStockTransactionsByType(
    String type,
  ) async {
    return await query(
      table: 'stock_transactions',
      where: 'transactionType = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
  }

  /// Get stock transactions by date range
  Future<List<Map<String, dynamic>>> getStockTransactionsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await query(
      table: 'stock_transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
  }

  // ===== VIEW QUERIES FOR REPORTING =====

  /// Get daily sales report
  Future<List<Map<String, dynamic>>> getDailySalesReport({
    int limit = 30,
  }) async {
    return await rawQuery('SELECT * FROM daily_sales_view LIMIT ?', [limit]);
  }

  /// Get monthly profit loss report
  Future<List<Map<String, dynamic>>> getMonthlyProfitLossReport({
    int limit = 12,
  }) async {
    return await rawQuery('SELECT * FROM monthly_profit_loss_view LIMIT ?', [
      limit,
    ]);
  }

  /// Get stock status report
  Future<List<Map<String, dynamic>>> getStockStatusReport() async {
    return await rawQuery('SELECT * FROM stock_status_view');
  }

  /// Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    return await rawQuery(
      "SELECT * FROM stock_status_view WHERE stock_status IN ('LOW_STOCK', 'OUT_OF_STOCK')",
    );
  }

  // ===== TRANSACTION-BASED OPERATIONS =====

  /// ✅ YENİ: Process complete sale transaction
  /// Satış, stok hareketi ve müşteri bakiyesi tek transaction'da
  Future<int> processSaleTransaction({
    required Map<String, dynamic> sale,
    required int productId,
    required double quantity,
    required double unitPrice,
  }) async {
    return await executeInTransaction((txn) async {
      // 1. Satış kaydı ekle
      final saleId = await txn.insert('sales', sale);

      // 2. Stok kontrolü
      final productResult = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (productResult.isEmpty) {
        throw core.DatabaseException('Product not found: $productId');
      }

      final currentStock = productResult.first['quantity'] as double;
      if (currentStock < quantity) {
        throw core.DatabaseException(
          'Insufficient stock. Available: $currentStock, Required: $quantity',
        );
      }

      // 3. Manuel stok hareketi kaydı (trigger'a ek güvenlik)
      await txn.insert('stock_transactions', {
        'productId': productId,
        'transactionType': 'OUT',
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': quantity * unitPrice,
        'date': sale['date'],
        'reason': 'SALE',
        'referenceId': saleId,
        'referenceType': 'SALE',
        'notes': 'Manual transaction record',
        'createdAt': DateTime.now().toIso8601String(),
      });

      Logger.database('Sale transaction completed: $saleId');
      return saleId;
    });
  }

  /// ✅ YENİ: Process stock adjustment
  /// Stok düzeltme işlemi (fire, kayıp, ekleme vs.)
  Future<void> processStockAdjustment({
    required int productId,
    required double adjustmentQuantity,
    required String reason,
    String? notes,
  }) async {
    await executeInTransaction((txn) async {
      // 1. Mevcut stok kontrolü
      final productResult = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (productResult.isEmpty) {
        throw core.DatabaseException('Product not found: $productId');
      }

      final currentStock = productResult.first['quantity'] as double;
      final newStock = currentStock + adjustmentQuantity;

      if (newStock < 0) {
        throw core.DatabaseException(
          'Stock cannot be negative. Current: $currentStock, Adjustment: $adjustmentQuantity',
        );
      }

      // 2. Stok güncelleme
      await txn.update(
        'products',
        {'quantity': newStock, 'lastUpdated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [productId],
      );

      // 3. Stok hareketi kaydı
      await txn.insert('stock_transactions', {
        'productId': productId,
        'transactionType': adjustmentQuantity > 0 ? 'IN' : 'OUT',
        'quantity': adjustmentQuantity.abs(),
        'date': DateTime.now().toIso8601String(),
        'reason': reason,
        'referenceType': 'MANUAL',
        'notes': notes ?? 'Stock adjustment',
        'createdAt': DateTime.now().toIso8601String(),
      });

      Logger.database('Stock adjustment completed for product: $productId');
    });
  }

  /// ✅ YENİ: Get comprehensive financial report
  /// Gelir-gider dengesi raporu
  Future<Map<String, dynamic>> getFinancialSummary({
    required String startDate,
    required String endDate,
  }) async {
    try {
      // Satış gelirleri
      final salesResult = await rawQuery(
        '''
        SELECT SUM(amount) as total_sales
        FROM sales 
        WHERE date BETWEEN ? AND ? AND isPaid = 1
      ''',
        [startDate, endDate],
      );

      // Manuel gelirler
      final manualIncomeResult = await rawQuery(
        '''
        SELECT SUM(amount) as total_manual_income
        FROM manual_incomes 
        WHERE date BETWEEN ? AND ?
      ''',
        [startDate, endDate],
      );

      // Restoran satışları
      final restaurantSalesResult = await rawQuery(
        '''
        SELECT SUM(amount) as total_restaurant_sales
        FROM restaurant_sales 
        WHERE date BETWEEN ? AND ?
      ''',
        [startDate, endDate],
      );

      // Giderler
      final expensesResult = await rawQuery(
        '''
        SELECT SUM(amount) as total_expenses
        FROM expenses 
        WHERE date BETWEEN ? AND ?
      ''',
        [startDate, endDate],
      );

      // Bekleyen alacaklar
      final pendingReceivablesResult = await rawQuery(
        '''
        SELECT SUM(amount) as pending_receivables
        FROM sales 
        WHERE date BETWEEN ? AND ? AND isPaid = 0
      ''',
        [startDate, endDate],
      );

      final totalSales = (salesResult.first['total_sales'] as double?) ?? 0.0;
      final totalManualIncome =
          (manualIncomeResult.first['total_manual_income'] as double?) ?? 0.0;
      final totalRestaurantSales =
          (restaurantSalesResult.first['total_restaurant_sales'] as double?) ??
          0.0;
      final totalExpenses =
          (expensesResult.first['total_expenses'] as double?) ?? 0.0;
      final pendingReceivables =
          (pendingReceivablesResult.first['pending_receivables'] as double?) ??
          0.0;

      final totalIncome = totalSales + totalManualIncome + totalRestaurantSales;
      final netProfit = totalIncome - totalExpenses;

      return {
        'period': '$startDate - $endDate',
        'total_sales': totalSales,
        'manual_income': totalManualIncome,
        'restaurant_sales': totalRestaurantSales,
        'total_income': totalIncome,
        'total_expenses': totalExpenses,
        'net_profit': netProfit,
        'pending_receivables': pendingReceivables,
        'profit_margin':
            totalIncome > 0 ? (netProfit / totalIncome * 100) : 0.0,
      };
    } catch (e) {
      throw core.DatabaseException(
        'Financial summary query failed',
        originalException: e,
      );
    }
  }

  // ===== MIGRATION HELPERS =====

  /// ✅ YENİ: Check if new tables exist
  Future<bool> checkTableExists(String tableName) async {
    try {
      final result = await rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ✅ YENİ: Create missing tables for upgrade
  Future<void> createMissingTablesV10() async {
    await executeInTransaction((txn) async {
      // Expenses table
      if (!await checkTableExists('expenses')) {
        await txn.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            notes TEXT,
            receiptNumber TEXT,
            isRecurring INTEGER DEFAULT 0,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }

      // Stock transactions table
      if (!await checkTableExists('stock_transactions')) {
        await txn.execute('''
          CREATE TABLE stock_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            transactionType TEXT NOT NULL,
            quantity REAL NOT NULL,
            unitPrice REAL,
            totalAmount REAL,
            date TEXT NOT NULL,
            reason TEXT,
            referenceId INTEGER,
            referenceType TEXT,
            notes TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
          )
        ''');
      }

      Logger.database('Missing tables created successfully');
    });
  }
}
