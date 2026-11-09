import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    return openDatabase(
      'andiwali.db',
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Members Table
    await db.execute('''
      CREATE TABLE member(
        m_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Books Table
    await db.execute('''
      CREATE TABLE book(
        b_id INTEGER PRIMARY KEY AUTOINCREMENT,
        b_name TEXT NOT NULL,
        b_startDate TEXT,
        b_closeDate TEXT
      )
    ''');

    // 3. Book-Member Join Table (Many-to-Many)
    await db.execute('''
      CREATE TABLE book_member(
        bm_id INTEGER PRIMARY KEY AUTOINCREMENT,
        b_id INTEGER NOT NULL,
        m_id INTEGER NOT NULL,
        FOREIGN KEY (b_id) REFERENCES book(b_id) ON DELETE CASCADE,
        FOREIGN KEY (m_id) REFERENCES member(m_id) ON DELETE CASCADE,
        UNIQUE (b_id, m_id)
      )
    ''');

    // 4. Expenses Table
    await db.execute('''
      CREATE TABLE expense(
        e_id INTEGER PRIMARY KEY AUTOINCREMENT,
        b_id INTEGER NOT NULL,
        item TEXT NOT NULL,
        total_price REAL NOT NULL,
        date TEXT NOT NULL,
        paid_by INTEGER NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (b_id) REFERENCES book(b_id) ON DELETE CASCADE,
        FOREIGN KEY (paid_by) REFERENCES member(m_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
    CREATE TABLE transaction(
      t_id INTEGER PRIMARY KEY AUTOINCREMENT,
      m_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      note TEXT,
      is_settled INTEGER NOT NULL DEFAULT 0,
      type TEXT NOT NULL,
      FOREIGN KEY (m_id) REFERENCES member(m_id) ON DELETE CASCADE
    )
  ''');
  }



}