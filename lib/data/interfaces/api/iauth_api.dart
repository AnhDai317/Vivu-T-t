import 'package:vivu_tet/data/dtos/auth/login_request_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/login_response_dtos.dart';
import 'package:vivu_tet/data/dtos/auth/register_request_dtos.dart';

abstract class IauthApi {
  Future<LoginResponseDto> login(LoginRequestDtos req);
  Future<bool> register(RegisterRequestDto req);
  Future<LoginResponseDto?> getCurrentSession();
  Future<void> logout();
}
