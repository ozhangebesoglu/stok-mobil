import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/database/database_helper.dart';
import '../core/utils/logger.dart';

enum StockLoadingState { initial, loading, loaded, error, recovering }

/// Context7 optimized stock provider with comprehensive error handling
/// Features: Real-time updates, transaction support, performance optimization
class StockProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // State management
  List<Product> _products = [];
  StockLoadingState _loadingState = StockLoadingState.initial;
  String? _errorMessage;

  // Filtering and search
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _showLowStockOnly = false;
  bool _showActiveOnly = true;

  // Getters with optimized access
  List<Product> get products => List.unmodifiable(_filteredProducts);
  StockLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == StockLoadingState.loading;
  bool get hasError => _loadingState == StockLoadingState.error;
  bool get isRecovering => _loadingState == StockLoadingState.recovering;
  bool get isEmpty =>
      _products.isEmpty && _loadingState == StockLoadingState.loaded;

  // Search and filter getters
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get showLowStockOnly => _showLowStockOnly;
  bool get showActiveOnly => _showActiveOnly;

  // Computed properties
  List<String> get categories {
    final categorySet = <String>{};
    for (final product in _products) {
      if (product.category.isNotEmpty) {
        categorySet.add(product.category);
      }
    }
    return categorySet.toList()..sort();
  }

  List<Product> get lowStockProducts {
    return _products
        .where((product) => product.isLowStock && product.isActive)
        .toList();
  }

  int get totalProducts => _products.where((p) => p.isActive).length;

  double get totalInventoryValue {
    return _products
        .where((p) => p.isActive)
        .fold(0.0, (sum, product) => sum + product.totalValue);
  }

  int get lowStockCount => lowStockProducts.length;

  // Filtered products based on current filters
  List<Product> get _filteredProducts {
    var filtered =
        _products.where((product) {
          // Active filter
          if (_showActiveOnly && !product.isActive) return false;

          // Low stock filter
          if (_showLowStockOnly && !product.isLowStock) return false;

          // Category filter
          if (_selectedCategory.isNotEmpty &&
              product.category != _selectedCategory) {
            return false;
          }

          // Search query filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final name = product.name.toLowerCase();
            final category = product.category.toLowerCase();
            if (!name.contains(query) && !category.contains(query)) {
              return false;
            }
          }

          return true;
        }).toList();

    // Sort by name for consistency
    filtered.sort((a, b) => a.name.compareTo(b.name));

    return filtered;
  }

  // Context7 pattern: Load products with retry and recovery mechanism
  Future<void> loadProducts() async {
    await _executeWithRetry(() async {
      _setLoadingState(StockLoadingState.loading);

      final results = await _dbHelper.query(
        table: 'products',
        orderBy: 'name ASC',
      );

      _products = results.map((map) => Product.fromMap(map)).toList();
      _setLoadingState(StockLoadingState.loaded);
    }, 'Ürünler yüklenirken hata oluştu');
  }

  // Context7 pattern: Add product with retry mechanism
  Future<bool> addProduct(Product product) async {
    return await _executeWithRetry(
      () async {
        if (!product.isValid) {
          _setError('Ürün bilgileri eksik veya hatalı');
          return false;
        }

        // Check for duplicate names
        if (_products.any(
          (p) =>
              p.name.toLowerCase() == product.name.toLowerCase() && p.isActive,
        )) {
          _setError('Bu isimde bir ürün zaten mevcut');
          return false;
        }

        final productWithTimestamp = product.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await _dbHelper.insert(
          table: 'products',
          values: productWithTimestamp.toMap(),
        );

        final newProduct = productWithTimestamp.copyWith(id: id);
        _products.add(newProduct);

        _clearError();
        notifyListeners();

        if (kDebugMode) {
          Logger.info('Product added successfully: ${newProduct.name}');
        }

        return true;
      },
      'Ürün eklenirken hata oluştu',
      defaultValue: false,
    );
  }

  // Context7 pattern: Update product with retry mechanism
  Future<bool> updateProduct(Product product) async {
    return await _executeWithRetry(
      () async {
        if (!product.isValid) {
          _setError('Ürün bilgileri eksik veya hatalı');
          return false;
        }

        final index = _products.indexWhere((p) => p.id == product.id);
        if (index == -1) {
          _setError('Güncellenecek ürün bulunamadı');
          return false;
        }

        final oldProduct = _products[index];
        final updatedProduct = product.copyWith(updatedAt: DateTime.now());

        // Track price changes
        if (oldProduct.purchasePrice != product.purchasePrice ||
            oldProduct.sellingPrice != product.sellingPrice) {
          await _addPriceHistory(oldProduct, updatedProduct);
        }

        final result = await _dbHelper.update(
          table: 'products',
          values: updatedProduct.toMap(),
          where: 'id = ?',
          whereArgs: [product.id],
        );

        if (result > 0) {
          _products[index] = updatedProduct;
          _clearError();
          notifyListeners();

          if (kDebugMode) {
            Logger.info('Product updated successfully: ${updatedProduct.name}');
          }

          return true;
        } else {
          _setError('Ürün güncellenemedi');
          return false;
        }
      },
      'Ürün güncellenirken hata oluştu',
      defaultValue: false,
    );
  }

  // Update product prices specifically
  Future<bool> updateProductPrices({
    required int productId,
    required double newPurchasePrice,
    required double newSellingPrice,
    String? reason,
  }) async {
    try {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index == -1) {
        _setError('Güncellenecek ürün bulunamadı');
        return false;
      }

      final oldProduct = _products[index];
      final updatedProduct = oldProduct.updatePrices(
        newPurchasePrice: newPurchasePrice,
        newSellingPrice: newSellingPrice,
      );

      // Add price history
      await _addPriceHistory(oldProduct, updatedProduct, reason: reason);

      await _dbHelper.update(
        table: 'products',
        values: updatedProduct.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );

      _products[index] = updatedProduct;

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Fiyatlar güncellenirken hata oluştu: ${e.toString()}');
      Logger.error('StockProvider updateProductPrices error', e);
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock({
    required int productId,
    required double newQuantity,
  }) async {
    try {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index == -1) {
        _setError('Güncellenecek ürün bulunamadı');
        return false;
      }

      if (newQuantity < 0) {
        _setError('Stok miktarı negatif olamaz');
        return false;
      }

      final updatedProduct = _products[index].updateStock(
        newQuantity: newQuantity,
      );

      await _dbHelper.update(
        table: 'products',
        values: updatedProduct.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );

      _products[index] = updatedProduct;

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Stok güncellenirken hata oluştu: ${e.toString()}');
      Logger.error('StockProvider updateStock error', e);
      return false;
    }
  }

  // Soft delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index == -1) {
        _setError('Silinecek ürün bulunamadı');
        return false;
      }

      // Soft delete by setting isActive = false
      final updatedProduct = _products[index].copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.update(
        table: 'products',
        values: updatedProduct.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );

      _products[index] = updatedProduct;

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ürün silinirken hata oluştu: ${e.toString()}');
      Logger.error('StockProvider deleteProduct error', e);
      return false;
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // Category filtering
  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  // Toggle filters
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }

  void toggleActiveFilter() {
    _showActiveOnly = !_showActiveOnly;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _showLowStockOnly = false;
    _showActiveOnly = true;
    notifyListeners();
  }

  // Get product by ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get price history for a product
  Future<List<ProductPriceHistory>> getProductPriceHistory(
    int productId,
  ) async {
    try {
      final results = await _dbHelper.query(
        table: 'product_price_history',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'changedAt DESC',
      );

      return results.map((map) => ProductPriceHistory.fromMap(map)).toList();
    } catch (e) {
      Logger.error('Error getting price history', e);
      return [];
    }
  }

  // Private helper methods
  void _setLoadingState(StockLoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      if (state != StockLoadingState.error) {
        _errorMessage = null;
      }
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _loadingState = StockLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> _addPriceHistory(
    Product oldProduct,
    Product newProduct, {
    String? reason,
  }) async {
    if (oldProduct.id == null) return;

    final priceHistory = ProductPriceHistory(
      productId: oldProduct.id!,
      oldPurchasePrice: oldProduct.purchasePrice,
      newPurchasePrice: newProduct.purchasePrice,
      oldSellingPrice: oldProduct.sellingPrice,
      newSellingPrice: newProduct.sellingPrice,
      changedAt: DateTime.now(),
      reason: reason,
    );

    try {
      await _dbHelper.insert(
        table: 'product_price_history',
        values: priceHistory.toMap(),
      );
    } catch (e) {
      Logger.error('Error adding price history', e);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadProducts();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  /// Context7 pattern: Execute operation with retry and state recovery
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation,
    String errorMessage, {
    T? defaultValue,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (kDebugMode) {
          Logger.error('StockProvider operation attempt $attempt failed', e);
        }

        if (attempt < _maxRetries) {
          _setLoadingState(StockLoadingState.recovering);
          await Future.delayed(_retryDelay * attempt);
          continue;
        }

        // Final attempt failed
        _setError('$errorMessage: ${e.toString()}');
        if (defaultValue != null) {
          return defaultValue;
        }
        rethrow;
      }
    }

    if (defaultValue != null) {
      return defaultValue;
    }
    throw Exception(errorMessage);
  }
}
