import '../db/database_helper.dart';
import '../models/book.dart';

class BookRepo {
  static Future<List<Book>> getBooks() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book', orderBy: 'b_name ASC');
    return rows.map(Book.fromMap).toList();
  }

  static Future<int> addBook(Book b) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('book', b.toMap());
  }

  static Future<int> updateBook(Book b) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('book', b.toMap(), where: 'b_id = ?', whereArgs: [b.b_id]);
  }

  static Future<int> deleteBook(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('book', where: 'b_id = ?', whereArgs: [id]);
  }

  static Future<List<int>> getAssignedMemberIds(int bId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('book_member',
        columns: ['m_id'],
        where: 'b_id = ?',
        whereArgs: [bId]
    );
    return rows.map((r) => r['m_id'] as int).toList();
  }

  static Future<void> saveAssignedMembers(int bId, List<int> mIds) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    batch.delete('book_member', where: 'b_id = ?', whereArgs: [bId]);

    for (final mId in mIds) {
      batch.insert('book_member', {'b_id': bId, 'm_id': mId});
    }

    await batch.commit(noResult: true);
  }

}