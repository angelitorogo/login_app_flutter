

import 'package:login_app/domain/entities/auth.dart';
import 'package:login_app/infraestructure/models/auth_login_response.dart';

class AuthLoginMapper {

  static Auth responseToAuth( AuthLoginResponse response) => Auth(
    csrfToken: response.csrfToken,
    statusCode: response.statusCode,
    message: response.message,
  );

}