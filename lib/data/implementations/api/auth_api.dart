import 'package:sqflite/sqflite.dart';
import 'package:vivu_tet/data/dtos/auth/login_request_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/login_response_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/register_request_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/user_dto.dart';
import '../../interfaces/api/iauth_api.dart';
import '../local/app_database.dart';
import '../local/password_hasher.dart';

class AuthApi implements IauthApi {
  final AppDatabase database;

  AuthApi(this.database);

  // ── LOGIN ────────────────────────────────────────────────────────────────
  @override
  Future<LoginResponseDto> login(LoginRequestDtos req) async {
    final db = await database.db;

    // 1. Tìm user theo email
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [req.email.trim().toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }

    final userRow = rows.first;
    final storedHash = (userRow['password_hash'] ?? '').toString();
    final inputHash = PasswordHasher.sha256Hash(req.passWord);

    if (storedHash != inputHash) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }

    // 2. Tạo token và lưu session
    final userId = userRow['id'] as int;
    final token = 'vivu_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    await db.insert('session', {
      'id': 1,
      'user_id': userId,
      'token': token,
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final userDto = UserDto.fromMap(userRow);
    return LoginResponseDto(token: token, user: userDto);
  }

  // ── REGISTER ─────────────────────────────────────────────────────────────
  @override
  Future<bool> register(RegisterRequestDto req) async {
    final db = await database.db;

    try {
      await db.insert('users', {
        'full_name': req.fullName.trim(),
        'email': req.email.trim().toLowerCase(),
        'password_hash': PasswordHasher.sha256Hash(req.passWord),
        'dob': req.dob,
      });
      return true;
    } catch (_) {
      // UNIQUE constraint → email đã tồn tại
      return false;
    }
  }

  // ── GET CURRENT SESSION ──────────────────────────────────────────────────
  @override
  Future<LoginResponseDto?> getCurrentSession() async {
    final db = await database.db;

    final sessionRows = await db.query('session', where: 'id = 1', limit: 1);
    if (sessionRows.isEmpty) return null;

    final sessionRow = sessionRows.first;
    final userId = sessionRow['user_id'] as int;
    final token = (sessionRow['token'] ?? '').toString();

    final userRows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (userRows.isEmpty) return null;

    final userDto = UserDto.fromMap(userRows.first);
    return LoginResponseDto(token: token, user: userDto);
  }

  // ── LOGOUT ───────────────────────────────────────────────────────────────
  @override
  Future<void> logout() async {
    final db = await database.db;
    await db.delete('session');
  }
}
