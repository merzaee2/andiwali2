import '../db/database_helper.dart';
import '../models/transaction.dart';

class TransactionRepo {
  static Future<List<Transaction>> getTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('transaction', orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  static Future<int> addTransaction(Transaction t) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('transaction', t.toMap());
  }

  static Future<int> updateTransaction(Transaction t) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('transaction', t.toMap(), where: 't_id = ?', whereArgs: [t.t_id]);
  }

  static Future<int> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('transaction', where: 't_id = ?', whereArgs: [id]);
  }
}