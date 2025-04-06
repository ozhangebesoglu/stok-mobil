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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'date': date,
      'isPaid': isPaid ? 1 : 0,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      amount: map['amount'],
      date: map['date'],
      isPaid: map['isPaid'] == 1,
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0.0,
      unit: map['unit'] ?? '',
      unitPrice: map['unitPrice'] ?? 0.0,
      notes: map['notes'],
    );
  }
}
