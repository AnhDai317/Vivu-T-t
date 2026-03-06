import 'package:flutter/material.dart';
import 'package:vivu_tet/data/interfaces/repositories/iauth_repository.dart';
import 'package:vivu_tet/domain/entities/auth_session.dart';

class LoginViewModel extends ChangeNotifier {
  final IauthRepository _repository;

  LoginViewModel(this._repository);

  bool _loading = false;
  String? _error;
  AuthSession? _session;
  bool _isPasswordVisible = false;

  bool get loading => _loading;
  String? get error => _error;
  AuthSession? get session => _session;
  bool get isPasswordVisible => _isPasswordVisible;

  // ── Actions ──────────────────────────────────────────────
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String passWord) async {
    if (email.trim().isEmpty || passWord.isEmpty) {
      _error = 'Vui lòng nhập đầy đủ email và mật khẩu.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _repository.login(email.trim(), passWord);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      _session = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await _repository.logout();
      _session = null;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Kiểm tra session cũ khi khởi động app
  Future<bool> checkSession() async {
    try {
      _session = await _repository.getCurrentSession();
      notifyListeners();
      return _session != null;
    } catch (_) {
      return false;
    }
  }

  /// Đổi mật khẩu — được gọi từ ProfileScreen
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final userId = _session?.user.id;
    if (userId == null) {
      throw Exception('Chưa đăng nhập');
    }
    await _repository.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
