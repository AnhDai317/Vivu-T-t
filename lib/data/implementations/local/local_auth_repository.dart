import 'dart:convert';
import 'package:crypto/crypto.dart'; 

@override
Future<void> changePassword({
  required String userId,
  required String oldPassword,
  required String newPassword,
}) async {
  final db = await _db.database;

  // Lấy user từ DB
  final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
  if (rows.isEmpty) throw Exception('Người dùng không tồn tại');

  // Kiểm tra mật khẩu cũ
  final oldHash = sha256.convert(utf8.encode(oldPassword)).toString();
  if (rows.first['password_hash'] != oldHash) {
    throw Exception('Mật khẩu hiện tại không đúng');
  }

  // Cập nhật mật khẩu mới
  final newHash = sha256.convert(utf8.encode(newPassword)).toString();
  await db.update(
    'users',
    {'password_hash': newHash},
    where: 'id = ?',
    whereArgs: [userId],
  );
}
