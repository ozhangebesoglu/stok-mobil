class Product {
  final int? id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final double? minStockLevel;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.minStockLevel,
  });

  /// Context7 pattern: Convert to database map with validation and null safety
  Map<String, dynamic> toMap() {
    // Validate and sanitize all required fields
    final sanitizedName = name.trim().isEmpty ? 'Adsız Ürün' : name.trim();
    final sanitizedCategory =
        category.trim().isEmpty ? 'Genel' : category.trim();
    final sanitizedUnit = unit.trim().isEmpty ? 'adet' : unit.trim();
    final validQuantity = quantity.isFinite && quantity >= 0 ? quantity : 0.0;
    final validPurchasePrice =
        purchasePrice.isFinite && purchasePrice >= 0 ? purchasePrice : 0.0;
    final validSellingPrice =
        sellingPrice.isFinite && sellingPrice >= 0 ? sellingPrice : 0.0;
    final validMinStockLevel =
        (minStockLevel?.isFinite ?? false) && minStockLevel! >= 0
            ? minStockLevel!
            : 0.0;

    return {
      'id': id,
      'name': sanitizedName,
      'category': sanitizedCategory,
      'unit': sanitizedUnit,
      'quantity': validQuantity,
      'purchasePrice': validPurchasePrice,
      'sellingPrice': validSellingPrice,
      'lastUpdated':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'minStockLevel': validMinStockLevel,
      'description': description?.trim() ?? '',
      'isActive': isActive ? 1 : 0,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0.0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0.0).toDouble(),
      description: map['description'],
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      isActive: (map['isActive'] ?? 1) == 1,
      minStockLevel: map['minStockLevel']?.toDouble(),
    );
  }

  // Kopyalama metodları
  Product copyWith({
    int? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? minStockLevel,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      minStockLevel: minStockLevel ?? this.minStockLevel,
    );
  }

  // Fiyat güncellemesi için özel method
  Product updatePrices({
    required double newPurchasePrice,
    required double newSellingPrice,
  }) {
    return copyWith(
      purchasePrice: newPurchasePrice,
      sellingPrice: newSellingPrice,
      updatedAt: DateTime.now(),
    );
  }

  // Stok güncellemesi için özel method
  Product updateStock({required double newQuantity}) {
    return copyWith(quantity: newQuantity, updatedAt: DateTime.now());
  }

  // Kar marjı hesaplama
  double get profitMargin {
    if (purchasePrice == 0) return 0;
    return ((sellingPrice - purchasePrice) / purchasePrice) * 100;
  }

  // Kar tutarı hesaplama
  double get profitAmount {
    return sellingPrice - purchasePrice;
  }

  // Stok durumu kontrolü
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return quantity <= minStockLevel!;
  }

  // Stok durumu string'i
  String get stockStatus {
    if (quantity <= 0) return 'Stokta Yok';
    if (isLowStock) return 'Düşük Stok';
    return 'Stokta Var';
  }

  // Toplam değer hesaplama
  double get totalValue {
    return quantity * sellingPrice;
  }

  // Validation
  bool get isValid {
    return name.isNotEmpty &&
        category.isNotEmpty &&
        unit.isNotEmpty &&
        purchasePrice >= 0 &&
        sellingPrice >= 0 &&
        quantity >= 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, name, category);

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, quantity: $quantity, unit: $unit, purchasePrice: $purchasePrice, sellingPrice: $sellingPrice)';
  }
}

// Fiyat geçmişi için ayrı model
class ProductPriceHistory {
  final int? id;
  final int productId;
  final double oldPurchasePrice;
  final double newPurchasePrice;
  final double oldSellingPrice;
  final double newSellingPrice;
  final DateTime changedAt;
  final String? reason;

  ProductPriceHistory({
    this.id,
    required this.productId,
    required this.oldPurchasePrice,
    required this.newPurchasePrice,
    required this.oldSellingPrice,
    required this.newSellingPrice,
    required this.changedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'oldPurchasePrice': oldPurchasePrice,
      'newPurchasePrice': newPurchasePrice,
      'oldSellingPrice': oldSellingPrice,
      'newSellingPrice': newSellingPrice,
      'changedAt': changedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory ProductPriceHistory.fromMap(Map<String, dynamic> map) {
    return ProductPriceHistory(
      id: map['id'],
      productId: map['productId'],
      oldPurchasePrice: (map['oldPurchasePrice'] ?? 0.0).toDouble(),
      newPurchasePrice: (map['newPurchasePrice'] ?? 0.0).toDouble(),
      oldSellingPrice: (map['oldSellingPrice'] ?? 0.0).toDouble(),
      newSellingPrice: (map['newSellingPrice'] ?? 0.0).toDouble(),
      changedAt: DateTime.parse(map['changedAt']),
      reason: map['reason'],
    );
  }

  // Fiyat değişimi yüzdesi
  double get purchasePriceChangePercent {
    if (oldPurchasePrice == 0) return 0;
    return ((newPurchasePrice - oldPurchasePrice) / oldPurchasePrice) * 100;
  }

  double get sellingPriceChangePercent {
    if (oldSellingPrice == 0) return 0;
    return ((newSellingPrice - oldSellingPrice) / oldSellingPrice) * 100;
  }
}
