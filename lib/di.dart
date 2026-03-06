// Data Layer
import 'package:vivu_tet/data/implementations/api/auth_api.dart';
import 'package:vivu_tet/data/implementations/local/app_database.dart';
// AuthMapper nằm trong mapper/, AuthRepository nằm trong repositories/
import 'package:vivu_tet/data/implementations/mapper/auth_mapper.dart';
import 'package:vivu_tet/data/implementations/repositories/auth_repository.dart';
import 'package:vivu_tet/data/implementations/repositories/checklist_repository.dart';
import 'package:vivu_tet/data/implementations/repositories/trip_repository.dart';
// ViewModel Layer
import 'package:vivu_tet/viewmodel/checklist/checklist_viewmodel.dart';
import 'package:vivu_tet/viewmodel/home/home_viewmodel.dart';
import 'package:vivu_tet/viewmodel/login/login_viewmodel.dart';
import 'package:vivu_tet/viewmodel/logout/logout_viewmodel.dart';
import 'package:vivu_tet/viewmodel/planner/create_trip_viewmodel.dart';
import 'package:vivu_tet/viewmodel/register/register_viewmodel.dart';

// Helper để tránh lặp lại code cho AuthRepository
AuthRepository _getAuthRepo() {
  final api = AuthApi(AppDatabase.instance);
  final mapper = AuthMapper();
  return AuthRepository(api: api, mapper: mapper);
}

// Factory Methods
LoginViewModel buildLogin() => LoginViewModel(_getAuthRepo());

RegisterViewModel buildRegister() => RegisterViewModel(_getAuthRepo());

LogoutViewModel buildLogout() => LogoutViewModel();

CreateTripViewModel buildCreateTrip() =>
    CreateTripViewModel(TripRepository(AppDatabase.instance));

HomeViewModel buildHome() =>
    HomeViewModel(TripRepository(AppDatabase.instance));

ChecklistViewModel buildChecklist() {
  final repo = ChecklistRepository(AppDatabase.instance);
  return ChecklistViewModel(repo)..loadCategories();
}
