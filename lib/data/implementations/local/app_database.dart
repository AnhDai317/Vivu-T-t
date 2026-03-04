import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Bật foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── Tạo toàn bộ schema lần đầu ─────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    // ── Bảng users ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id          TEXT PRIMARY KEY,
        full_name   TEXT NOT NULL,
        email       TEXT NOT NULL UNIQUE,
        password    TEXT NOT NULL,
        dob         TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    // ── Bảng sessions ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sessions (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        token       TEXT NOT NULL UNIQUE,
        created_at  TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ── Bảng trips ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE trips (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        start_date  TEXT NOT NULL,
        end_date    TEXT NOT NULL
      )
    ''');

    // ── Bảng trip_activities ─────────────────────────────────────
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

    // ── Bảng checklist_categories ────────────────────────────────
    await db.execute('''
      CREATE TABLE checklist_categories (
        id          TEXT PRIMARY KEY,
        icon        TEXT NOT NULL,
        title       TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Bảng checklist_items ─────────────────────────────────────
    await db.execute('''
      CREATE TABLE checklist_items (
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

    // Seed dữ liệu checklist mặc định
    await _seedChecklist(db);
  }

  // ── Migration ────────────────────────────────────────────────────
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: thêm bảng trips + trip_activities
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

    // v2 → v3: thêm bảng checklist
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
  }

  // ── Seed checklist mặc định ──────────────────────────────────────
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

    final items = [
      // ── Sắm Tết ───────────────────────────────────────────────
      {
        'id': 'i_1_1',
        'category_id': 'cat_1',
        'title': 'Mua bánh chưng / bánh tét',
        'sort_order': 0,
      },
      {
        'id': 'i_1_2',
        'category_id': 'cat_1',
        'title': 'Mua mứt Tết',
        'sort_order': 1,
      },
      {
        'id': 'i_1_3',
        'category_id': 'cat_1',
        'title': 'Mua hoa đào / mai',
        'sort_order': 2,
      },
      {
        'id': 'i_1_4',
        'category_id': 'cat_1',
        'title': 'Quần áo mới cho cả nhà',
        'sort_order': 3,
      },
      {
        'id': 'i_1_5',
        'category_id': 'cat_1',
        'title': 'Phong bì lì xì',
        'sort_order': 4,
      },
      {
        'id': 'i_1_6',
        'category_id': 'cat_1',
        'title': 'Hương & nến thờ',
        'sort_order': 5,
      },

      // ── Dọn nhà ───────────────────────────────────────────────
      {
        'id': 'i_2_1',
        'category_id': 'cat_2',
        'title': 'Dọn dẹp toàn bộ nhà',
        'sort_order': 0,
      },
      {
        'id': 'i_2_2',
        'category_id': 'cat_2',
        'title': 'Trang trí cây mai / đào',
        'sort_order': 1,
      },
      {
        'id': 'i_2_3',
        'category_id': 'cat_2',
        'title': 'Trang trí đèn lồng',
        'sort_order': 2,
      },
      {
        'id': 'i_2_4',
        'category_id': 'cat_2',
        'title': 'Lau dọn bàn thờ',
        'sort_order': 3,
      },
      {
        'id': 'i_2_5',
        'category_id': 'cat_2',
        'title': 'Thay ga gối mới',
        'sort_order': 4,
      },

      // ── Ẩm thực ───────────────────────────────────────────────
      {
        'id': 'i_3_1',
        'category_id': 'cat_3',
        'title': 'Chuẩn bị nguyên liệu gói bánh',
        'sort_order': 0,
      },
      {
        'id': 'i_3_2',
        'category_id': 'cat_3',
        'title': 'Nấu thịt kho tàu',
        'sort_order': 1,
      },
      {
        'id': 'i_3_3',
        'category_id': 'cat_3',
        'title': 'Làm dưa hành / kiệu',
        'sort_order': 2,
      },
      {
        'id': 'i_3_4',
        'category_id': 'cat_3',
        'title': 'Đặt bàn ăn tất niên',
        'sort_order': 3,
      },
      {
        'id': 'i_3_5',
        'category_id': 'cat_3',
        'title': 'Mua rượu / nước ngọt đãi khách',
        'sort_order': 4,
      },

      // ── Du xuân ───────────────────────────────────────────────
      {
        'id': 'i_4_1',
        'category_id': 'cat_4',
        'title': 'Đặt vé / phương tiện di chuyển',
        'sort_order': 0,
      },
      {
        'id': 'i_4_2',
        'category_id': 'cat_4',
        'title': 'Đặt khách sạn nếu đi xa',
        'sort_order': 1,
      },
      {
        'id': 'i_4_3',
        'category_id': 'cat_4',
        'title': 'Lên lịch thăm họ hàng',
        'sort_order': 2,
      },
      {
        'id': 'i_4_4',
        'category_id': 'cat_4',
        'title': 'Chuẩn bị quà biếu',
        'sort_order': 3,
      },
      {
        'id': 'i_4_5',
        'category_id': 'cat_4',
        'title': 'Sạc pin điện thoại / máy ảnh',
        'sort_order': 4,
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

    for (final item in items) {
      batch.insert('checklist_items', {
        ...item,
        'done': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  // ── Xoá DB (dùng khi debug) ──────────────────────────────────────
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vivu_tet.db');
    await databaseFactory.deleteDatabase(path);
    _db = null;
  }
}
