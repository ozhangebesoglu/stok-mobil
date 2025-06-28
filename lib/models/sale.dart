class Sale {
  final int? id;
  final int? customerId;
  final String customerName;
  final double amount;
  final String date;
  final bool isPaid;
  final int? productId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? notes;
  final String saleType; // 'customer' or 'restaurant'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sale({
    this.id,
    this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    this.isPaid = false,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.notes,
    this.saleType = 'customer',
    this.createdAt,
    this.updatedAt,
  });

  /// Context7 Pattern: Immutable updates with validation
  Sale copyWith({
    int? id,
    int? customerId,
    String? customerName,
    double? amount,
    String? date,
    bool? isPaid,
    int? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? notes,
    String? saleType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      saleType: saleType ?? this.saleType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Context7 Pattern: Business logic validation
  bool get isValid {
    return customerName.trim().isNotEmpty &&
        amount > 0 &&
        quantity > 0 &&
        unitPrice > 0 &&
        productName.trim().isNotEmpty &&
        ['customer', 'restaurant'].contains(saleType);
  }

  /// Business logic methods
  bool get isCustomerSale => saleType == 'customer';
  bool get isRestaurantSale => saleType == 'restaurant';
  bool get isUnpaid => !isPaid;

  /// Context7 Pattern: Sale status categorization
  String get paymentStatus {
    return isPaid ? 'paid' : 'unpaid';
  }

  /// Context7 Pattern: Sale category for analytics
  String get saleCategory {
    if (isRestaurantSale && isPaid) return 'restaurant_paid';
    if (isRestaurantSale && !isPaid) return 'restaurant_unpaid';
    if (isCustomerSale && isPaid) return 'customer_paid';
    if (isCustomerSale && !isPaid) return 'customer_unpaid';
    return 'unknown';
  }

  /// Calculate profit margin if cost is available
  double calculateProfitMargin(double costPrice) {
    if (costPrice <= 0 || unitPrice <= 0) return 0.0;
    return ((unitPrice - costPrice) / unitPrice) * 100;
  }

  /// Format amount for display
  String get formattedAmount {
    return amount.toStringAsFixed(2);
  }

  /// Get display text for payment status
  String get paymentStatusText {
    return isPaid ? 'Ödendi' : 'Ödenmedi';
  }

  /// Get display text for sale type
  String get saleTypeText {
    return isRestaurantSale ? 'Restoran Satışı' : 'Müşteri Satışı';
  }

  /// Context7 pattern: Convert to database map with null safety and validation
  Map<String, dynamic> toMap() {
    // Validate and sanitize all fields
    final sanitizedCustomerName =
        customerName.trim().isEmpty
            ? 'Bilinmeyen Müşteri'
            : customerName.trim();
    final sanitizedProductName =
        productName.trim().isEmpty ? 'Bilinmeyen Ürün' : productName.trim();
    final validAmount = amount.isFinite && amount > 0 ? amount : 0.01;
    final validQuantity = quantity.isFinite && quantity > 0 ? quantity : 0.01;
    final validUnitPrice =
        unitPrice.isFinite && unitPrice > 0 ? unitPrice : 0.01;
    final validSaleType =
        (saleType?.trim().isEmpty ?? true) ? 'customer' : saleType!.trim();

    return {
      'id': id,
      'customerId': customerId,
      'customerName': sanitizedCustomerName,
      'amount': validAmount,
      'date':
          date.trim().isEmpty ? DateTime.now().toIso8601String() : date.trim(),
      'isPaid': isPaid ? 1 : 0,
      'productId': productId,
      'productName': sanitizedProductName,
      'quantity': validQuantity,
      'unit': unit.trim().isEmpty ? 'adet' : unit.trim(),
      'unitPrice': validUnitPrice,
      'notes': notes?.trim() ?? '',
      'saleType': validSaleType,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] ?? '',
      isPaid: (map['isPaid'] ?? 0) == 1,
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      notes: map['notes'],
      saleType: map['saleType'] ?? 'customer',
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale &&
        other.id == id &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.amount == amount &&
        other.date == date &&
        other.isPaid == isPaid &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.unit == unit &&
        other.unitPrice == unitPrice &&
        other.saleType == saleType;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      customerName,
      amount,
      date,
      isPaid,
      productId,
      productName,
      quantity,
      unit,
      unitPrice,
      saleType,
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, customer: $customerName, amount: $amount, type: $saleType, paid: $isPaid)';
  }
}
