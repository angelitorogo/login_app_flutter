import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:login_app/domain/entities/user.dart';
import 'package:login_app/infraestructure/repositories/auth_repository_impl.dart';
import 'package:login_app/presentation/providers/auth/auth_repository_provider.dart';
import 'package:login_app/presentation/providers/forms/login_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final formNotifier = ref.watch(loginProvider.notifier); 
  return AuthNotifier(authRepository: authRepository, formNotifier: formNotifier);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? csrfToken;
  final String? errorMessage;
  final UserEntity? user; // ✅ Agregamos el usuario autenticado

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.csrfToken,
    this.errorMessage,
    this.user
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? csrfToken,
    String? errorMessage,
    UserEntity? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      csrfToken: csrfToken ?? this.csrfToken,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl authRepository;
  final LoginNotifier  formNotifier;

  AuthNotifier({required this.authRepository, required this.formNotifier}) : super(const AuthState()){
    loadSession(); // ✅ Cargar sesión al iniciar la app
  }


  // ✅ Cargar sesión almacenada en SharedPreferences
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    if (userJson != null && isAuthenticated) {
      final user = UserEntity.fromJson(jsonDecode(userJson)); // Asegúrate de que `UserEntity` tenga un método `fromJson`
      state = state.copyWith(isAuthenticated: true, user: user);
    }
  }


  void updateUser(UserEntity updatedUser) {
    state = state.copyWith(user: updatedUser);
  }


  // ✅ Guardar sesión en SharedPreferences después del login
  Future<void> saveSession(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson())); // Asegúrate de que `UserEntity` tenga un método `toJson`
    await prefs.setBool('isAuthenticated', true);
  }

  // ✅ Eliminar sesión de SharedPreferences al hacer logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setBool('isAuthenticated', false);
  }

  Future<void> login(BuildContext context, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await authRepository.login(context, email, password);


      if (result) {
        await verifyUser();
        formNotifier.resetForm();
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        if (context.mounted) {
          GoRouter.of(context).go('/core');
        }
      } else {
        // ✅ Asegurar que el estado de autenticación es FALSO si el login falla
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Usuario o contraseña incorrectos',
        );
      }


    } catch (e) {
      // ✅ También asegurar que `isAuthenticated = false` en caso de error
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Error al iniciar sesión',
      );
    }
  }


  Future<void> fetchCsrfToken() async {
    state = state.copyWith(isLoading: true);
    try {
      await authRepository.fetchCsrfToken();
      state = state.copyWith(isLoading: false, csrfToken: 'Token cargado correctamente');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al recuperar CSRF Token');
    }
  }

  Future<void> verifyUser() async {

    state = state.copyWith(isLoading: true);

    try {
      final user = await authRepository.authVerifyUser();
      await saveSession(user); // ✅ Guardar sesión
      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al verificar usuario');
    }

  }

  Future<void> logout() async {

    state = state.copyWith(isLoading: true);

    try {

      await authRepository.logout();

      await clearSession(); // ✅ Limpiar sesión en SharedPreferences


      // ✅ Primero, resetear completamente el estado
      state = const AuthState();

      state = state.copyWith(isLoading: false, user: null, isAuthenticated: false);
      /*
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        user: null,
      );
      */
      //print("✅ Estado después de logout: ${state.user?.fullname}");
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al verificar usuario');
    }

  }

}
