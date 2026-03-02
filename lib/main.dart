import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/data/implementations/api/auth_api.dart';
import 'package:vivu_tet/data/implementations/local/app_database.dart';
import 'package:vivu_tet/data/implementations/mapper/auth_mapper.dart';
import 'package:vivu_tet/data/implementations/repositories/auth_repository.dart';

import 'package:vivu_tet/presentations/auth/login_page.dart';
import 'package:vivu_tet/main_screen.dart'; // <-- ĐÃ SỬA IMPORT
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/login/login_viewmodel.dart';
import 'package:vivu_tet/viewmodel/logout/logout_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Dependency Injection ─────────────────────────────────────────────────
  final authApi = AuthApi(AppDatabase.instance);
  final authMapper = AuthMapper();
  final authRepo = AuthRepository(api: authApi, mapper: authMapper);
  final loginVm = LoginViewModel(authRepo);

  // Kiểm tra session cũ → tự động đăng nhập nếu còn
  final hasSession = await loginVm.checkSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: loginVm),
        ChangeNotifierProvider(create: (_) => LogoutViewModel()),
      ],
      child: ViVuTetApp(isLoggedIn: hasSession),
    ),
  );
}

class ViVuTetApp extends StatelessWidget {
  const ViVuTetApp({super.key, required this.isLoggedIn});
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViVu Tết',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // <-- ĐÃ SỬA: Gọi MainScreen thay vì HomePage
      home: isLoggedIn ? const MainScreen() : const LoginPage(),
    );
  }
}
