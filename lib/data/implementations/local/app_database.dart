import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// ignore_for_file: avoid_print

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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── Tạo toàn bộ schema lần đầu ─────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE session (
        id         INTEGER PRIMARY KEY,
        user_id    TEXT NOT NULL,
        token      TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        start_date  TEXT NOT NULL,
        end_date    TEXT NOT NULL
      )
    ''');

    // sort_order có ngay từ đầu
    await db.execute('''
      CREATE TABLE trip_activities (
        id          TEXT PRIMARY KEY,
        trip_id     TEXT NOT NULL,
        hour        INTEGER NOT NULL,
        minute      INTEGER NOT NULL,
        title       TEXT NOT NULL,
        location    TEXT NOT NULL DEFAULT '',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_categories (
        id          TEXT PRIMARY KEY,
        icon        TEXT NOT NULL,
        title       TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id          TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        title       TEXT NOT NULL,
        done        INTEGER NOT NULL DEFAULT 0,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        item_date   TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (category_id)
          REFERENCES checklist_categories(id) ON DELETE CASCADE
      )
    ''');

    await _seedChecklist(db);
    await _seedDemoAccount(db);
  }

  // ── Migration ───────────────────────────────────────────────────────────
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trips (
          id TEXT PRIMARY KEY, title TEXT NOT NULL,
          start_date TEXT NOT NULL, end_date TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trip_activities (
          id TEXT PRIMARY KEY, trip_id TEXT NOT NULL,
          hour INTEGER NOT NULL, minute INTEGER NOT NULL,
          title TEXT NOT NULL, location TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS checklist_categories (
          id TEXT PRIMARY KEY, icon TEXT NOT NULL, title TEXT NOT NULL,
          color_value INTEGER NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS checklist_items (
          id TEXT PRIMARY KEY, category_id TEXT NOT NULL,
          title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (category_id)
            REFERENCES checklist_categories(id) ON DELETE CASCADE
        )
      ''');
      await _seedChecklist(db);
    }

    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE checklist_items ADD COLUMN item_date TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute('DROP TABLE IF EXISTS sessions');
      } catch (_) {}
      try {
        await db.execute('DROP TABLE IF EXISTS session');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session (
          id INTEGER PRIMARY KEY, user_id TEXT NOT NULL,
          token TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN password_hash TEXT NOT NULL DEFAULT ""',
        );
        await db.execute(
          'UPDATE users SET password_hash = password WHERE password_hash = ""',
        );
      } catch (_) {}
    }

    // v5 → v6: thêm sort_order + seed demo
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE trip_activities ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
        );
        // Khởi tạo sort_order cho dữ liệu cũ theo hour/minute
        final trips = await db.query('trips');
        for (final trip in trips) {
          final tid = trip['id'].toString();
          final acts = await db.query(
            'trip_activities',
            where: 'trip_id = ?',
            whereArgs: [tid],
            orderBy: 'hour ASC, minute ASC',
          );
          final batch = db.batch();
          for (int i = 0; i < acts.length; i++) {
            batch.update(
              'trip_activities',
              {'sort_order': i},
              where: 'id = ?',
              whereArgs: [acts[i]['id']],
            );
          }
          await batch.commit(noResult: true);
        }
      } catch (_) {}

      await _seedDemoAccount(db);
    }
  }

  // ── Seed checklist categories ───────────────────────────────────────────
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

  // ── Seed tài khoản demo + lịch trình 21–26/3/2026 ──────────────────────
  Future<void> _seedDemoAccount(Database db) async {
    const userId = 'demo_user_001';
    const email = 'demo@vivutet.vn';
    // sha256('123456') — dùng PasswordHasher.sha256Hash('123456') để xác minh
    const pwdHash =
        '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';

    final existing = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'full_name': 'Nguyễn Xuân An',
      'email': email,
      'password_hash': pwdHash,
      'dob': '1998-02-17',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Auto-login: chèn session sẵn
    await db.insert('session', {
      'id': 1,
      'user_id': userId,
      'token': 'vivu_demo_2026_token',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print('✅ Demo seeded — email: $email  |  password: 123456');

    final batch = db.batch();
    for (final trip in _demoTrips()) {
      batch.insert('trips', {
        'id': trip.id,
        'title': trip.title,
        'start_date': trip.startIso,
        'end_date': trip.endIso,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      for (int i = 0; i < trip.acts.length; i++) {
        final a = trip.acts[i];
        batch.insert('trip_activities', {
          'id': a.id,
          'trip_id': trip.id,
          'hour': a.hour,
          'minute': a.minute,
          'title': a.title,
          'location': a.loc,
          'sort_order': i,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    await batch.commit(noResult: true);
  }

  // ── Data lịch trình ─────────────────────────────────────────────────────
  List<_Trip> _demoTrips() => [
    // ── 21/3 Thứ 7 ─────────────────────────────────────────────────────
    _Trip(
      id: 'trip_20260321',
      title: 'Dạo phố Xuân cuối tuần 🌸',
      startIso: '2026-03-21T00:00:00.000',
      endIso: '2026-03-21T23:59:59.000',
      acts: [
        _Act(
          'act_0321_01',
          7,
          30,
          'Ăn sáng phở Bát Đàn',
          'Phở Bát Đàn, 49 Bát Đàn, Hoàn Kiếm',
        ),
        _Act(
          'act_0321_02',
          9,
          0,
          'Dạo Hồ Hoàn Kiếm buổi sáng',
          'Hồ Hoàn Kiếm, Hoàn Kiếm, Hà Nội',
        ),
        _Act(
          'act_0321_03',
          10,
          30,
          'Thăm Đền Ngọc Sơn',
          'Đền Ngọc Sơn, Hồ Hoàn Kiếm',
        ),
        _Act(
          'act_0321_04',
          12,
          0,
          'Ăn trưa bún chả Hàng Mành',
          'Bún chả Hàng Mành, Hoàn Kiếm',
        ),
        _Act(
          'act_0321_05',
          14,
          0,
          'Văn Miếu Quốc Tử Giám',
          'Văn Miếu, 58 Quốc Tử Giám, Đống Đa',
        ),
        _Act(
          'act_0321_06',
          16,
          30,
          'Cà phê trứng Giảng',
          'Cà phê Giảng, 39 Nguyễn Hữu Huân',
        ),
        _Act(
          'act_0321_07',
          18,
          30,
          'Ăn tối Chả cá Lã Vọng',
          'Chả cá Lã Vọng, 14 Chả Cá, Hoàn Kiếm',
        ),
        _Act(
          'act_0321_08',
          20,
          30,
          'Đi bộ phố đêm Hàng Đào',
          'Phố đi bộ Hàng Đào, Hoàn Kiếm',
        ),
      ],
    ),

    // ── 22/3 Chủ nhật ──────────────────────────────────────────────────
    _Trip(
      id: 'trip_20260322',
      title: 'Chùa chiền & Hồ Tây bình yên 🛕',
      startIso: '2026-03-22T00:00:00.000',
      endIso: '2026-03-22T23:59:59.000',
      acts: [
        _Act(
          'act_0322_01',
          6,
          0,
          'Đạp xe quanh Hồ Tây lúc bình minh',
          'Hồ Tây, Tây Hồ, Hà Nội',
        ),
        _Act(
          'act_0322_02',
          8,
          0,
          'Lễ Chùa Trấn Quốc',
          'Chùa Trấn Quốc, Thanh Niên, Tây Hồ',
        ),
        _Act(
          'act_0322_03',
          9,
          30,
          'Ghé Phủ Tây Hồ cầu may mắn',
          'Phủ Tây Hồ, Tây Hồ, Hà Nội',
        ),
        _Act(
          'act_0322_04',
          11,
          0,
          'Ăn bánh tôm Hồ Tây',
          'Bánh tôm Hồ Tây, Thanh Niên',
        ),
        _Act(
          'act_0322_05',
          14,
          0,
          'Thăm Vườn Đào Nhật Tân',
          'Vườn Đào Nhật Tân, Tây Hồ',
        ),
        _Act(
          'act_0322_06',
          17,
          0,
          'Hoàng hôn tại cầu Nhật Tân',
          'Cầu Nhật Tân, Tây Hồ',
        ),
        _Act(
          'act_0322_07',
          19,
          0,
          'Ăn tối lẩu cá kèo Quảng Bá',
          'Quảng Bá, Tây Hồ, Hà Nội',
        ),
      ],
    ),

    // ── 23/3 Thứ 2 ─────────────────────────────────────────────────────
    _Trip(
      id: 'trip_20260323',
      title: 'Hành trình Ba Đình lịch sử 🏛️',
      startIso: '2026-03-23T00:00:00.000',
      endIso: '2026-03-23T23:59:59.000',
      acts: [
        _Act(
          'act_0323_01',
          7,
          0,
          'Xem lễ chào cờ Lăng Bác',
          'Lăng Chủ tịch Hồ Chí Minh, Ba Đình',
        ),
        _Act(
          'act_0323_02',
          8,
          30,
          'Tham quan Hoàng Thành Thăng Long',
          'Hoàng Thành Thăng Long, 19C Hoàng Diệu',
        ),
        _Act(
          'act_0323_03',
          11,
          0,
          'Ăn trưa xôi lúa Nguyễn Hữu Huân',
          'Xôi lúa, Nguyễn Hữu Huân, Hoàn Kiếm',
        ),
        _Act(
          'act_0323_04',
          13,
          30,
          'Bảo tàng Hồ Chí Minh',
          'Bảo tàng HCM, 19 Ngọc Hà, Ba Đình',
        ),
        _Act(
          'act_0323_05',
          15,
          30,
          'Tản bộ Vườn hoa Lý Thái Tổ',
          'Vườn hoa Lý Thái Tổ, Hoàn Kiếm',
        ),
        _Act(
          'act_0323_06',
          17,
          30,
          'Cà phê view Tháp Rùa',
          'The Note Coffee, 64 Lương Văn Can',
        ),
        _Act(
          'act_0323_07',
          19,
          30,
          'Ăn tối nem cuốn Thanh Hương',
          'Nem cuốn Thanh Hương, Đinh Tiên Hoàng',
        ),
      ],
    ),

    // ── 24/3 Thứ 3 ─────────────────────────────────────────────────────
    _Trip(
      id: 'trip_20260324',
      title: 'Làng cổ Đường Lâm - Sơn Tây 🏡',
      startIso: '2026-03-24T00:00:00.000',
      endIso: '2026-03-24T23:59:59.000',
      acts: [
        _Act(
          'act_0324_01',
          6,
          30,
          'Khởi hành đi Sơn Tây',
          'Hà Nội → Sơn Tây (~50km)',
        ),
        _Act(
          'act_0324_02',
          8,
          30,
          'Ăn sáng bánh cuốn Sơn Tây',
          'Chợ Sơn Tây, Sơn Tây',
        ),
        _Act(
          'act_0324_03',
          9,
          30,
          'Tham quan Làng cổ Đường Lâm',
          'Làng cổ Đường Lâm, Sơn Tây',
        ),
        _Act(
          'act_0324_04',
          11,
          30,
          'Ăn trưa thịt quay đòn & gà Mía',
          'Nhà hàng làng cổ Đường Lâm',
        ),
        _Act(
          'act_0324_05',
          13,
          30,
          'Thành cổ Sơn Tây & Đền Và',
          'Đền Và, Trung Hưng, Sơn Tây',
        ),
        _Act(
          'act_0324_06',
          15,
          30,
          'Hồ Suối Hai nghỉ ngơi',
          'Hồ Suối Hai, Ba Vì',
        ),
        _Act('act_0324_07', 17, 30, 'Về Hà Nội', 'Sơn Tây → Hà Nội'),
        _Act(
          'act_0324_08',
          20,
          0,
          'Ăn tối bún đậu mắm tôm',
          'Bún đậu Cầu Giấy, Hà Nội',
        ),
      ],
    ),

    // ── 25/3 Thứ 4 ─────────────────────────────────────────────────────
    _Trip(
      id: 'trip_20260325',
      title: 'Làng lụa Vạn Phúc & Bát Tràng 🎨',
      startIso: '2026-03-25T00:00:00.000',
      endIso: '2026-03-25T23:59:59.000',
      acts: [
        _Act('act_0325_01', 8, 0, 'Ăn sáng bánh mì Hà Đông', 'Hà Đông, Hà Nội'),
        _Act(
          'act_0325_02',
          9,
          0,
          'Tham quan Làng lụa Vạn Phúc',
          'Làng lụa Vạn Phúc, Hà Đông',
        ),
        _Act(
          'act_0325_03',
          11,
          0,
          'Mua sắm lụa làm quà',
          'Chợ lụa Vạn Phúc, Hà Đông',
        ),
        _Act(
          'act_0325_04',
          12,
          30,
          'Ăn trưa cơm gà Hà Đông',
          'Cơm gà, Quang Trung, Hà Đông',
        ),
        _Act(
          'act_0325_05',
          14,
          30,
          'Di chuyển đến làng gốm Bát Tràng',
          'Làng gốm Bát Tràng, Gia Lâm',
        ),
        _Act(
          'act_0325_06',
          16,
          30,
          'Tự tay nặn gốm trải nghiệm',
          'Xưởng gốm Bát Tràng, Gia Lâm',
        ),
        _Act(
          'act_0325_07',
          18,
          30,
          'Về trung tâm Hà Nội',
          'Bát Tràng → Hoàn Kiếm',
        ),
        _Act(
          'act_0325_08',
          20,
          0,
          'Ăn tối lẩu bò nhúng dấm',
          'Lẩu bò, Lê Văn Hưu, Hai Bà Trưng',
        ),
      ],
    ),

    // ── 26/3 Thứ 5 — Ngày cuối ─────────────────────────────────────────
    _Trip(
      id: 'trip_20260326',
      title: 'Ngày cuối - Ẩm thực & Quà tặng 🎁',
      startIso: '2026-03-26T00:00:00.000',
      endIso: '2026-03-26T23:59:59.000',
      acts: [
        _Act(
          'act_0326_01',
          7,
          0,
          'Ăn sáng bánh cuốn Thanh Trì',
          'Bánh cuốn Thanh Trì, Hoàng Mai',
        ),
        _Act(
          'act_0326_02',
          9,
          0,
          'Chợ Đồng Xuân mua đặc sản',
          'Chợ Đồng Xuân, Đồng Xuân, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_03',
          11,
          0,
          'Phố Hàng Buồm mua bánh kẹo',
          'Phố Hàng Buồm, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_04',
          12,
          30,
          'Ăn trưa lợn quay Bắc Kinh',
          'Lợn quay, Hàng Buồm, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_05',
          14,
          30,
          'Kem Tràng Tiền — check-in',
          'Kem Tràng Tiền, 35 Tràng Tiền',
        ),
        _Act(
          'act_0326_06',
          15,
          30,
          'Nhà hát Lớn Hà Nội',
          'Nhà hát Lớn, 1 Tràng Tiền, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_07',
          17,
          0,
          'Hoàng hôn cầu Long Biên',
          'Cầu Long Biên, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_08',
          19,
          0,
          'Tiệc chia tay — Bữa tối đặc biệt',
          'Nhà hàng Hoa Sứ, Hoàn Kiếm',
        ),
        _Act(
          'act_0326_09',
          21,
          30,
          'Ngắm đêm Hà Nội từ trên cao',
          'Lotte Observation Deck, Ba Đình',
        ),
      ],
    ),
  ];

  String newId() => _uuid.v4();

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vivu_tet.db');
    await databaseFactory.deleteDatabase(path);
    _db = null;
  }
}

// ── Helper models chỉ dùng nội bộ trong file này ─────────────────────────────
class _Trip {
  final String id, title, startIso, endIso;
  final List<_Act> acts;
  const _Trip({
    required this.id,
    required this.title,
    required this.startIso,
    required this.endIso,
    required this.acts,
  });
}

class _Act {
  final String id, title, loc;
  final int hour, minute;
  const _Act(this.id, this.hour, this.minute, this.title, this.loc);
}
