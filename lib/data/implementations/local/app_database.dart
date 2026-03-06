import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;
  static const _uuid = Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vivu_tet.db');

    return await openDatabase(
      path,
      version: 5, // bump version để chạy migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── Tạo toàn bộ schema lần đầu ─────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    // ── users ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        full_name     TEXT NOT NULL,
        email         TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        dob           TEXT,
        created_at    TEXT NOT NULL
      )
    ''');

    // ── session (single-row, id = 1) ──────────────────────────────
    await db.execute('''
      CREATE TABLE session (
        id         INTEGER PRIMARY KEY,
        user_id    TEXT NOT NULL,
        token      TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ── trips ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE trips (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        start_date  TEXT NOT NULL,
        end_date    TEXT NOT NULL
      )
    ''');

    // ── trip_activities ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE trip_activities (
        id        TEXT PRIMARY KEY,
        trip_id   TEXT NOT NULL,
        hour      INTEGER NOT NULL,
        minute    INTEGER NOT NULL,
        title     TEXT NOT NULL,
        location  TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE
      )
    ''');

    // ── checklist_categories ─────────────────────────────────────
    await db.execute('''
      CREATE TABLE checklist_categories (
        id          TEXT PRIMARY KEY,
        icon        TEXT NOT NULL,
        title       TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── checklist_items ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE checklist_items (
        id          TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        title       TEXT NOT NULL,
        done        INTEGER NOT NULL DEFAULT 0,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        item_date   TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (category_id)
          REFERENCES checklist_categories(id)
          ON DELETE CASCADE
      )
    ''');

    await _seedChecklist(db);
  }

  // ── Migration ────────────────────────────────────────────────────
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: thêm trips + trip_activities
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trips (
          id          TEXT PRIMARY KEY,
          title       TEXT NOT NULL,
          start_date  TEXT NOT NULL,
          end_date    TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trip_activities (
          id        TEXT PRIMARY KEY,
          trip_id   TEXT NOT NULL,
          hour      INTEGER NOT NULL,
          minute    INTEGER NOT NULL,
          title     TEXT NOT NULL,
          location  TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (trip_id)
            REFERENCES trips(id)
            ON DELETE CASCADE
        )
      ''');
    }

    // v2 → v3: thêm checklist
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS checklist_categories (
          id          TEXT PRIMARY KEY,
          icon        TEXT NOT NULL,
          title       TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          sort_order  INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS checklist_items (
          id          TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          title       TEXT NOT NULL,
          done        INTEGER NOT NULL DEFAULT 0,
          sort_order  INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (category_id)
            REFERENCES checklist_categories(id)
            ON DELETE CASCADE
        )
      ''');
      await _seedChecklist(db);
    }

    // v3 → v4: thêm cột item_date vào checklist_items
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE checklist_items ADD COLUMN item_date TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
    }

    // v4 → v5: migrate schema users (password → password_hash) và
    //          sessions (TEXT id) → session (INTEGER id)
    if (oldVersion < 5) {
      // Xóa bảng cũ nếu tồn tại rồi tạo lại đúng schema
      // (dữ liệu dev, chấp nhận reset)
      try {
        await db.execute('DROP TABLE IF EXISTS sessions');
      } catch (_) {}
      try {
        await db.execute('DROP TABLE IF EXISTS session');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS session (
          id         INTEGER PRIMARY KEY,
          user_id    TEXT NOT NULL,
          token      TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id)
            REFERENCES users(id)
            ON DELETE CASCADE
        )
      ''');

      // Nếu bảng users dùng cột `password` cũ, tạo lại
      try {
        // Thêm cột password_hash nếu chưa có
        await db.execute(
          'ALTER TABLE users ADD COLUMN password_hash TEXT NOT NULL DEFAULT ""',
        );
        // Copy dữ liệu cũ sang
        await db.execute(
          'UPDATE users SET password_hash = password WHERE password_hash = ""',
        );
      } catch (_) {
        // Cột đã tồn tại hoặc không cần migrate
      }
    }
  }

  // ── Seed categories mặc định ─────────────────────────────────────
  Future<void> _seedChecklist(Database db) async {
    final cats = [
      {
        'id': 'cat_1',
        'icon': '🛍️',
        'title': 'Sắm Tết',
        'color_value': 0xFFE53935,
        'sort_order': 0,
      },
      {
        'id': 'cat_2',
        'icon': '🏠',
        'title': 'Dọn nhà',
        'color_value': 0xFF43A047,
        'sort_order': 1,
      },
      {
        'id': 'cat_3',
        'icon': '🍜',
        'title': 'Ẩm thực',
        'color_value': 0xFFF57C00,
        'sort_order': 2,
      },
      {
        'id': 'cat_4',
        'icon': '✈️',
        'title': 'Du xuân',
        'color_value': 0xFF1E88E5,
        'sort_order': 3,
      },
    ];

    final batch = db.batch();
    for (final cat in cats) {
      batch.insert(
        'checklist_categories',
        cat,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Tạo UUID mới
  String newId() => _uuid.v4();

  // ── Xoá DB (dùng khi debug) ──────────────────────────────────────
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vivu_tet.db');
    await databaseFactory.deleteDatabase(path);
    _db = null;
  }
}
