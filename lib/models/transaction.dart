class Transaction {
  int? t_id;
  int m_id;
  double amount;
  DateTime date;
  String? note;
  bool is_settled;
  String type; // 'owes' or 'gets'

  Transaction({
    this.t_id,
    required this.m_id,
    required this.amount,
    required this.date,
    this.note,
    this.is_settled = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      't_id': t_id,
      'm_id': m_id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'is_settled': is_settled ? 1 : 0,
      'type': type,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      t_id: map['t_id'],
      m_id: map['m_id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'],
      is_settled: map['is_settled'] == 1,
      type: map['type'],
    );
  }
}