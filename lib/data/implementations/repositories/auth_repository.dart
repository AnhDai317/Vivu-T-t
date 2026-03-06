import 'package:vivu_tet/data/dtos/auth/login_request_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/login_response_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/register_request_dtos.dart';
import 'package:vivu_tet/domain/entities/auth_session.dart';

import '../../interfaces/api/iauth_api.dart';
import '../../interfaces/mapper/imapper.dart';
import '../../interfaces/repositories/iauth_repository.dart';

class AuthRepository implements IauthRepository {
  final IauthApi api;
  final Imapper<LoginResponseDto, AuthSession> mapper;

  AuthRepository({required this.api, required this.mapper});

  @override
  Future<AuthSession> login(String email, String passWord) async {
    final req = LoginRequestDtos(email: email, passWord: passWord);
    final dto = await api.login(req);
    return mapper.map(dto);
  }

  @override
  Future<bool> register({
    required String fullName,
    required String email,
    required String passWord,
    String? dob,
  }) async {
    final req = RegisterRequestDto(
      fullName: fullName,
      email: email,
      passWord: passWord,
      dob: dob,
    );
    return api.register(req);
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final dto = await api.getCurrentSession();
    if (dto == null) return null;
    return mapper.map(dto);
  }

  @override
  Future<void> logout() => api.logout();

  @override
  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) => api.changePassword(
    userId: userId,
    oldPassword: oldPassword,
    newPassword: newPassword,
  );
}
