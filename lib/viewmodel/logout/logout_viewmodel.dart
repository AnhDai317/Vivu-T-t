import 'package:flutter/material.dart';

class LogoutViewModel extends ChangeNotifier {
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _isLoggingOut = false;
    notifyListeners();
  }

  void reset() {
    _isLoggingOut = false;
    notifyListeners();
  }
}
