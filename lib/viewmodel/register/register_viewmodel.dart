import 'package:flutter/material.dart';
import 'package:vivu_tet/data/interfaces/repositories/iauth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final IauthRepository _repository;

  RegisterViewModel(this._repository);

  bool _loading = false;
  String? _error;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _agreeToTerms = false;
  DateTime? _selectedDob;

  bool get loading => _loading;
  String? get error => _error;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmVisible => _isConfirmVisible;
  bool get agreeToTerms => _agreeToTerms;
  DateTime? get selectedDob => _selectedDob;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    _isConfirmVisible = !_isConfirmVisible;
    notifyListeners();
  }

  void toggleAgreeToTerms(bool? val) {
    _agreeToTerms = val ?? false;
    notifyListeners();
  }

  void setDob(DateTime date) {
    _selectedDob = date;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String passWord,
    required String confirmPassword,
  }) async {
    // Validate
    if (fullName.trim().isEmpty || email.trim().isEmpty || passWord.isEmpty) {
      _error = 'Vui lòng nhập đầy đủ thông tin.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      _error = 'Email không hợp lệ.';
      notifyListeners();
      return false;
    }
    if (passWord != confirmPassword) {
      _error = 'Mật khẩu xác nhận không khớp.';
      notifyListeners();
      return false;
    }
    if (passWord.length < 6) {
      _error = 'Mật khẩu phải có ít nhất 6 ký tự.';
      notifyListeners();
      return false;
    }
    if (!_agreeToTerms) {
      _error = 'Bạn cần đồng ý với điều khoản để tiếp tục.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _repository.register(
        fullName: fullName.trim(),
        email: email.trim(),
        passWord: passWord,
        dob: _selectedDob?.toIso8601String(),
      );

      _loading = false;
      if (!ok) _error = 'Email này đã được sử dụng.';
      notifyListeners();
      return ok;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
