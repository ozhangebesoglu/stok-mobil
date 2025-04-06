class Restaurant {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String contactName;

  Restaurant({
    this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.contactName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'contactName': contactName,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      name: map['name'],
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      contactName: map['contactName'] ?? '',
    );
  }
}
