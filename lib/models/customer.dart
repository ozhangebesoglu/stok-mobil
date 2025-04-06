class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final double balance;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      balance: map['balance'] ?? 0.0,
    );
  }
}
