
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:login_app/domain/entities/user.dart';
import 'package:login_app/infraestructure/models/user_updated_response.dart';

abstract class AuthRepository {

  Future<void> fetchCsrfToken();

  Future<void> checkCookies();

  Future<bool> login(BuildContext context,String email, String password);

  Future<UserEntity> authVerifyUser(); 

  Future<void> logout(BuildContext context);

  Future<Uint8List?> fetchUserImage(String imagePath);

  Future<UserUpdatedResponse> updateUser(UserEntity user);

}