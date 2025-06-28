class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final double balance;
  final String type; // 'customer' veya 'restaurant'
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0.0,
    this.type = 'customer',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Context7 Pattern: Immutable updates with validation
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Context7 Pattern: Business logic validation
  bool get isValid {
    return name.trim().isNotEmpty && ['customer', 'restaurant'].contains(type);
  }

  /// Business logic methods
  bool get hasDebt => balance > 0;
  bool get hasCredit => balance < 0;
  bool get isRestaurant => type == 'restaurant';
  bool get isCustomer => type == 'customer';

  /// Context7 Pattern: Debt status categorization
  String get debtStatus {
    if (balance > 100) return 'high_debt';
    if (balance > 0) return 'low_debt';
    if (balance < 0) return 'credit';
    return 'clear';
  }

  /// Format balance for display
  String get formattedBalance {
    return balance.abs().toStringAsFixed(2);
  }

  /// Get balance display text
  String get balanceDisplayText {
    if (balance > 0) return '+$formattedBalance ₺ Borç';
    if (balance < 0) return '-$formattedBalance ₺ Alacak';
    return '0.00 ₺';
  }

  /// Context7 pattern: Convert to database map with null safety
  Map<String, dynamic> toMap() {
    // Ensure all required fields have valid defaults
    return {
      'id': id,
      'name': name.trim().isEmpty ? 'Adsız Müşteri' : name.trim(),
      'phone': phone?.trim() ?? '',
      'address': address?.trim() ?? '',
      'balance': balance.isFinite ? balance : 0.0,
      'type': type.trim().isEmpty ? 'customer' : type.trim(),
      'isActive': isActive ? 1 : 0,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'customer',
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.address == address &&
        other.balance == balance &&
        other.type == type &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, phone, address, balance, type, isActive);
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, type: $type, balance: $balance, isActive: $isActive)';
  }
}
