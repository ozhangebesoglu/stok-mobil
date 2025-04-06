import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Windows platformu için sqflite_ffi kullan
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      // Veritabanı başlatma
      sqfliteFfiInit();
      // databaseFactory değişkenini databaseFactoryFfi ile değiştir
      databaseFactory = databaseFactoryFfi;
    }

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'kasap_stok.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Ürünler tablosu
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        sellingPrice REAL NOT NULL
      )
    ''');

    // Müşteriler tablosu
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        balance REAL NOT NULL
      )
    ''');

    // Satışlar tablosu
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        productId INTEGER,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE SET NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    // Giderler tablosu
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Manuel Gelirler tablosu
    await db.execute('''
      CREATE TABLE manual_incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Restoranlar tablosu
    await db.execute('''
      CREATE TABLE restaurants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        contactName TEXT
      )
    ''');

    // Restoran Satışları tablosu
    await db.execute('''
      CREATE TABLE restaurant_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        productName TEXT,
        quantity REAL,
        unit TEXT,
        unitPrice REAL,
        notes TEXT,
        isPaid INTEGER DEFAULT 1
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Manuel Gelirler tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS manual_incomes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          category TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Mevcut satışları yedekle
      await db.execute('ALTER TABLE sales RENAME TO sales_old');

      // Yeni sütunlarla satışlar tablosunu oluştur
      await db.execute('''
        CREATE TABLE sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerId INTEGER,
          customerName TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          isPaid INTEGER NOT NULL,
          productId INTEGER,
          productName TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          unitPrice REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE SET NULL,
          FOREIGN KEY (productId) REFERENCES products (id) ON DELETE SET NULL
        )
      ''');

      // Eski verileri yeni tabloya taşı (yeni sütunlar için varsayılan değerler ekleyerek)
      await db.execute('''
        INSERT INTO sales (id, customerId, customerName, amount, date, isPaid, productName, quantity, unit, unitPrice, notes)
        SELECT id, customerId, customerName, amount, date, isPaid, 'Eski kayıt', 0, 'kg', 0, 'Eski kayıt'
        FROM sales_old
      ''');

      // Eski tabloyu sil
      await db.execute('DROP TABLE sales_old');
    }

    if (oldVersion < 4) {
      // Restoran Satışları tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS restaurant_sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          restaurant TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          productName TEXT,
          quantity REAL,
          unit TEXT,
          unitPrice REAL,
          notes TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      // Sales tablosuna notes sütunu ekle
      await db.execute('ALTER TABLE sales ADD COLUMN notes TEXT');
    }

    if (oldVersion < 6) {
      // restaurant_sales tablosuna isPaid sütunu ekle
      await db.execute(
        'ALTER TABLE restaurant_sales ADD COLUMN isPaid INTEGER DEFAULT 1',
      );
    }
  }
}
