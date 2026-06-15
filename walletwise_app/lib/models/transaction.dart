class Transaction {
  final int id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;
  final String? note;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      category: json['category'],
      date: json['date'],
      note: json['note'],
    );
  }
}