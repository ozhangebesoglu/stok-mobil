class Product {
  final int? id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'] ?? 0.0,
      unit: map['unit'],
      purchasePrice: map['purchasePrice'] ?? 0.0,
      sellingPrice: map['sellingPrice'] ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
