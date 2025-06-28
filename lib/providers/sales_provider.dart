import 'package:flutter/foundation.dart';
import '../models/sale.dart';

import '../services/database/database_helper.dart';
import '../core/exceptions/database_exception.dart' as core;
import '../core/utils/logger.dart';

enum SalesDataState { loading, loaded, error, recovering }

/// Context7 optimized sales provider with comprehensive error handling
/// Features: Real-time updates, transaction support, performance optimization
class SalesProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // State management
  SalesDataState _dataState = SalesDataState.loading;
  String? _errorMessage;

  // All sales data
  List<Sale> _allSales = [];

  // Categorized sales - Context7 pattern: clear data separation
  final List<Sale> _customerSales = [];
  final List<Sale> _restaurantSales = [];

  // Filtered views
  final List<Sale> _paidSales = [];
  final List<Sale> _unpaidSales = [];

  // Performance optimization - cached totals
  double _totalCustomerSales = 0.0;
  double _totalRestaurantSales = 0.0;
  double _totalPaidAmount = 0.0;
  double _totalUnpaidAmount = 0.0;

  // Getters
  SalesDataState get dataState => _dataState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _dataState == SalesDataState.loading;
  bool get hasError => _dataState == SalesDataState.error;

  // All sales
  List<Sale> get sales => List.unmodifiable(_allSales);

  // Categorized sales with immutable returns (Context7 pattern)
  List<Sale> get customerSales => List.unmodifiable(_customerSales);
  List<Sale> get restaurantSales => List.unmodifiable(_restaurantSales);
  List<Sale> get paidSales => List.unmodifiable(_paidSales);
  List<Sale> get unpaidSales => List.unmodifiable(_unpaidSales);

  // Financial totals
  double get totalCustomerSales => _totalCustomerSales;
  double get totalRestaurantSales => _totalRestaurantSales;
  double get totalPaidAmount => _totalPaidAmount;
  double get totalUnpaidAmount => _totalUnpaidAmount;
  double get totalSalesAmount => _totalCustomerSales + _totalRestaurantSales;

  // Debt metrics
  double get totalCustomerDebt => _customerSales
      .where((sale) => !sale.isPaid)
      .fold(0.0, (sum, sale) => sum + sale.amount);

  double get totalCustomerPaid => _customerSales
      .where((sale) => sale.isPaid)
      .fold(0.0, (sum, sale) => sum + sale.amount);

  // Load all sales with categorization
  Future<void> loadSales() async {
    await _executeWithRetry(() async {
      _setDataState(SalesDataState.loading);

      final salesData = await _dbHelper.getAllSales();
      _allSales = salesData.map((data) => Sale.fromMap(data)).toList();

      _categorizeSales();
      _calculateTotals();

      _setDataState(SalesDataState.loaded);
    }, 'Satışlar yüklenirken hata');
  }

  // Add new sale with proper categorization
  Future<void> addSale(Sale sale) async {
    await _executeWithRetry(() async {
      _setDataState(SalesDataState.loading);

      final saleId = await _dbHelper.insertSale(sale.toMap());
      final newSale = sale.copyWith(id: saleId);

      _allSales.insert(0, newSale); // Add at beginning for recency
      _categorizeSales();
      _calculateTotals();

      _setDataState(SalesDataState.loaded);

      if (kDebugMode) {
        Logger.info(
          'Sale added successfully: ${newSale.productName} to ${newSale.customerName}',
        );
      }
    }, 'Satış eklenirken hata');
  }

  // Update sale with recategorization
  Future<void> updateSale(Sale sale) async {
    await _executeWithRetry(() async {
      final result = await _dbHelper.updateSale(sale.toMap());

      if (result > 0) {
        final index = _allSales.indexWhere((s) => s.id == sale.id);
        if (index != -1) {
          _allSales[index] = sale;
          _categorizeSales();
          _calculateTotals();
          notifyListeners();

          if (kDebugMode) {
            Logger.info('Sale updated successfully: ${sale.productName}');
          }
        }
      } else {
        throw Exception('Satış güncellenemedi - veritabanı hatası');
      }
    }, 'Satış güncellenirken hata');
  }

  // Delete sale with cleanup
  Future<void> deleteSale(int saleId) async {
    try {
      await _dbHelper.deleteSale(saleId);

      _allSales.removeWhere((sale) => sale.id == saleId);
      _categorizeSales();
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      _handleError('Satış silinirken hata', e);
      rethrow;
    }
  }

  // Mark sale as paid/unpaid
  Future<void> updatePaymentStatus(int saleId, bool isPaid) async {
    await _executeWithRetry(() async {
      final saleIndex = _allSales.indexWhere((sale) => sale.id == saleId);
      if (saleIndex == -1) {
        throw core.DatabaseException(
          'Satış bulunamadı',
          code: 'SALE_NOT_FOUND',
        );
      }

      final updatedSale = _allSales[saleIndex].copyWith(
        isPaid: isPaid,
        updatedAt: DateTime.now(),
      );

      final result = await _dbHelper.update(
        table: 'sales',
        values: updatedSale.toMap(),
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (result > 0) {
        _allSales[saleIndex] = updatedSale;
        _categorizeSales();
        _calculateTotals();
        notifyListeners();

        if (kDebugMode) {
          Logger.info(
            'Payment status updated for sale: ${updatedSale.productName}',
          );
        }
      } else {
        throw Exception('Ödeme durumu güncellenemedi - veritabanı hatası');
      }
    }, 'Ödeme durumu güncellenirken hata');
  }

  // Get sales by customer
  List<Sale> getSalesByCustomer(int customerId) {
    return _customerSales
        .where((sale) => sale.customerId == customerId)
        .toList();
  }

  // Get sales by date range
  List<Sale> getSalesByDateRange(DateTime startDate, DateTime endDate) {
    return _allSales.where((sale) {
      final saleDate = DateTime.parse(sale.date);
      return saleDate.isAfter(startDate.subtract(Duration(days: 1))) &&
          saleDate.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  // Get sales by product
  List<Sale> getSalesByProduct(String productName) {
    return _allSales
        .where(
          (sale) => sale.productName.toLowerCase().contains(
            productName.toLowerCase(),
          ),
        )
        .toList();
  }

  // Search sales with multiple criteria
  List<Sale> searchSales(String query) {
    final lowerQuery = query.toLowerCase();
    return _allSales.where((sale) {
      return sale.customerName.toLowerCase().contains(lowerQuery) ||
          sale.productName.toLowerCase().contains(lowerQuery) ||
          (sale.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Private methods for data organization

  void _categorizeSales() {
    // Reset categories
    _customerSales.clear();
    _restaurantSales.clear();
    _paidSales.clear();
    _unpaidSales.clear();

    // Categorize by type and payment status
    for (final sale in _allSales) {
      // Category by customer type (assuming restaurant names contain "Restoran" or similar)
      if (_isRestaurantSale(sale)) {
        _restaurantSales.add(sale);
      } else {
        _customerSales.add(sale);
      }

      // Category by payment status
      if (sale.isPaid) {
        _paidSales.add(sale);
      } else {
        _unpaidSales.add(sale);
      }
    }

    // Sort by date (newest first)
    _customerSales.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
    _restaurantSales.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
    _paidSales.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
    _unpaidSales.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
  }

  bool _isRestaurantSale(Sale sale) {
    // Business logic to determine if this is a restaurant sale
    final customerName = sale.customerName.toLowerCase();
    return customerName.contains('restoran') ||
        customerName.contains('restaurant') ||
        customerName.contains('cafe') ||
        customerName.contains('otel') ||
        customerName.contains('lokanta') ||
        (sale.notes?.toLowerCase().contains('restoran') ?? false);
  }

  void _calculateTotals() {
    _totalCustomerSales = _customerSales.fold(
      0.0,
      (sum, sale) => sum + sale.amount,
    );
    _totalRestaurantSales = _restaurantSales.fold(
      0.0,
      (sum, sale) => sum + sale.amount,
    );
    _totalPaidAmount = _paidSales.fold(0.0, (sum, sale) => sum + sale.amount);
    _totalUnpaidAmount = _unpaidSales.fold(
      0.0,
      (sum, sale) => sum + sale.amount,
    );
  }

  void _setDataState(SalesDataState state) {
    _dataState = state;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(String message, dynamic error) {
    _dataState = SalesDataState.error;
    _errorMessage = '$message: $error';
    notifyListeners();

    if (kDebugMode) {
      Logger.error('SalesProvider Error: $message', error);
    }
  }

  // Bulk operations for performance

  Future<void> markMultipleSalesAsPaid(List<int> saleIds) async {
    try {
      _setDataState(SalesDataState.loading);

      for (final saleId in saleIds) {
        await updatePaymentStatus(saleId, true);
      }

      _setDataState(SalesDataState.loaded);
    } catch (e) {
      _handleError('Toplu ödeme işlemi sırasında hata', e);
      rethrow;
    }
  }

  Future<void> deleteMultipleSales(List<int> saleIds) async {
    try {
      _setDataState(SalesDataState.loading);

      for (final saleId in saleIds) {
        await _dbHelper.deleteSale(saleId);
      }

      _allSales.removeWhere((sale) => saleIds.contains(sale.id));
      _categorizeSales();
      _calculateTotals();

      _setDataState(SalesDataState.loaded);
    } catch (e) {
      _handleError('Toplu silme işlemi sırasında hata', e);
      rethrow;
    }
  }

  // Analytics methods

  Map<String, double> getSalesAnalytics() {
    return {
      'totalSales': totalSalesAmount,
      'customerSales': _totalCustomerSales,
      'restaurantSales': _totalRestaurantSales,
      'paidAmount': _totalPaidAmount,
      'unpaidAmount': _totalUnpaidAmount,
      'customerDebt': totalCustomerDebt,
      'customerPaid': totalCustomerPaid,
    };
  }

  Map<String, int> getSalesCount() {
    return {
      'totalSales': _allSales.length,
      'customerSales': _customerSales.length,
      'restaurantSales': _restaurantSales.length,
      'paidSales': _paidSales.length,
      'unpaidSales': _unpaidSales.length,
    };
  }

  // Refresh data
  Future<void> refresh() async {
    await loadSales();
  }

  /// Context7 pattern: Execute operation with retry and state recovery
  Future<void> _executeWithRetry(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await operation();
        return; // Success
      } catch (e) {
        if (kDebugMode) {
          Logger.error('SalesProvider operation attempt $attempt failed', e);
        }

        if (attempt < _maxRetries) {
          _setDataState(SalesDataState.recovering);
          await Future.delayed(_retryDelay * attempt);
          continue;
        }

        // Final attempt failed
        _handleError(errorMessage, e);
        rethrow;
      }
    }
  }
}
