class Expense {
  int? e_id;
  int b_id;
  String item;
  double total_price;
  DateTime date;
  int paid_by;
  bool is_settled;

  Expense({
    this.e_id,
    required this.b_id,
    required this.item,
    required this.total_price,
    required this.date,
    required this.paid_by,
    this.is_settled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'e_id': e_id,
      'b_id': b_id,
      'item': item,
      'total_price': total_price,
      'date': date.toIso8601String(),
      'paid_by': paid_by,
      'is_settled': is_settled ? 1 : 0,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      e_id: map['e_id'],
      b_id: map['b_id'],
      item: map['item'],
      total_price: (map['total_price'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      paid_by: map['paid_by'],
      is_settled: map['is_settled'] == 1,
    );
  }
}