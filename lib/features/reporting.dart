import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database/database_helper.dart';
import '../core/utils/logger.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State management
  bool _isLoading = false;
  String? _errorMessage;

  // Financial data
  double _customerTotalDebt = 0.0;
  double _customerPaidSales = 0.0;
  double _restaurantTotalSales = 0.0;

  // Business metrics
  int _totalCustomers = 0;
  int _activeCustomers = 0;
  int _totalProducts = 0;
  int _lowStockProducts = 0;
  int _totalRestaurants = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'İş Raporları',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReportData,
            icon: Icon(CupertinoIcons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withAlpha(179),
          tabs: [
            Tab(icon: Icon(CupertinoIcons.chart_pie_fill), text: 'Finansal'),
            Tab(icon: Icon(CupertinoIcons.person_3_fill), text: 'Müşteriler'),
            Tab(icon: Icon(CupertinoIcons.cube_box_fill), text: 'Stok'),
          ],
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState(colorScheme, theme)
              : _errorMessage != null
              ? _buildErrorState(colorScheme, theme)
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildFinancialTab(colorScheme, theme),
                  _buildCustomersTab(colorScheme, theme),
                  _buildStockTab(colorScheme, theme),
                ],
              ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          SizedBox(height: 24.h),
          Text(
            'Raporlar hazırlanıyor...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Veriler analiz ediliyor',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 64.w,
                color: Colors.red.withAlpha(77),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Bir hata oluştu',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            FilledButton.icon(
              onPressed: _loadReportData,
              icon: Icon(CupertinoIcons.refresh),
              label: Text('Tekrar Dene'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTab(ColorScheme colorScheme, ThemeData theme) {
    final totalDebt = _customerTotalDebt;
    final totalRevenue = _customerPaidSales + _restaurantTotalSales;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Overview Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withAlpha(179),
                    colorScheme.primaryContainer.withAlpha(128),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(25),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    color: colorScheme.primary,
                    size: 40.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Finansal Durum',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(179),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Revenue Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Toplam Gelir',
                    amount: totalRevenue,
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    color: Colors.green,
                    subtitle: 'Ödenen satışlar',
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildMetricCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Bekleyen Alacak',
                    amount: totalDebt,
                    icon: CupertinoIcons.clock_fill,
                    color: Colors.orange,
                    subtitle: 'Ödenmemiş borçlar',
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Detailed breakdown
            _buildDetailCard(
              colorScheme: colorScheme,
              theme: theme,
              title: 'Müşteri Satışları',
              paidAmount: _customerPaidSales,
              unpaidAmount: _customerTotalDebt,
              icon: CupertinoIcons.person_2_fill,
            ),

            SizedBox(height: 16.h),

            _buildDetailCard(
              colorScheme: colorScheme,
              theme: theme,
              title: 'Restoran Satışları',
              paidAmount: _restaurantTotalSales,
              unpaidAmount: 0, // Restaurants are usually paid immediately
              icon: CupertinoIcons.building_2_fill,
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTab(ColorScheme colorScheme, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Customer metrics
            Row(
              children: [
                Expanded(
                  child: _buildCountCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Toplam Müşteri',
                    count: _totalCustomers,
                    icon: CupertinoIcons.person_3_fill,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildCountCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Aktif Müşteri',
                    count: _activeCustomers,
                    icon: CupertinoIcons.person_badge_plus_fill,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            _buildCountCard(
              colorScheme: colorScheme,
              theme: theme,
              title: 'Restoran Sayısı',
              count: _totalRestaurants,
              icon: CupertinoIcons.building_2_fill,
              color: Colors.purple,
              fullWidth: true,
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTab(ColorScheme colorScheme, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCountCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Toplam Ürün',
                    count: _totalProducts,
                    icon: CupertinoIcons.cube_box_fill,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildCountCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Düşük Stok',
                    count: _lowStockProducts,
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    color: _lowStockProducts > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            if (_lowStockProducts > 0)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.red.withAlpha(51), width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: Colors.red.withAlpha(77),
                      size: 32.w,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Stok Uyarısı',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red.withAlpha(179),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '$_lowStockProducts ürünün stoğu azalmış.\nStok yönetimi sayfasından kontrol edin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700.withAlpha(128),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withAlpha(51), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String title,
    required double paidAmount,
    required double unpaidAmount,
    required IconData icon,
  }) {
    final total = paidAmount + unpaidAmount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(179),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} ₺',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ödenen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${paidAmount.toStringAsFixed(2)} ₺',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bekleyen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${unpaidAmount.toStringAsFixed(2)} ₺',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: unpaidAmount > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withAlpha(51), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
            textAlign: fullWidth ? TextAlign.center : TextAlign.start,
          ),
          SizedBox(height: 4.h),
          Text(
            count.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = await DatabaseHelper().database;

      // Safe database queries with error handling
      final results = await Future.wait([
        _getCustomerFinancials(db),
        _getRestaurantFinancials(db),
        _getBusinessMetrics(db),
      ]);

      final customerData = results[0] as Map<String, double>;
      final restaurantData = results[1] as Map<String, double>;
      final metricsData = results[2] as Map<String, int>;

      setState(() {
        _customerTotalDebt = customerData['unpaid'] ?? 0.0;
        _customerPaidSales = customerData['paid'] ?? 0.0;
        _restaurantTotalSales = restaurantData['total'] ?? 0.0;

        _totalCustomers = metricsData['totalCustomers'] ?? 0;
        _activeCustomers = metricsData['activeCustomers'] ?? 0;
        _totalProducts = metricsData['totalProducts'] ?? 0;
        _lowStockProducts = metricsData['lowStockProducts'] ?? 0;
        _totalRestaurants = metricsData['totalRestaurants'] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veriler yüklenirken hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<Map<String, double>> _getCustomerFinancials(Database db) async {
    try {
      // Use safe queries without saleType if column doesn't exist
      final unpaidResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM sales 
        WHERE isPaid = 0
      ''');

      final paidResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM sales 
        WHERE isPaid = 1
      ''');

      return {
        'unpaid': _parseToDouble(unpaidResult.first['total']),
        'paid': _parseToDouble(paidResult.first['total']),
      };
    } catch (e) {
      Logger.error('Customer financials error', e);
      return {'unpaid': 0.0, 'paid': 0.0};
    }
  }

  Future<Map<String, double>> _getRestaurantFinancials(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM restaurant_sales
      ''');

      return {'total': _parseToDouble(result.first['total'])};
    } catch (e) {
      Logger.error('Restaurant financials error', e);
      return {'total': 0.0};
    }
  }

  Future<Map<String, int>> _getBusinessMetrics(Database db) async {
    try {
      final results = await Future.wait([
        db.rawQuery('SELECT COUNT(*) as total FROM customers'),
        db.rawQuery(
          'SELECT COUNT(*) as total FROM customers WHERE isActive = 1',
        ),
        db.rawQuery(
          'SELECT COUNT(*) as total FROM products WHERE isActive = 1',
        ),
        db.rawQuery(
          'SELECT COUNT(*) as total FROM products WHERE isActive = 1 AND quantity <= COALESCE(minStockLevel, 5)',
        ),
        db.rawQuery(
          'SELECT COUNT(DISTINCT restaurant) as total FROM restaurant_sales',
        ),
      ]);

      return {
        'totalCustomers': _parseToInt(results[0].first['total']),
        'activeCustomers': _parseToInt(results[1].first['total']),
        'totalProducts': _parseToInt(results[2].first['total']),
        'lowStockProducts': _parseToInt(results[3].first['total']),
        'totalRestaurants': _parseToInt(results[4].first['total']),
      };
    } catch (e) {
      Logger.error('Business metrics error', e);
      return {
        'totalCustomers': 0,
        'activeCustomers': 0,
        'totalProducts': 0,
        'lowStockProducts': 0,
        'totalRestaurants': 0,
      };
    }
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
