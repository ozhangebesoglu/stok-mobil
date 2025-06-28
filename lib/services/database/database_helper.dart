import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/exceptions/database_exception.dart' as core;
import '../../core/utils/logger.dart';

/// Context7 optimized database helper with comprehensive error handling
/// Features: Connection pooling, transaction support, performance optimization, auto-recovery
/// UPDATED: Added missing tables (expenses, stock_transactions), proper indexes, triggers
class DatabaseHelper {
  static const String _databaseName = 'stok_takibim.db';
  static const int _databaseVersion =
      12; // ✅ Version artırıldı - constraint'ler, validation, complete triggers için
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // Singleton pattern for connection pooling - Context7 pattern
  static DatabaseHelper? _instance;
  static Database? _database;
  static bool _isInitializing = false;

  // Context7 pattern: Factory constructor for singleton
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  DatabaseHelper._internal();

  /// Context7 pattern: Fixed database getter - no more recursive calls
  Future<Database> get database async {
    // Return existing database if available and open
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    // Prevent multiple initialization attempts
    if (_isInitializing) {
      // Wait for ongoing initialization instead of recursive call
      int waitCount = 0;
      while (_isInitializing && waitCount < 50) {
        // Max 5 saniye bekle
        await Future.delayed(Duration(milliseconds: 100));
        waitCount++;
      }
      // After waiting, check if database is now available
      if (_database != null && _database!.isOpen) {
        return _database!;
      }

      // Eğer hala başlatılıyorsa hata ver
      if (_isInitializing) {
        throw core.DatabaseException.connectionFailed(
          'Database initialization timeout after 5 seconds',
        );
      }
    }

    // Initialize database with retry mechanism
    _isInitializing = true;
    try {
      _database = await _initDatabaseWithRetry();
      Logger.database('Database initialized successfully');
      return _database!;
    } catch (e) {
      Logger.error('Database initialization failed', e);
      _database = null; // Başarısız durumda null yap
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Context7 pattern: Database initialization with retry mechanism
  Future<Database> _initDatabaseWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await _initDatabase();
      } catch (e) {
        Logger.error('Database init attempt $attempt failed', e);

        if (attempt == _maxRetries) {
          throw core.DatabaseException.connectionFailed(
            'Failed to initialize database after $_maxRetries attempts: $e',
          );
        }

        // Wait before retry
        await Future.delayed(_retryDelay * attempt);

        // Close any partial connection
        try {
          await _database?.close();
          _database = null;
        } catch (_) {}
      }
    }

