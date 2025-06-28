import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database/database_helper.dart';
import '../core/utils/logger.dart';

enum CustomerDataState { loading, loaded, error, recovering }

class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // State management
  CustomerDataState _dataState = CustomerDataState.loading;
  String? _errorMessage;

  // Data storage
  List<Customer> _allCustomers = [];
  final List<Customer> _activeCustomers = [];
  final List<Customer> _inactiveCustomers = [];

  // Filtered views for performance
  final List<Customer> _customersWithDebt = [];
  final List<Customer> _customersWithoutDebt = [];

  // Search and filter state
  String _searchQuery = '';
  bool _showOnlyWithDebt = false;

  // Cached totals for performance
  double _totalCustomerDebt = 0.0;
  int _totalActiveCustomers = 0;
  int _totalCustomersWithDebt = 0;

  // Getters with immutable returns (Context7 pattern)
  CustomerDataState get dataState => _dataState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _dataState == CustomerDataState.loading;
  bool get hasError => _dataState == CustomerDataState.error;

  List<Customer> get customers => List.unmodifiable(_allCustomers);
  List<Customer> get activeCustomers => List.unmodifiable(_activeCustomers);
  List<Customer> get inactiveCustomers => List.unmodifiable(_inactiveCustomers);
  List<Customer> get customersWithDebt => List.unmodifiable(_customersWithDebt);
  List<Customer> get customersWithoutDebt =>
      List.unmodifiable(_customersWithoutDebt);

  // Filtered customers based on search and filters
  List<Customer> get filteredCustomers {
    List<Customer> filtered = _activeCustomers;

    // Apply debt filter
    if (_showOnlyWithDebt) {
      filtered = filtered.where((customer) => customer.balance > 0).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((customer) {
            return customer.name.toLowerCase().contains(query) ||
                customer.phone.toLowerCase().contains(query) ||
                customer.address.toLowerCase().contains(query);
          }).toList();
    }

    return List.unmodifiable(filtered);
  }

  // Analytics getters
  double get totalCustomerDebt => _totalCustomerDebt;
  int get totalActiveCustomers => _totalActiveCustomers;
  int get totalCustomersWithDebt => _totalCustomersWithDebt;
  double get averageDebtPerCustomer =>
      _totalCustomersWithDebt > 0
          ? _totalCustomerDebt / _totalCustomersWithDebt
          : 0.0;

  // Search and filter methods
  String get searchQuery => _searchQuery;
  bool get showOnlyWithDebt => _showOnlyWithDebt;

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void toggleDebtFilter() {
    _showOnlyWithDebt = !_showOnlyWithDebt;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _showOnlyWithDebt = false;
    notifyListeners();
  }

  // Load customers with categorization
  Future<void> loadCustomers() async {
    await _executeWithRetry(() async {
      _setDataState(CustomerDataState.loading);

      final customersData = await _dbHelper.getAllCustomers();
      _allCustomers =
          customersData.map((data) => Customer.fromMap(data)).toList();

      _categorizeCustomers();
      _calculateTotals();

      _setDataState(CustomerDataState.loaded);
    }, 'Müşteriler yüklenirken hata');
  }

  // Add new customer
  Future<void> addCustomer(Customer customer) async {
    await _executeWithRetry(() async {
      _setDataState(CustomerDataState.loading);

      final customerId = await _dbHelper.insertCustomer(customer.toMap());
      final newCustomer = customer.copyWith(id: customerId);

      _allCustomers.insert(0, newCustomer); // Add at beginning for recency
      _categorizeCustomers();
      _calculateTotals();

      _setDataState(CustomerDataState.loaded);

      Logger.info('Customer added successfully: ${newCustomer.name}');
    }, 'Müşteri eklenirken hata');
  }

  // Update customer
  Future<void> updateCustomer(Customer customer) async {
    await _executeWithRetry(() async {
      final result = await _dbHelper.updateCustomer(customer.toMap());

      if (result > 0) {
        final index = _allCustomers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _allCustomers[index] = customer;
          _categorizeCustomers();
          _calculateTotals();
          notifyListeners();

          Logger.info('Customer updated successfully: ${customer.name}');
        }
      } else {
        throw Exception('Müşteri güncellenemedi - veritabanı hatası');
      }
    }, 'Müşteri güncellenirken hata');
  }

  // Delete customer (soft delete)
  Future<void> deleteCustomer(int customerId) async {
    try {
      // Check if customer has unpaid debts
      final customer = _allCustomers.firstWhere((c) => c.id == customerId);
      if (customer.balance > 0) {
        throw Exception('Borcu olan müşteri silinemez');
      }

      // Soft delete - mark as inactive
      final updatedCustomer = customer.copyWith(isActive: false);
      await updateCustomer(updatedCustomer);
    } catch (e) {
      _handleError('Müşteri silinirken hata', e);
      rethrow;
    }
  }

  // Hard delete customer (admin only)
  Future<void> hardDeleteCustomer(int customerId) async {
    try {
      await _dbHelper.deleteCustomer(customerId);

      _allCustomers.removeWhere((customer) => customer.id == customerId);
      _categorizeCustomers();
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      _handleError('Müşteri kalıcı olarak silinirken hata', e);
      rethrow;
    }
  }

  // Update balance - proper implementation
  Future<void> updateBalance(int customerId, double amount) async {
    await _executeWithRetry(() async {
      final customerIndex = _allCustomers.indexWhere((c) => c.id == customerId);
      if (customerIndex == -1) {
        throw Exception('Müşteri bulunamadı (ID: $customerId)');
      }

      final currentCustomer = _allCustomers[customerIndex];
      final newBalance = currentCustomer.balance + amount;

      Logger.debug('Balance Update - Customer: ${currentCustomer.name}');
      Logger.debug('Current Balance: ${currentCustomer.balance}');
      Logger.debug('Amount: $amount');
      Logger.debug('New Balance: $newBalance');

      // Create updated customer with new balance
      final updatedCustomer = currentCustomer.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      // Update in database
      final result = await _dbHelper.update(
        table: 'customers',
        values: updatedCustomer.toMap(),
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (result > 0) {
        // Update in memory
        _allCustomers[customerIndex] = updatedCustomer;
        _categorizeCustomers();
        _calculateTotals();
        notifyListeners();

        Logger.info('Balance updated successfully for ${updatedCustomer.name}');
      } else {
        throw Exception('Bakiye güncellenemedi - veritabanı hatası');
      }
    }, 'Müşteri bakiyesi güncellenirken hata');
  }

  // Get customer by ID
  Customer? getCustomerById(int customerId) {
    try {
      return _allCustomers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  // Get customers by debt status
  List<Customer> getCustomersByDebtStatus(bool hasDebt) {
    return hasDebt ? customersWithDebt : customersWithoutDebt;
  }

  // Get top debtors
  List<Customer> getTopDebtors({int limit = 10}) {
    final debtors = List<Customer>.from(_customersWithDebt);
    debtors.sort((a, b) => b.balance.compareTo(a.balance));
    return debtors.take(limit).toList();
  }

  // Search customers by multiple criteria
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return activeCustomers;

    final lowerQuery = query.toLowerCase();
    return _activeCustomers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery) ||
          customer.phone.toLowerCase().contains(lowerQuery) ||
          customer.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Private methods for data organization

  void _categorizeCustomers() {
    // Reset categories
    _activeCustomers.clear();
    _inactiveCustomers.clear();
    _customersWithDebt.clear();
    _customersWithoutDebt.clear();

    // Categorize customers
    for (final customer in _allCustomers) {
      // Active/Inactive categorization
      if (customer.isActive) {
        _activeCustomers.add(customer);
      } else {
        _inactiveCustomers.add(customer);
      }

      // Debt categorization (only for active customers)
      if (customer.isActive) {
        if (customer.balance > 0) {
          _customersWithDebt.add(customer);
        } else {
          _customersWithoutDebt.add(customer);
        }
      }
    }

    // Sort by name for consistent ordering
    _activeCustomers.sort((a, b) => a.name.compareTo(b.name));
    _inactiveCustomers.sort((a, b) => a.name.compareTo(b.name));
    _customersWithDebt.sort(
      (a, b) => b.balance.compareTo(a.balance),
    ); // Sort by debt amount
    _customersWithoutDebt.sort((a, b) => a.name.compareTo(b.name));
  }

  void _calculateTotals() {
    _totalCustomerDebt = _customersWithDebt.fold(
      0.0,
      (sum, customer) => sum + customer.balance,
    );
    _totalActiveCustomers = _activeCustomers.length;
    _totalCustomersWithDebt = _customersWithDebt.length;
  }

  void _setDataState(CustomerDataState state) {
    _dataState = state;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(String message, dynamic error) {
    _dataState = CustomerDataState.error;
    _errorMessage = '$message: $error';
    notifyListeners();

    Logger.error('CustomerProvider Error: $message', error);
  }

  // Bulk operations for performance

  Future<void> markMultipleCustomersInactive(List<int> customerIds) async {
    try {
      _setDataState(CustomerDataState.loading);

      for (final customerId in customerIds) {
        final customer = getCustomerById(customerId);
        if (customer != null && customer.balance == 0) {
          await updateCustomer(customer.copyWith(isActive: false));
        }
      }

      _setDataState(CustomerDataState.loaded);
    } catch (e) {
      _handleError('Toplu müşteri deaktivasyonu sırasında hata', e);
      rethrow;
    }
  }

  Future<void> updateMultipleCustomerBalances(
    Map<int, double> balanceUpdates,
  ) async {
    try {
      _setDataState(CustomerDataState.loading);

      for (final entry in balanceUpdates.entries) {
        await updateCustomerBalance(entry.key, entry.value);
      }

      _setDataState(CustomerDataState.loaded);
    } catch (e) {
      _handleError('Toplu bakiye güncelleme sırasında hata', e);
      rethrow;
    }
  }

  // Analytics methods

  Map<String, dynamic> getCustomerAnalytics() {
    return {
      'totalCustomers': _allCustomers.length,
      'activeCustomers': _totalActiveCustomers,
      'inactiveCustomers': _inactiveCustomers.length,
      'customersWithDebt': _totalCustomersWithDebt,
      'customersWithoutDebt': _customersWithoutDebt.length,
      'totalDebt': _totalCustomerDebt,
      'averageDebtPerCustomer': averageDebtPerCustomer,
    };
  }

  Map<String, int> getCustomerCounts() {
    return {
      'total': _allCustomers.length,
      'active': _totalActiveCustomers,
      'inactive': _inactiveCustomers.length,
      'withDebt': _totalCustomersWithDebt,
      'withoutDebt': _customersWithoutDebt.length,
    };
  }

  // Refresh data
  Future<void> refresh() async {
    await loadCustomers();
  }

  // Validation methods

  bool isCustomerNameUnique(String name, {int? excludeId}) {
    return !_allCustomers.any(
      (customer) =>
          customer.name.toLowerCase() == name.toLowerCase() &&
          customer.id != excludeId,
    );
  }

  bool isPhoneNumberUnique(String phone, {int? excludeId}) {
    if (phone.isEmpty) return true; // Empty phone is allowed

    return !_allCustomers.any(
      (customer) => customer.phone == phone && customer.id != excludeId,
    );
  }

  bool canDeleteCustomer(int customerId) {
    final customer = getCustomerById(customerId);
    return customer != null && customer.balance == 0;
  }

  // Update customer balance (for direct balance setting)
  Future<void> updateCustomerBalance(int customerId, double newBalance) async {
    try {
      final customerIndex = _allCustomers.indexWhere((c) => c.id == customerId);
      if (customerIndex == -1) {
        throw Exception('Müşteri bulunamadı (ID: $customerId)');
      }

      final currentCustomer = _allCustomers[customerIndex];

      // Update in database first
      final updatedCustomer = currentCustomer.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateCustomer(updatedCustomer.toMap());

      // Update in memory after successful database update
      _allCustomers[customerIndex] = updatedCustomer;
      _categorizeCustomers();
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      _handleError('Müşteri bakiyesi güncellenirken hata', e);
      rethrow;
    }
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
          Logger.error('CustomerProvider operation attempt $attempt failed', e);
        }

        if (attempt < _maxRetries) {
          _setDataState(CustomerDataState.recovering);
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
