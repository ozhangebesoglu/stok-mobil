import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'providers/stock_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/sales_provider.dart';
import 'features/stock_management.dart';
import 'features/profit_loss.dart';
import 'features/customer_management.dart';
import 'features/reporting.dart';
import 'features/restaurant_sales.dart';
import 'features/sales_management.dart';
import 'features/restaurant_management.dart';
import 'widgets/dashboard_button.dart';
import 'services/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatı desteği
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  // Veritabanını başlat
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Veritabanını initialize et

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StockProvider()),
        ChangeNotifierProvider(create: (context) => CustomerProvider()),
        ChangeNotifierProvider(create: (context) => SalesProvider()),
      ],
      child: KasapStokApp(),
    ),
  );
}

class KasapStokApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasap Stok Yönetimi',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();

  // Statik metot - istatistikleri güncelleme
  static void updateStatistics(BuildContext context) {
    try {
      final homePageState = context.findAncestorStateOfType<_HomePageState>();
      if (homePageState != null) {
        homePageState._loadStatistics();
      } else {
        // Ana sayfa durumu bulunamadı, gerekli sağlayıcıları manuel olarak güncelle
        Provider.of<StockProvider>(context, listen: false).loadProducts();
        Provider.of<SalesProvider>(context, listen: false).loadSales();
        Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      }
    } catch (e) {
      print('Ana sayfa istatistikleri güncellenirken hata: $e');
    }
  }
}

class _HomePageState extends State<HomePage> {
  int _totalStock = 0;
  double _totalSales = 0;
  int _customerCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Toplam stok miktarı
      final stockResult = await db.rawQuery(
        'SELECT SUM(quantity) as total FROM products',
      );

      // Toplam satış tutarı
      // 1. Normal satışlar (ödenmiş olanlar)
      final salesResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM sales WHERE isPaid = 1',
      );

      // 2. Restoran satışları
      final restaurantSalesResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM restaurant_sales',
      );

      // 3. Manuel gelirler
      final manualIncomesResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM manual_incomes',
      );

      // Toplam müşteri sayısı
      final customerResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM customers',
      );

      if (mounted) {
        setState(() {
          // SQLite'dan gelen değerler farklı tiplerde olabilir
          final stockTotal =
              stockResult.isNotEmpty ? stockResult.first['total'] : null;

          // Satışlardan gelen gelir
          final salesTotal =
              salesResult.isNotEmpty
                  ? _parseToDouble(salesResult.first['total'] ?? 0)
                  : 0.0;

          // Restoran satışlarından gelen gelir
          final restaurantTotal =
              restaurantSalesResult.isNotEmpty
                  ? _parseToDouble(restaurantSalesResult.first['total'] ?? 0)
                  : 0.0;

          // Manuel gelirler
          final manualTotal =
              manualIncomesResult.isNotEmpty
                  ? _parseToDouble(manualIncomesResult.first['total'] ?? 0)
                  : 0.0;

          // Toplam gelir hesabı
          final totalSales = salesTotal + restaurantTotal + manualTotal;

          final customerTotal =
              customerResult.isNotEmpty ? customerResult.first['total'] : null;

          // Güvenli dönüşüm
          _totalStock = stockTotal != null ? _parseToInt(stockTotal) : 0;
          _totalSales = totalSales;
          _customerCount =
              customerTotal != null ? _parseToInt(customerTotal) : 0;
          _isLoading = false;

          print('Toplam Gelir Detayları:');
          print('Normal Satışlar: $salesTotal');
          print('Restoran Satışları: $restaurantTotal');
          print('Manuel Gelirler: $manualTotal');
          print('Toplam Gelir: $totalSales');
        });
      }
    } catch (e) {
      print('İstatistikler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _totalStock = 0;
          _totalSales = 0.0;
          _customerCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  // SQLite değerini int'e çevirme yardımcı metodu
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // SQLite değerini double'a çevirme yardımcı metodu
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Stok Yönetimi'),
        backgroundColor: Color(0xFF8B0000), // Muted Tomato Red
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
                child: Text(
                  'Hoşgeldiniz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF654321), // Deep Brown
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    DashboardButton(
                      title: 'Stok Yönetimi',
                      icon: CupertinoIcons.cube_box,
                      backgroundColor: Color(0xFF8B0000), // Muted Tomato Red
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockManagementPage(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    SizedBox(height: 12),
                    DashboardButton(
                      title: 'Satış Yönetimi',
                      icon: CupertinoIcons.cart,
                      backgroundColor: Color(0xFFAA2704), // Muted Rust Red
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalesManagementPage(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    SizedBox(height: 12),
                    DashboardButton(
                      title: 'Müşteri Yönetimi',
                      icon: CupertinoIcons.person_2,
                      backgroundColor: Color(0xFF9D9885), // Dusty Olive Green
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerManagementPage(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    SizedBox(height: 12),
                    DashboardButton(
                      title: 'Kâr-Zarar',
                      icon: CupertinoIcons.money_dollar,
                      backgroundColor: Color(0xFF013220), // Dark Green
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfitLossPage(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    SizedBox(height: 12),
                    DashboardButton(
                      title: 'Raporlama',
                      icon: CupertinoIcons.chart_bar,
                      backgroundColor: Color(0xFF778EA8), // Wash-Out Denim Blue
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportingPage(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Özet Bilgiler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF654321), // Deep Brown
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Toplam Stok',
                            '$_totalStock Adet',
                            Color(0xFF8B0000), // Muted Tomato Red
                            CupertinoIcons.cube_box,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Toplam Satış',
                            '${_totalSales.toStringAsFixed(2)} ₺',
                            Color(0xFFAA2704), // Muted Rust Red
                            CupertinoIcons.money_dollar,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoCard(
                      'Toplam Müşteri',
                      '$_customerCount Müşteri',
                      Color(0xFF9D9885), // Dusty Olive Green
                      CupertinoIcons.person_2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF654321), // Deep Brown
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
