
import 'package:vivu_tet/data/implementations/api/auth_api.dart';
import 'package:vivu_tet/data/implementations/local/app_database.dart';
import 'package:vivu_tet/data/implementations/mapper/auth_mapper.dart';
import 'package:vivu_tet/data/implementations/repositories/auth_repository.dart';
import 'package:vivu_tet/viewmodel/login/login_viewmodel.dart';
import 'package:vivu_tet/viewmodel/logout/logout_viewmodel.dart';
import 'package:vivu_tet/viewmodel/register/register_viewmodel.dart';

/// Khởi tạo toàn bộ dependency chain cho Login
LoginViewModel buildLogin() {
  final api = AuthApi(AppDatabase.instance);
  final mapper = AuthMapper();
  final repo = AuthRepository(api: api, mapper: mapper);
  return LoginViewModel(repo);
}

/// Khởi tạo toàn bộ dependency chain cho Register
RegisterViewModel buildRegister() {
  final api = AuthApi(AppDatabase.instance);
  final mapper = AuthMapper();
  final repo = AuthRepository(api: api, mapper: mapper);
  return RegisterViewModel(repo);
}

/// LogoutViewModel – standalone
LogoutViewModel buildLogout() => LogoutViewModel();
