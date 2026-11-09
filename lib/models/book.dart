class Book {
  int? b_id;
  String? b_name;
  DateTime? b_startDate;
  DateTime? b_closeDate; // Null means the book is active

  Book({this.b_id, this.b_name, this.b_startDate, this.b_closeDate});

  bool get isClosed => b_closeDate != null;

  Map<String, dynamic> toMap() {
    return {
      'b_id': b_id,
      'b_name': b_name,
      'b_startDate': b_startDate?.toIso8601String(),
      'b_closeDate': b_closeDate?.toIso8601String(),
    };
  }

  static Book fromMap(Map<String, dynamic> map) {
    return Book(
      b_id: map['b_id'],
      b_name: map['b_name'],
      b_startDate: map['b_startDate'] != null ? DateTime.tryParse(map['b_startDate']) : null,
      b_closeDate: map['b_closeDate'] != null ? DateTime.tryParse(map['b_closeDate']) : null,
    );
  }
}