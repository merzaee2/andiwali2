import '../db/database_helper.dart';
import '../models/member.dart';

class MemberRepo {
  static Future<List<Member>> getMembers({bool onlyActive = false}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'member',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'full_name ASC',
    );
    return rows.map(Member.fromMap).toList();
  }

  static Future<int> addMember(Member m) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('member', m.toMap());
  }

  static Future<int> updateMember(Member m) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('member', m.toMap(), where: 'm_id = ?', whereArgs: [m.m_id]);
  }

  static Future<int> deleteMember(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('member', where: 'm_id = ?', whereArgs: [id]);
  }
}