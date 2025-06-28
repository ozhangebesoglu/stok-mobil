import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'features/sales_management.dart';
import 'features/restaurant_management.dart';
import 'widgets/dashboard_button.dart';
import 'services/database/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Türkçe tarih formatı desteği
    await initializeDateFormatting('tr_TR', null);
    Intl.defaultLocale = 'tr_TR';
  } catch (e) {
    // Tarih formatı yüklenemezse varsayılan devam et
    Logger.error('Date formatting initialization failed', e);
  }

  // Web platformu kontrolü - SQLite sadece mobil/desktop'ta çalışır
  if (kIsWeb) {
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
    return;
  }

  // Mobil/Desktop için veritabanını başlat
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Veritabanını başlat
    Logger.info('Database initialized successfully in main()');
  } catch (e) {
    Logger.error('Database initialization failed in main()', e);
    // Hata olsa bile uygulamayı başlat - kullanıcı hata mesajını görecek
  }

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
  const KasapStokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Standart telefon tasarım boyutu
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Stok Takibim',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: AppTheme.lightTheme.colorScheme.primary,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: AppTheme.lightTheme.colorScheme.surface,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: HomePage(),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  // Statik metot - istatistikleri güncelleme
  static void updateStatistics(BuildContext context) {
    try {
      final homePageState = context.findAncestorStateOfType<_HomePageState>();
      if (homePageState != null) {
        homePageState._initializeProviders();
      } else {
        // Ana sayfa durumu bulunamadı, gerekli sağlayıcıları manuel olarak güncelle
        Provider.of<StockProvider>(context, listen: false).loadProducts();
        Provider.of<SalesProvider>(context, listen: false).loadSales();
        Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      }
    } catch (e) {
      Logger.error('Ana sayfa istatistikleri güncellenirken hata', e);
    }
  }
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true; // Başlangıçta true olsun
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Context7 Pattern: Provider'lar otomatik yüklenecek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return; // Web'de SQLite çalışmaz
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      Logger.info('Starting database and provider initialization...');

      // Context7 Pattern: Database initialization with detailed error handling
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        Logger.info('Database connection successful');

        // Comprehensive database tests
        await db.rawQuery('SELECT 1 as test');

        // Test core tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        Logger.info(
          'Available tables: ${tables.map((t) => t['name']).join(', ')}',
        );

        // Verify essential tables
        final essentialTables = ['products', 'customers', 'sales'];
        for (final table in essentialTables) {
          try {
            await db.rawQuery('SELECT COUNT(*) FROM $table');
            Logger.info('Table $table verified');
          } catch (e) {
            Logger.error('Table $table missing or corrupted', e);
            throw Exception('Essential table $table is missing or corrupted');
          }
        }

        Logger.info('Database integrity check passed');
      } catch (dbError) {
        Logger.error('Database initialization failed', dbError);
        throw Exception('Veritabanı bağlantı hatası: ${dbError.toString()}');
      }

      // Context7 Pattern: Provider initialization with error isolation
      final providers = [
        () async {
          final stockProvider = Provider.of<StockProvider>(
            context,
            listen: false,
          );
          await stockProvider.loadProducts();
          Logger.info('Stock provider loaded successfully');
        },
        () async {
          final customerProvider = Provider.of<CustomerProvider>(
            context,
            listen: false,
          );
          await customerProvider.loadCustomers();
          Logger.info('Customer provider loaded successfully');
        },
        () async {
          final salesProvider = Provider.of<SalesProvider>(
            context,
            listen: false,
          );
          await salesProvider.loadSales();
          Logger.info('Sales provider loaded successfully');
        },
      ];

      // Load providers with individual error handling
      final List<String> failedProviders = [];
      for (int i = 0; i < providers.length; i++) {
        try {
          await providers[i]();
        } catch (e) {
          final providerNames = ['Stok', 'Müşteri', 'Satış'];
          Logger.error('${providerNames[i]} provider failed', e);
          failedProviders.add(providerNames[i]);
        }
      }

      if (failedProviders.isNotEmpty) {
        throw Exception('${failedProviders.join(', ')} verileri yüklenemedi');
      }

      Logger.info('All providers initialized successfully');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Provider initialization error', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _generateUserFriendlyError(e.toString());
        });
      }
    }
  }

  String _generateUserFriendlyError(String error) {
    if (error.contains('bağlantı') || error.contains('connection')) {
      return 'Veritabanı bağlantısı kurulamadı.\n\nLütfen uygulamayı yeniden başlatın.';
    } else if (error.contains('permission')) {
      return 'Uygulama izinleri eksik.\n\nAyarlardan uygulamaya izin verin.';
    } else if (error.contains('disk') || error.contains('space')) {
      return 'Yetersiz depolama alanı.\n\nCihazınızda yer açın.';
    } else if (error.contains('corrupt')) {
      return 'Veri dosyası bozulmuş.\n\nUygulamayı yeniden yükleyin.';
    } else if (error.contains('table') || error.contains('tablo')) {
      return 'Veri yapısı hatası tespit edildi.\n\nUygulama güncelleme gerekli.';
    } else {
      return 'Uygulama başlatılamadı.\n\nHata: ${error.length > 100 ? error.substring(0, 100) + '...' : error}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stok Takibim'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: _initializeProviders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Tekrar Dene'),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Uygulama yükleniyor...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h, left: 8.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoşgeldiniz',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'İşletmenizi yönetin',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ana Butonlar
                              Consumer<StockProvider>(
                                builder: (context, stockProvider, child) {
                                  final totalStock =
                                      stockProvider.products.length;
                                  return DashboardButton(
                                    title: 'Stok Yönetimi',
                                    subtitle:
                                        totalStock > 0
                                            ? '$totalStock ürün stokta'
                                            : 'Henüz ürün yok',
                                    icon: Icons.inventory_2_outlined,
                                    iconColor: Colors.blue[700]!,
                                    badge:
                                        totalStock > 0
                                            ? totalStock.toString()
                                            : null,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  StockManagementPage(),
                                        ),
                                      );
                                      // Provider otomatik güncellenecek, manuel _loadStatistics gerekmez
                                    },
                                  );
                                },
                              ),

                              Consumer<CustomerProvider>(
                                builder: (context, customerProvider, child) {
                                  final customerCount =
                                      customerProvider.customers.length;
                                  return DashboardButton(
                                    title: 'Müşteri & Borç Takibi',
                                    subtitle:
                                        customerCount > 0
                                            ? '$customerCount müşteri'
                                            : 'Henüz müşteri yok',
                                    icon: Icons.people_outline,
                                    iconColor: Colors.green[700]!,
                                    badge:
                                        customerCount > 0
                                            ? customerCount.toString()
                                            : null,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  CustomerManagementPage(),
                                        ),
                                      );
                                      // Provider otomatik güncellenecek
                                    },
                                  );
                                },
                              ),

                              // Side by side payment buttons as requested
                              Padding(
                                padding: AppTheme.defaultPadding,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ActionDashboardButton(
                                        title: 'Ödeme Al',
                                        icon: Icons.payments_outlined,
                                        iconColor: Colors.green,
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      CustomerManagementPage(),
                                            ),
                                          );
                                          await _initializeProviders();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: ActionDashboardButton(
                                        title: 'Borç Ekle',
                                        icon: Icons.add_circle_outline,
                                        iconColor: Colors.orange,
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      CustomerManagementPage(),
                                            ),
                                          );
                                          await _initializeProviders();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              DashboardButton(
                                title: 'Satış Yönetimi',
                                subtitle: 'Müşteri satışları',
                                icon: Icons.point_of_sale_outlined,
                                iconColor: Colors.purple[700]!,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SalesManagementPage(),
                                    ),
                                  ).then((_) => _initializeProviders());
                                },
                              ),

                              DashboardButton(
                                title: 'Restoran Satışları',
                                subtitle: 'Restoran müşterileri',
                                icon: Icons.restaurant_outlined,
                                iconColor: Colors.amber[700]!,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RestaurantManagement(),
                                    ),
                                  ).then((_) => _initializeProviders());
                                },
                              ),

                              DashboardButton(
                                title: 'Kar & Zarar',
                                subtitle: 'Finansal analiz',
                                icon: Icons.trending_up_outlined,
                                iconColor: Colors.indigo[700]!,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfitLossPage(),
                                    ),
                                  ).then((_) => _initializeProviders());
                                },
                              ),

                              DashboardButton(
                                title: 'Raporlama',
                                subtitle: 'Detaylı raporlar',
                                icon: Icons.assessment_outlined,
                                iconColor: Colors.red[700]!,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportingPage(),
                                    ),
                                  ).then((_) => _initializeProviders());
                                },
                              ),

                              SizedBox(height: 24.h),

                              // Enhanced Statistics Section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Özet Bilgiler',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _initializeProviders,
                                      icon: Icon(Icons.refresh_outlined),
                                      tooltip: 'Yenile',
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Enhanced Statistics Cards
                              _isLoading
                                  ? SizedBox(
                                    height: 120.h,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.red,
                                            ),
                                      ),
                                    ),
                                  )
                                  : Consumer3<
                                    StockProvider,
                                    SalesProvider,
                                    CustomerProvider
                                  >(
                                    builder: (
                                      context,
                                      stockProvider,
                                      salesProvider,
                                      customerProvider,
                                      child,
                                    ) {
                                      // Context7 Pattern: Real-time Computed State with Error Handling
                                      final totalStock =
                                          stockProvider.products.length;
                                      final totalSales = salesProvider.sales
                                          .where((sale) => sale.isPaid)
                                          .fold(
                                            0.0,
                                            (sum, sale) => sum + sale.amount,
                                          );
                                      final customerCount =
                                          customerProvider.customers.length;

                                      // Context7 Pattern: Error Boundary
                                      if (stockProvider.hasError ||
                                          salesProvider.hasError ||
                                          customerProvider.hasError) {
                                        return SizedBox(
                                          height: 120.h,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 32.sp,
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  'Veriler yüklenirken hata oluştu',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 8.h),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    await Future.wait([
                                                      stockProvider
                                                          .loadProducts(),
                                                      salesProvider.loadSales(),
                                                      customerProvider
                                                          .loadCustomers(),
                                                    ]);
                                                  },
                                                  child: Text('Yeniden Dene'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      // Context7 Pattern: Recovery State Indicator
                                      if (stockProvider.isRecovering ||
                                          salesProvider.dataState ==
                                              SalesDataState.recovering ||
                                          customerProvider.dataState ==
                                              CustomerDataState.recovering) {
                                        return SizedBox(
                                          height: 120.h,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.orange),
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  'Bağlantı kurtarılıyor...',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              'Toplam Stok',
                                              totalStock > 0
                                                  ? '$totalStock Ürün'
                                                  : 'Ürün Yok',
                                              Icons.inventory_2,
                                              Colors.blue,
                                              totalStock > 0,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: _buildStatCard(
                                              'Toplam Satış',
                                              totalSales > 0
                                                  ? '₺${totalSales.toStringAsFixed(2)}'
                                                  : '₺0.00',
                                              Icons.trending_up,
                                              Colors.green,
                                              totalSales > 0,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: _buildStatCard(
                                              'Müşteri',
                                              customerCount > 0
                                                  ? '$customerCount Kişi'
                                                  : 'Müşteri Yok',
                                              Icons.people,
                                              Colors.orange,
                                              customerCount > 0,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isEnabled,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black87 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
