import 'package:vivu_tet/data/dtos/auth/login_response_dtos.dart';
import 'package:vivu_tet/domain/entities/auth_session.dart';
import 'package:vivu_tet/domain/entities/user.dart';
import '../../interfaces/mapper/imapper.dart';

class AuthMapper implements Imapper<LoginResponseDto, AuthSession> {
  @override
  AuthSession map(LoginResponseDto input) {
    return AuthSession(
      token: input.token,
      user: User(
        id: input.user.id,
        email: input.user.email,
        fullName: input.user.fullName,
      ),
    );
  }
}
