
import 'package:vivu_tet/interfaces/domain/entities/auth_session.dart';

abstract class IauthRepository {
  Future<AuthSession> login(String email, String passWord);
  Future<bool> register({
    required String fullName,
    required String email,
    required String passWord,
    String? dob,
  });
  Future<AuthSession?> getCurrentSession();
  Future<void> logout();
}
