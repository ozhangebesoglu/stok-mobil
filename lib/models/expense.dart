class Expense {
  final int? id;
  final String description;
  final double amount;
  final String date;
  final String category;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date,
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: map['date'],
      category: map['category'],
    );
  }
}
