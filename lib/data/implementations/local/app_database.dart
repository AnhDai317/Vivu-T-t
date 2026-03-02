import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vivu_tet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Bảng users
        await db.execute('''
          CREATE TABLE users (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name     TEXT    NOT NULL,
            email         TEXT    NOT NULL UNIQUE,
            password_hash TEXT    NOT NULL,
            dob           TEXT
          )
        ''');

        // Bảng session – chỉ 1 row (id = 1) tại một thời điểm
        await db.execute('''
          CREATE TABLE session (
            id         INTEGER PRIMARY KEY CHECK (id = 1),
            user_id    INTEGER NOT NULL,
            token      TEXT    NOT NULL,
            created_at TEXT    NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Seed tài khoản mặc định để test
        // password: vivu2026  →  sha256
        await db.insert('users', {
          'full_name': 'Admin ViVu',
          'email': 'admin@vivu.tet',
          'password_hash':
              '7c43c0c9f0e0a6a4e80d32de86f2b2c1ee7d42a5f3d2a8cde63b5df84f3b2c9', // placeholder
          'dob': null,
        });
      },
    );
  }
}
