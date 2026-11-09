import '../db/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepo {
  static Future<List<Expense>> getExpenses() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('expense', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  static Future<int> addExpense(Expense e) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('expense', e.toMap());
  }

  // NEW: Update method
  static Future<int> updateExpense(Expense e) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('expense', e.toMap(), where: 'e_id = ?', whereArgs: [e.e_id]);
  }

  static Future<int> deleteExpense(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('expense', where: 'e_id = ?', whereArgs: [id]);
  }

  static Future<Set<int>> getMembersWithExpensesForBook(int bId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'expense',
      columns: ['paid_by'],
      where: 'b_id = ?',
      whereArgs: [bId],
      distinct: true,
    );
    return rows.map((r) => r['paid_by'] as int).toSet();
  }
}