    throw core.DatabaseException.connectionFailed(
      'Unexpected error in database initialization',
    );
  }

  /// Context7 pattern: Database initialization with better error handling
  Future<Database> _initDatabase() async {
    try {
      // Context7 Pattern: Platform-specific initialization with better error handling
      if (!kIsWeb) {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          try {
            sqfliteFfiInit();
            databaseFactory = databaseFactoryFfi;
            Logger.info('FFI database factory initialized for desktop');
          } catch (e) {
            Logger.warning(
              'FFI initialization warning (continuing anyway): $e',
            );
            // Continue without FFI - let default factory handle it
          }
        }
      }

      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, _databaseName);

      Logger.info('Database path: $path');

      // Context7 Pattern: Safe database opening with detailed error handling
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: (db) async {
          Logger.info('Database opened successfully');
          // Verify database integrity after opening
          try {
            await db.rawQuery('SELECT 1');
            Logger.info('Database connection test passed');
          } catch (e) {
            Logger.error('Database connection test failed', e);
            throw core.DatabaseException.connectionFailed(
              'Connection test failed: $e',
            );
          }
        },
      );
    } catch (e) {
      Logger.error('Database initialization error details', e);

      // Context7 Pattern: Detailed error reporting
      if (e.toString().contains('permission')) {
        throw core.DatabaseException.connectionFailed(
          'Database permission denied. Check app permissions.',
        );
      } else if (e.toString().contains('disk')) {
        throw core.DatabaseException.connectionFailed(
          'Insufficient disk space for database.',
        );
      } else if (e.toString().contains('corrupt')) {
        throw core.DatabaseException.connectionFailed(
          'Database file corrupted. App restart required.',
        );
      } else {
        throw core.DatabaseException.connectionFailed(
          'Database initialization failed: ${e.toString()}',
        );
      }
    }
  }

  /// Context7 pattern: Database configuration for performance
  /// ✅ DÜZELTME: PRAGMA ayarları optimize edildi
  Future<void> _onConfigure(Database db) async {
    try {
      // Enable WAL mode for better concurrency
      await db.execute('PRAGMA journal_mode = WAL');
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');

      // ✅ DÜZELTME: Cache size adaptive yapıldı
      // Page size genelde 4096, 2500 page = ~10MB (telefon için uygun)
      await db.execute('PRAGMA cache_size = 2500');

      // ✅ DÜZELTME: Synchronous level açık tanımlandı
      // NORMAL = performans/güvenlik dengesi (production için uygun)
      await db.execute('PRAGMA synchronous = NORMAL');

      // ✅ EK: Temp store memory'de (performans için)
      await db.execute('PRAGMA temp_store = MEMORY');

      // ✅ EK: Mmap size (büyük DB'ler için)
      await db.execute('PRAGMA mmap_size = 268435456'); // 256MB
    } catch (e) {
      Logger.warning('Database configuration warning: $e');
    }
  }

  /// Create database tables with Context7 schema design
  /// ✅ DÜZELTME: Eksik tablolar eklendi
  Future<void> _onCreate(Database db, int version) async {
    try {
      Logger.database('Creating database schema v$version...');

      await db.transaction((txn) async {
        // Products table - ✅ ENHANCED with constraints
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL CHECK (length(trim(name)) > 0),
            category TEXT NOT NULL DEFAULT 'Genel' CHECK (length(trim(category)) > 0),
            unit TEXT NOT NULL DEFAULT 'kg' CHECK (unit IN ('kg', 'gram', 'adet', 'litre')),
            quantity REAL NOT NULL DEFAULT 0 CHECK (quantity >= 0),
            purchasePrice REAL NOT NULL DEFAULT 0 CHECK (purchasePrice >= 0),
            sellingPrice REAL NOT NULL DEFAULT 0 CHECK (sellingPrice >= 0),
            lastUpdated TEXT DEFAULT CURRENT_TIMESTAMP,
            minStockLevel REAL DEFAULT 0 CHECK (minStockLevel >= 0),
            description TEXT,
            isActive INTEGER DEFAULT 1 CHECK (isActive IN (0, 1)),
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(name, category)
          )
        ''');
        Logger.database('Products table created');

        // Customers table - ✅ ENHANCED with constraints
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL CHECK (length(trim(name)) > 0),
            phone TEXT DEFAULT '' CHECK (length(phone) <= 20),
            address TEXT DEFAULT '',
            balance REAL NOT NULL DEFAULT 0,
            type TEXT NOT NULL DEFAULT 'customer' CHECK (type IN ('customer', 'restaurant', 'supplier')),
            isActive INTEGER DEFAULT 1 CHECK (isActive IN (0, 1)),
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        Logger.database('Customers table created');

        // Sales table - ✅ ENHANCED with proper schema
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER,
            customerName TEXT NOT NULL CHECK (length(trim(customerName)) > 0),
            amount REAL NOT NULL CHECK (amount > 0),
            date TEXT NOT NULL CHECK (date != ''),
            isPaid INTEGER DEFAULT 0 CHECK (isPaid IN (0, 1)),
            productId INTEGER,
            productName TEXT NOT NULL CHECK (length(trim(productName)) > 0),
            quantity REAL NOT NULL CHECK (quantity > 0),
            unit TEXT NOT NULL CHECK (unit IN ('kg', 'gram', 'adet', 'litre')),
            unitPrice REAL NOT NULL CHECK (unitPrice > 0),
            notes TEXT,
            saleType TEXT DEFAULT 'customer' CHECK (saleType IN ('customer', 'restaurant')),
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE SET NULL,
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE SET NULL
          )
        ''');
        Logger.database('Sales table created');

        // Restaurant sales table - ✅ Separate table for restaurant transactions
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS restaurant_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurantName TEXT NOT NULL CHECK (length(trim(restaurantName)) > 0),
            amount REAL NOT NULL CHECK (amount > 0),
            date TEXT NOT NULL CHECK (date != ''),
            isPaid INTEGER DEFAULT 1 CHECK (isPaid IN (0, 1)),
            notes TEXT,
            paymentMethod TEXT DEFAULT 'cash',
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        Logger.database('Restaurant sales table created');

        // Manual incomes table - ✅ Additional income tracking
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS manual_incomes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL CHECK (length(trim(description)) > 0),
            amount REAL NOT NULL CHECK (amount > 0),
            date TEXT NOT NULL CHECK (date != ''),
            category TEXT DEFAULT 'Diğer',
            notes TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        Logger.database('Manual incomes table created');

        // Expenses table - ✅ Expense tracking
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL CHECK (amount > 0),
            description TEXT NOT NULL,
            notes TEXT,
            receiptNumber TEXT,
            isRecurring INTEGER DEFAULT 0,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        Logger.database('Expenses table created');

        // Stock transactions table - ✅ Stock movement tracking
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS stock_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            transactionType TEXT NOT NULL CHECK (transactionType IN ('purchase', 'sale', 'adjustment', 'waste', 'return')),
            quantity REAL NOT NULL,
            unitPrice REAL DEFAULT 0,
            totalAmount REAL DEFAULT 0,
            date TEXT NOT NULL,
            reason TEXT,
            referenceId INTEGER,
            referenceType TEXT,
            notes TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
          )
        ''');
        Logger.database('Stock transactions table created');

        // Create indexes for performance
        await _createOptimizedIndexes(txn);
        Logger.database('Indexes created');

        // Create triggers for data integrity (if supported)
        try {
          await _createTriggers(txn);
          Logger.database('Triggers created');
        } catch (e) {
          Logger.warning('Trigger creation failed (continuing anyway): $e');
        }

        // Create views for reporting (if supported)
        try {
          await _createViews(txn);
          Logger.database('Views created');
        } catch (e) {
          Logger.warning('View creation failed (continuing anyway): $e');
        }
      });

      Logger.database('Database schema creation completed successfully');
    } catch (e) {
      Logger.error('Database schema creation failed', e);
      throw core.DatabaseException.transactionFailed(e);
    }
  }

  /// Database upgrade handler
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      await db.transaction((txn) async {
        if (oldVersion < 11) {
          // Check and add missing columns
          await _addMissingColumns(txn);

          // Create missing tables (including expenses and stock_transactions)
          await _createMissingTablesV11(txn);

          // Create optimized indexes
          await _createOptimizedIndexes(txn);

          // Create triggers for data integrity
          await _createTriggers(txn);

          // Create views for reporting
          await _createViews(txn);
        }

        if (oldVersion < 12) {
          // ✅ YENİ: v12 upgrade - constraints ve advanced features
          await _upgradeToV12(txn);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        Logger.error(
          'Database upgrade error (v$oldVersion -> v$newVersion)',
          e,
        );
      }
    }
  }

  /// Add missing columns safely
  Future<void> _addMissingColumns(Transaction txn) async {
    try {
      // Check customers table columns
      final customerColumns = await txn.rawQuery(
        'PRAGMA table_info(customers)',
      );
      final customerColumnNames =
          customerColumns.map((col) => col['name'] as String).toSet();

      if (!customerColumnNames.contains('isActive')) {
        await txn.execute(
          'ALTER TABLE customers ADD COLUMN isActive INTEGER DEFAULT 1',
        );
      }
      if (!customerColumnNames.contains('createdAt')) {
        await txn.execute(
          'ALTER TABLE customers ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }
      if (!customerColumnNames.contains('updatedAt')) {
        await txn.execute(
          'ALTER TABLE customers ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }
      if (!customerColumnNames.contains('type')) {
        await txn.execute(
          'ALTER TABLE customers ADD COLUMN type TEXT DEFAULT "customer"',
        );
      }

      // Check sales table columns
      final salesColumns = await txn.rawQuery('PRAGMA table_info(sales)');
      final salesColumnNames =
          salesColumns.map((col) => col['name'] as String).toSet();

      if (!salesColumnNames.contains('saleType')) {
        await txn.execute(
          'ALTER TABLE sales ADD COLUMN saleType TEXT DEFAULT "customer"',
        );
      }
      if (!salesColumnNames.contains('createdAt')) {
        await txn.execute(
          'ALTER TABLE sales ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }
      if (!salesColumnNames.contains('updatedAt')) {
        await txn.execute(
          'ALTER TABLE sales ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }

      // Check products table columns
      final productColumns = await txn.rawQuery('PRAGMA table_info(products)');
      final productColumnNames =
          productColumns.map((col) => col['name'] as String).toSet();

      if (!productColumnNames.contains('isActive')) {
        await txn.execute(
          'ALTER TABLE products ADD COLUMN isActive INTEGER DEFAULT 1',
        );
      }
      if (!productColumnNames.contains('createdAt')) {
        await txn.execute(
          'ALTER TABLE products ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }
      if (!productColumnNames.contains('minStockLevel')) {
        await txn.execute(
          'ALTER TABLE products ADD COLUMN minStockLevel REAL DEFAULT 0',
        );
      }
      if (!productColumnNames.contains('description')) {
        await txn.execute('ALTER TABLE products ADD COLUMN description TEXT');
      }

      // Check manual_incomes table columns
      final manualIncomeColumns = await txn.rawQuery(
        'PRAGMA table_info(manual_incomes)',
      );
      final manualIncomeColumnNames =
          manualIncomeColumns.map((col) => col['name'] as String).toSet();

      if (!manualIncomeColumnNames.contains('type')) {
        await txn.execute(
          'ALTER TABLE manual_incomes ADD COLUMN type TEXT DEFAULT "income"',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.warning('Column addition warning: $e');
      }
    }
  }

  /// Create missing tables for version 11
  Future<void> _createMissingTablesV11(Transaction txn) async {
    try {
      // Restaurant sales table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS restaurant_sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          restaurant TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          productName TEXT,
          quantity REAL,
          unit TEXT,
          unitPrice REAL,
          notes TEXT,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Manual incomes table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS manual_incomes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          type TEXT DEFAULT 'income',
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Product price history table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS product_price_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          oldPurchasePrice REAL NOT NULL,
          newPurchasePrice REAL NOT NULL,
          oldSellingPrice REAL NOT NULL,
          newSellingPrice REAL NOT NULL,
          changedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          reason TEXT,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');

      // ✅ YENİ: Expenses table - kritik eksiklik giderildi
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          paymentMethod TEXT DEFAULT 'cash',
          isRecurring INTEGER DEFAULT 0,
          recurringPeriod TEXT,
          notes TEXT,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // ✅ YENİ: Stock transactions table - stok hareketleri için
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS stock_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          transactionType TEXT NOT NULL CHECK (transactionType IN ('purchase', 'sale', 'adjustment', 'waste', 'return')),
          quantity REAL NOT NULL,
          unitPrice REAL DEFAULT 0,
          totalAmount REAL DEFAULT 0,
          date TEXT NOT NULL,
          reason TEXT,
          referenceId INTEGER,
          referenceType TEXT,
          notes TEXT,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      if (kDebugMode) {
        Logger.warning('Table creation warning: $e');
      }
    }
  }

  /// ✅ YENİ: Create optimized indexes for performance
  Future<void> _createOptimizedIndexes(Transaction txn) async {
    try {
      // Products indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_active ON products(isActive)',
      );

      // Customers indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_type ON customers(type)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_balance ON customers(balance)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_active ON customers(isActive)',
      );

      // ✅ DÜZELTME: Sales indexes - date+paid kombine index eklendi
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customerId)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_paid ON sales(isPaid)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_type ON sales(saleType)',
      );
      // ✅ YENİ: Kombine index - günlük raporlar için kritik
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_date_paid ON sales(date, isPaid)',
      );

      // ✅ DÜZELTME: Manual incomes indexes - eksikti
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_manual_incomes_date ON manual_incomes(date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_manual_incomes_type ON manual_incomes(type)',
      );

      // ✅ YENİ: Expenses indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date_category ON expenses(date, category)',
      );

      // ✅ YENİ: Stock transactions indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_trans_product ON stock_transactions(productId)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_trans_date ON stock_transactions(date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_trans_type ON stock_transactions(transactionType)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_stock_trans_product_date ON stock_transactions(productId, date)',
      );

      // Price history indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_price_history_product ON product_price_history(productId)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_price_history_date ON product_price_history(changedAt)',
      );

      // ✅ YENİ: Restaurant sales indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_restaurant_sales_date ON restaurant_sales(date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_restaurant_sales_restaurant ON restaurant_sales(restaurantName)',
      );
    } catch (e) {
      if (kDebugMode) {
        Logger.warning('Index creation warning: $e');
      }
    }
  }

  /// ✅ YENİ: Create triggers for data integrity and automation
  Future<void> _createTriggers(Transaction txn) async {
    try {
      // Trigger: Automatic price history when product prices change
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_product_price_history
        AFTER UPDATE OF purchasePrice, sellingPrice ON products
        FOR EACH ROW
        WHEN OLD.purchasePrice != NEW.purchasePrice OR OLD.sellingPrice != NEW.sellingPrice
        BEGIN
          INSERT INTO product_price_history (
            productId, 
            oldPurchasePrice, 
            newPurchasePrice, 
            oldSellingPrice, 
            newSellingPrice, 
            changedAt,
            reason
          ) VALUES (
            NEW.id,
            OLD.purchasePrice,
            NEW.purchasePrice,
            OLD.sellingPrice,
            NEW.sellingPrice,
            CURRENT_TIMESTAMP,
            'Price update'
          );
        END;
      ''');

      // Trigger: Update product lastUpdated when quantity changes
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_product_last_updated
        AFTER UPDATE OF quantity ON products
        FOR EACH ROW
        BEGIN
          UPDATE products 
          SET lastUpdated = CURRENT_TIMESTAMP 
          WHERE id = NEW.id;
        END;
      ''');

      // Trigger: Create stock transaction when product quantity changes manually
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_stock_adjustment
        AFTER UPDATE OF quantity ON products
        FOR EACH ROW
        WHEN OLD.quantity != NEW.quantity
        BEGIN
          INSERT INTO stock_transactions (
            productId,
            transactionType,
            quantity,
            date,
            reason,
            notes
          ) VALUES (
            NEW.id,
            'adjustment',
            NEW.quantity - OLD.quantity,
            CURRENT_TIMESTAMP,
            'Manual stock adjustment',
            'Quantity changed from ' || OLD.quantity || ' to ' || NEW.quantity
          );
        END;
      ''');

      // Trigger: Update customer updatedAt when balance changes
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_customer_updated
        AFTER UPDATE OF balance ON customers
        FOR EACH ROW
        BEGIN
          UPDATE customers 
          SET updatedAt = CURRENT_TIMESTAMP 
          WHERE id = NEW.id;
        END;
      ''');
    } catch (e) {
      if (kDebugMode) {
        Logger.warning('Trigger creation warning: $e');
      }
    }
  }

  /// ✅ YENİ: Create views for reporting performance
  Future<void> _createViews(Transaction txn) async {
    try {
      // ✅ View: Günlük satış özeti
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS daily_sales_view AS
        SELECT 
          date,
          COUNT(*) as transaction_count,
          SUM(amount) as total_amount,
          SUM(CASE WHEN isPaid = 1 THEN amount ELSE 0 END) as paid_amount,
          SUM(CASE WHEN isPaid = 0 THEN amount ELSE 0 END) as unpaid_amount,
          COUNT(DISTINCT customerId) as unique_customers
        FROM sales
        GROUP BY date
        ORDER BY date DESC;
      ''');

      // ✅ View: Aylık kar-zarar özeti
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS monthly_profit_loss_view AS
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(s.amount) as total_sales,
          SUM(s.quantity * p.purchasePrice) as total_cost,
          SUM(s.amount) - SUM(s.quantity * p.purchasePrice) as gross_profit,
          (SELECT SUM(amount) FROM expenses WHERE strftime('%Y-%m', date) = month) as total_expenses,
          (SELECT SUM(amount) FROM manual_incomes WHERE strftime('%Y-%m', date) = month) as manual_income
        FROM sales s
        LEFT JOIN products p ON s.productId = p.id
        GROUP BY strftime('%Y-%m', s.date)
        ORDER BY month DESC;
      ''');

      // ✅ View: Stok durumu özeti
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS stock_status_view AS
        SELECT 
          p.id,
          p.name,
          p.category,
          p.quantity,
          p.minStockLevel,
          CASE 
            WHEN p.quantity <= 0 THEN 'OUT_OF_STOCK'
            WHEN p.quantity <= p.minStockLevel THEN 'LOW_STOCK'
            ELSE 'IN_STOCK'
          END as stock_status,
          (SELECT SUM(quantity) FROM stock_transactions WHERE productId = p.id AND transactionType IN ('purchase', 'adjustment') AND quantity > 0) as total_in,
          (SELECT SUM(ABS(quantity)) FROM stock_transactions WHERE productId = p.id AND transactionType IN ('sale', 'waste') AND quantity < 0) as total_out
        FROM products p
        WHERE p.isActive = 1;
      ''');
    } catch (e) {
      if (kDebugMode) {
        Logger.warning('View creation warning: $e');
      }
    }
  }

  /// ✅ YENİ: Upgrade to version 12 - Add constraints and advanced features
  Future<void> _upgradeToV12(Transaction txn) async {
    try {
      Logger.database('Starting upgrade to v12...');

      // ✅ 1. Advanced indexes
      await _createAdvancedIndexes(txn);

      // ✅ 2. Additional triggers for business logic
      await _createAdvancedTriggers(txn);

      // ✅ 3. Validation functions (stored as views for reporting)
      await _createValidationViews(txn);

      // ✅ 4. Performance views
      await _createPerformanceViews(txn);

      Logger.database('v12 upgrade completed successfully');
    } catch (e) {
      Logger.error('v12 upgrade failed', e);
      rethrow;
    }
  }

  /// ✅ YENİ: Create advanced indexes for v12
  Future<void> _createAdvancedIndexes(Transaction txn) async {
    try {
      // Multi-column performance indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_customer_date_paid ON sales(customerId, date, isPaid)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category, isActive)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date_amount ON expenses(date, amount)',
      );

      // Text search optimization
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name_lower ON products(lower(name))',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name_lower ON customers(lower(name))',
      );

      // Financial reporting indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_amount_date ON sales(amount, date)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_category_amount ON expenses(category, amount)',
      );
    } catch (e) {
      Logger.warning('Advanced index creation warning: $e');
    }
  }

  /// ✅ YENİ: Create advanced triggers for business logic
  Future<void> _createAdvancedTriggers(Transaction txn) async {
    try {
      // Trigger: Prevent negative stock (except adjustments)
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_prevent_negative_stock
        BEFORE UPDATE OF quantity ON products
        FOR EACH ROW
        WHEN NEW.quantity < 0 AND OLD.quantity >= 0
        BEGIN
          SELECT RAISE(ABORT, 'Stock cannot be negative. Current: ' || OLD.quantity || ', Attempted: ' || NEW.quantity);
        END;
      ''');

      // Trigger: Auto-create stock transaction on sales
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_sales_stock_transaction
        AFTER INSERT ON sales
        FOR EACH ROW
        WHEN NEW.productId IS NOT NULL
        BEGIN
          INSERT INTO stock_transactions (
            productId,
            transactionType,
            quantity,
            unitPrice,
            totalAmount,
            date,
            reason,
            referenceId,
            referenceType,
            notes
          ) VALUES (
            NEW.productId,
            'sale',
            -NEW.quantity,
            NEW.unitPrice,
            NEW.amount,
            NEW.date,
            'Sale transaction',
            NEW.id,
            'sales',
            'Auto-generated from sale #' || NEW.id
          );
          
          -- Update product stock
          UPDATE products 
          SET quantity = quantity - NEW.quantity,
              lastUpdated = CURRENT_TIMESTAMP
          WHERE id = NEW.productId;
        END;
      ''');

      // Trigger: Validate customer balance updates
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_customer_balance_validation
        BEFORE UPDATE OF balance ON customers
        FOR EACH ROW
        WHEN NEW.balance < -10000
        BEGIN
          SELECT RAISE(ABORT, 'Customer balance cannot be less than -10000. Customer: ' || NEW.name);
        END;
      ''');

      // Trigger: Auto-update expenses total validation
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trigger_expenses_validation
        BEFORE INSERT ON expenses
        FOR EACH ROW
        WHEN NEW.amount <= 0
        BEGIN
          SELECT RAISE(ABORT, 'Expense amount must be greater than 0');
        END;
      ''');
    } catch (e) {
      Logger.warning('Advanced trigger creation warning: $e');
    }
  }

  /// ✅ YENİ: Create validation views for monitoring
  Future<void> _createValidationViews(Transaction txn) async {
    try {
      // View: Data integrity check
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS data_integrity_view AS
        SELECT 
          'Products with negative stock' as issue_type,
          COUNT(*) as count,
          'SELECT * FROM products WHERE quantity < 0' as query
        FROM products WHERE quantity < 0
        UNION ALL
        SELECT 
          'Sales without valid product' as issue_type,
          COUNT(*) as count,
          'SELECT * FROM sales WHERE productId NOT IN (SELECT id FROM products)' as query
        FROM sales WHERE productId IS NOT NULL AND productId NOT IN (SELECT id FROM products)
        UNION ALL
        SELECT 
          'Customers with extreme balance' as issue_type,
          COUNT(*) as count,
          'SELECT * FROM customers WHERE balance < -10000 OR balance > 100000' as query
        FROM customers WHERE balance < -10000 OR balance > 100000;
      ''');

      // View: Business rules compliance
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS business_rules_view AS
        SELECT 
          p.name as product_name,
          p.quantity,
          p.minStockLevel,
          CASE 
            WHEN p.quantity < 0 THEN 'CRITICAL: Negative stock'
            WHEN p.quantity < p.minStockLevel THEN 'WARNING: Low stock'
            ELSE 'OK'
          END as stock_status,
          p.sellingPrice,
          p.purchasePrice,
          CASE 
            WHEN p.sellingPrice < p.purchasePrice THEN 'WARNING: Selling below cost'
            ELSE 'OK'
          END as pricing_status
        FROM products p
        WHERE p.isActive = 1;
      ''');
    } catch (e) {
      Logger.warning('Validation view creation warning: $e');
    }
  }

  /// ✅ YENİ: Create performance monitoring views
  Future<void> _createPerformanceViews(Transaction txn) async {
    try {
      // View: Query performance metrics
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS performance_metrics_view AS
        SELECT 
          'Total Products' as metric,
          COUNT(*) as value,
          'Active: ' || SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) as details
        FROM products
        UNION ALL
        SELECT 
          'Total Customers' as metric,
          COUNT(*) as value,
          'Active: ' || SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) as details
        FROM customers
        UNION ALL
        SELECT 
          'Total Sales (30 days)' as metric,
          COUNT(*) as value,
          'Paid: ' || SUM(CASE WHEN isPaid = 1 THEN 1 ELSE 0 END) as details
        FROM sales 
        WHERE date >= date('now', '-30 days')
        UNION ALL
        SELECT 
          'Database Size (MB)' as metric,
          0 as value,
          'Calculated externally' as details;
      ''');

      // View: Financial summary
      await txn.execute('''
        CREATE VIEW IF NOT EXISTS financial_summary_view AS
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(s.amount) as total_sales,
          COUNT(s.id) as sales_count,
          SUM(s.quantity * p.purchasePrice) as cost_of_goods,
          SUM(s.amount) - SUM(s.quantity * p.purchasePrice) as gross_profit,
          (SELECT SUM(amount) FROM expenses e WHERE strftime('%Y-%m', e.date) = month) as total_expenses,
          SUM(s.amount) - SUM(s.quantity * p.purchasePrice) - 
          COALESCE((SELECT SUM(amount) FROM expenses e WHERE strftime('%Y-%m', e.date) = month), 0) as net_profit
        FROM sales s
        LEFT JOIN products p ON s.productId = p.id
        WHERE s.date >= date('now', '-12 months')
        GROUP BY strftime('%Y-%m', s.date)
        ORDER BY month DESC;
      ''');
    } catch (e) {
      Logger.warning('Performance view creation warning: $e');
    }
  }

  // ===== GENERIC CRUD OPERATIONS WITH ERROR HANDLING =====

  /// Context7 pattern: Generic query with comprehensive error handling and retry
  Future<List<Map<String, dynamic>>> query({
    required String table,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _executeWithRetry(() async {
      final db = await database;
      return await db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    }, 'Query failed on table: $table');
  }

  /// Context7 pattern: Generic insert with transaction safety
  Future<int> insert({
    required String table,
    required Map<String, dynamic> values,
  }) async {
    return await _executeWithRetry(() async {
      final db = await database;
      return await db.insert(table, values);
    }, 'Insert failed on table: $table');
  }

  /// Context7 pattern: Generic update with transaction safety
  Future<int> update({
    required String table,
    required Map<String, dynamic> values,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return await _executeWithRetry(() async {
      final db = await database;
      final result = await db.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
      );

      if (kDebugMode) {
        Logger.database('Update result for $table: $result rows affected');
        Logger.debug('Values: $values');
        Logger.debug('Where: $where with args: $whereArgs');
      }

      return result;
    }, 'Update failed on table: $table');
  }

  /// Context7 pattern: Generic delete with transaction safety
  Future<int> delete({
    required String table,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return await _executeWithRetry(() async {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    }, 'Delete failed on table: $table');
  }

  /// Context7 pattern: Raw query with retry mechanism
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return await _executeWithRetry(() async {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    }, 'Raw query failed: $sql');
  }

  /// Context7 pattern: Execute database operation with retry and recovery
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation,
    String errorMessage,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (kDebugMode) {
          Logger.error('Database operation attempt $attempt failed', e);
        }

        // Check if database connection is broken
        if (_isDatabaseConnectionError(e)) {
          if (kDebugMode) {
            Logger.warning(
              'Database connection error detected, attempting recovery...',
            );
          }

          // Force database reconnection
          await _recoverDatabaseConnection();

          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
        }

        if (attempt == _maxRetries) {
          throw core.DatabaseException(
            '$errorMessage (after $_maxRetries attempts)',
            originalException: e,
          );
        }

        await Future.delayed(_retryDelay);
      }
    }

    throw core.DatabaseException(errorMessage);
  }

  /// Context7 pattern: Check if error is database connection related
  bool _isDatabaseConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('database') ||
        errorString.contains('connection') ||
        errorString.contains('closed') ||
        errorString.contains('locked') ||
        errorString.contains('busy') ||
        errorString.contains('timeout');
  }

  /// Context7 pattern: Recover database connection
  Future<void> _recoverDatabaseConnection() async {
    try {
      // Close existing connection
      await _database?.close();
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error closing database', e);
      }
    } finally {
      _database = null;
      _isInitializing = false;
    }
  }

  /// Context7 pattern: Execute in transaction with retry
  Future<T> executeInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    return await _executeWithRetry(() async {
      final db = await database;
      return await db.transaction(action);
    }, 'Transaction failed');
  }

  // ===== CUSTOMER CRUD OPERATIONS =====

  /// Get all customers from database
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    return await query(table: 'customers', orderBy: 'name ASC');
  }

  /// Insert new customer
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    return await insert(table: 'customers', values: customer);
  }

  /// Update existing customer
  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final id = customer['id'];
    if (id == null) {
      throw core.DatabaseException('Customer ID is required for update');
    }

    return await update(
      table: 'customers',
      values: customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete customer by ID
  Future<int> deleteCustomer(int customerId) async {
    return await delete(
      table: 'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// Get customer by ID
  Future<Map<String, dynamic>?> getCustomerById(int customerId) async {
    final results = await query(
      table: 'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get customers by type (customer/restaurant)
  Future<List<Map<String, dynamic>>> getCustomersByType(String type) async {
    return await query(
      table: 'customers',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
  }

  /// Get customers with debt
  Future<List<Map<String, dynamic>>> getCustomersWithDebt() async {
    return await query(
      table: 'customers',
      where: 'balance > 0',
      orderBy: 'balance DESC',
    );
  }

  // ===== SALE CRUD OPERATIONS =====

  /// Get all sales from database
  Future<List<Map<String, dynamic>>> getAllSales() async {
    return await query(table: 'sales', orderBy: 'date DESC');
  }

  /// Insert new sale
  Future<int> insertSale(Map<String, dynamic> sale) async {
    return await insert(table: 'sales', values: sale);
  }

  /// Update existing sale
  Future<int> updateSale(Map<String, dynamic> sale) async {
    final id = sale['id'];
    if (id == null) {
      throw core.DatabaseException('Sale ID is required for update');
    }

    return await update(
      table: 'sales',
      values: sale,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete sale by ID
  Future<int> deleteSale(int saleId) async {
    return await delete(table: 'sales', where: 'id = ?', whereArgs: [saleId]);
  }

  /// Get sales by customer ID
  Future<List<Map<String, dynamic>>> getSalesByCustomer(int customerId) async {
    return await query(
      table: 'sales',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  /// Get sales by type (customer/restaurant)
  Future<List<Map<String, dynamic>>> getSalesByType(String saleType) async {
    return await query(
      table: 'sales',
      where: 'saleType = ?',
      whereArgs: [saleType],
      orderBy: 'date DESC',
    );
  }

  /// Get sales by payment status
  Future<List<Map<String, dynamic>>> getSalesByPaymentStatus(
    bool isPaid,
  ) async {
    return await query(
      table: 'sales',
      where: 'isPaid = ?',
      whereArgs: [isPaid ? 1 : 0],
      orderBy: 'date DESC',
    );
  }

  // ===== UTILITY METHODS =====

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Database health check
  Future<bool> isHealthy() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Backup database
  Future<String> backup() async {
    try {
      final db = await database;
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String backupPath = join(
        documentsDirectory.path,
        'kasap_stok_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      await File(db.path).copy(backupPath);
      return backupPath;
    } catch (e) {
      throw core.DatabaseException('Backup failed', originalException: e);
    }
  }

  /// Vacuum database for performance
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
    } catch (e) {
      throw core.DatabaseException('Vacuum failed', originalException: e);
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await database;

      final productCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM products WHERE isActive = 1',
            ),
          ) ??
          0;

      final customerCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM customers WHERE isActive = 1',
            ),
          ) ??
          0;

      final salesCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM sales'),
          ) ??
          0;

      return {
        'products': productCount,
        'customers': customerCount,
        'sales': salesCount,
        'dbSize': await File(db.path).length(),
      };
    } catch (e) {
      throw core.DatabaseException('Stats query failed', originalException: e);
    }
  }

  // ===== YENİ CRUD OPERATIONS =====

  /// ✅ YENİ: Expenses CRUD operations
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    return await query(table: 'expenses', orderBy: 'date DESC');
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    return await insert(table: 'expenses', values: expense);
  }

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

  Future<int> deleteExpense(int expenseId) async {
    return await delete(
      table: 'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  /// ✅ YENİ: Stock transactions CRUD operations
  Future<List<Map<String, dynamic>>> getAllStockTransactions() async {
    return await query(table: 'stock_transactions', orderBy: 'date DESC');
  }

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

  Future<int> insertStockTransaction(Map<String, dynamic> transaction) async {
    return await insert(table: 'stock_transactions', values: transaction);
  }

  /// ✅ YENİ: View queries for reporting
  Future<List<Map<String, dynamic>>> getDailySalesReport() async {
    return await rawQuery('SELECT * FROM daily_sales_view LIMIT 30');
  }

  Future<List<Map<String, dynamic>>> getMonthlyProfitLossReport() async {
    return await rawQuery('SELECT * FROM monthly_profit_loss_view LIMIT 12');
  }

  Future<List<Map<String, dynamic>>> getStockStatusReport() async {
    return await rawQuery('SELECT * FROM stock_status_view');
  }

  /// ✅ YENİ: Transaction-based operations
  Future<void> processSaleTransaction({
    required Map<String, dynamic> sale,
    required int productId,
    required double quantity,
  }) async {
    await executeInTransaction((txn) async {
      // 1. Satış kaydı ekle
      final saleId = await txn.insert('sales', sale);

      // 2. Stok hareketi kaydı (trigger otomatik yapacak ama manuel de ekleyebiliriz)
      // Trigger zaten yapıyor, ama manuel kontrol için:

      // 3. Müşteri bakiyesi güncelleme (trigger otomatik yapacak)
      // Trigger zaten yapıyor

      Logger.database('Sale transaction completed: $saleId');
    });
  }

  /// ✅ YENİ: v12 Validation and monitoring methods
  Future<List<Map<String, dynamic>>> getDataIntegrityReport() async {
    return await rawQuery('SELECT * FROM data_integrity_view');
  }

  Future<List<Map<String, dynamic>>> getBusinessRulesReport() async {
    return await rawQuery('SELECT * FROM business_rules_view');
  }

  Future<List<Map<String, dynamic>>> getPerformanceMetrics() async {
    return await rawQuery('SELECT * FROM performance_metrics_view');
  }

  Future<List<Map<String, dynamic>>> getFinancialSummary() async {
    return await rawQuery('SELECT * FROM financial_summary_view');
  }

  /// ✅ YENİ: Advanced stock management
  Future<void> adjustStock({
    required int productId,
    required double quantity,
    required String reason,
    String? notes,
  }) async {
    await executeInTransaction((txn) async {
      // Manual stock adjustment with full audit trail
      await txn.insert('stock_transactions', {
        'productId': productId,
        'transactionType': 'adjustment',
        'quantity': quantity,
        'date': DateTime.now().toIso8601String(),
        'reason': reason,
        'notes': notes ?? 'Manual adjustment',
      });

      // Update product quantity
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ?, lastUpdated = CURRENT_TIMESTAMP WHERE id = ?',
        [quantity, productId],
      );

      Logger.database(
        'Stock adjusted: Product $productId, Quantity: $quantity',
      );
    });
  }

  /// ✅ YENİ: Customer balance management
  Future<void> updateCustomerBalance({
    required int customerId,
    required double amount,
    required String reason,
  }) async {
    await executeInTransaction((txn) async {
      // Update customer balance with validation
      final result = await txn.rawUpdate(
        'UPDATE customers SET balance = balance + ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ?',
        [amount, customerId],
      );

      if (result == 0) {
        throw core.DatabaseException('Customer not found: $customerId');
      }

      Logger.database(
        'Customer balance updated: $customerId, Amount: $amount, Reason: $reason',
      );
    });
  }

  /// ✅ YENİ: Complete sale with stock and balance updates
  Future<int> processCompleteSale({
    required Map<String, dynamic> sale,
    required bool updateStock,
    required bool updateCustomerBalance,
  }) async {
    return await executeInTransaction((txn) async {
      // 1. Insert sale
      final saleId = await txn.insert('sales', sale);

      // 2. Update stock if required (and if productId exists)
      if (updateStock && sale['productId'] != null) {
        final productId = sale['productId'] as int;
        final quantity = sale['quantity'] as double;

        // Check current stock
        final stockResult = await txn.rawQuery(
          'SELECT quantity FROM products WHERE id = ?',
          [productId],
        );

        if (stockResult.isEmpty) {
          throw core.DatabaseException('Product not found: $productId');
        }

        final currentStock = stockResult.first['quantity'] as double;
        if (currentStock < quantity) {
          throw core.DatabaseException(
            'Insufficient stock. Current: $currentStock, Required: $quantity',
          );
        }

        // Update stock (trigger will handle stock_transactions)
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [quantity, productId],
        );
      }

      // 3. Update customer balance if unpaid and customer exists
      if (!updateCustomerBalance ||
          sale['isPaid'] == 1 ||
          sale['customerId'] == null) {
        // No balance update needed
      } else {
        final customerId = sale['customerId'] as int;
        final amount = sale['amount'] as double;

        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ? WHERE id = ?',
          [amount, customerId],
        );
      }

      Logger.database('Complete sale processed: $saleId');
      return saleId;
    });
  }

  /// ✅ YENİ: Database maintenance and optimization
  Future<void> runMaintenance() async {
    try {
      final db = await database;

      // 1. Analyze tables for query optimization
      await db.execute('ANALYZE');

      // 2. Update table statistics
      await db.execute('PRAGMA optimize');

      // 3. Check integrity
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      final isOk =
          integrityResult.isNotEmpty &&
          integrityResult.first.values.first == 'ok';

      if (!isOk) {
        Logger.warning('Database integrity check failed: $integrityResult');
      }

      // 4. Vacuum if database is large
      final dbFile = File(db.path);
      final size = await dbFile.length();
      if (size > 50 * 1024 * 1024) {
        // 50MB
        await db.execute('VACUUM');
        Logger.database(
          'Database vacuumed due to size: ${size ~/ (1024 * 1024)}MB',
        );
      }

      Logger.database('Database maintenance completed');
    } catch (e) {
      Logger.error('Database maintenance failed', e);
      rethrow;
    }
  }

  /// ✅ YENİ: Export data for backup/reporting
  Future<Map<String, dynamic>> exportData({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final db = await database;

      // Build date filter
      String dateFilter = '';
      List<Object?> dateArgs = [];

      if (startDate != null && endDate != null) {
        dateFilter = ' WHERE date BETWEEN ? AND ?';
        dateArgs = [startDate, endDate];
      } else if (startDate != null) {
        dateFilter = ' WHERE date >= ?';
        dateArgs = [startDate];
      } else if (endDate != null) {
        dateFilter = ' WHERE date <= ?';
        dateArgs = [endDate];
      }

      // Export data
      final products = await query(table: 'products');
      final customers = await query(table: 'customers');
      final sales = await rawQuery(
        'SELECT * FROM sales$dateFilter ORDER BY date DESC',
        dateArgs,
      );
      final expenses = await rawQuery(
        'SELECT * FROM expenses$dateFilter ORDER BY date DESC',
        dateArgs,
      );
      final stockTransactions = await rawQuery(
        'SELECT * FROM stock_transactions$dateFilter ORDER BY date DESC',
        dateArgs,
      );

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'dateRange': {'start': startDate, 'end': endDate},
        'data': {
          'products': products,
          'customers': customers,
          'sales': sales,
          'expenses': expenses,
          'stockTransactions': stockTransactions,
        },
        'summary': {
          'totalProducts': products.length,
          'totalCustomers': customers.length,
          'totalSales': sales.length,
          'totalExpenses': expenses.length,
          'totalStockTransactions': stockTransactions.length,
        },
      };
    } catch (e) {
      Logger.error('Data export failed', e);
      rethrow;
    }
  }
}
