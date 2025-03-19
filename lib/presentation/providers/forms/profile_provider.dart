
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:login_app/domain/entities/user.dart';
import 'package:login_app/infraestructure/inputs/inputs.dart';
import 'package:login_app/infraestructure/models/user_updated_response.dart';
import 'package:login_app/infraestructure/repositories/auth_repository_impl.dart';
import 'package:login_app/presentation/providers/auth/auth_provider.dart';
import 'package:login_app/presentation/providers/auth/auth_repository_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:login_app/presentation/providers/forms/login_notifier.dart';

/// 🔥 Proveedor del formulario de perfil
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileFormState>((ref) {
  final authState = ref.watch(authProvider); // ⬅ Obtiene el usuario autenticado
  final loginState = ref.watch(loginProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return ProfileNotifier(authState.user, authRepository, ref, loginState);
});

/// 📌 Estado del formulario de perfil
class ProfileFormState {
  final Email email;
  final Fullname fullname;
  final Role role;
  final Telephone telephone;
  final Active active;
  final Language language;
  final ThemeInput theme;
  final String? image;
  final FormzSubmissionStatus status;
  final bool isLoading;
  final String? errorMessage;
  final bool isNewImage;

  const ProfileFormState({
    this.email = const Email.pure(),
    this.fullname = const Fullname.pure(),
    this.role = const Role.pure(),
    this.telephone = const Telephone.pure(),
    this.active = const Active.pure(),
    this.language = const Language.pure(),
    this.theme = const ThemeInput.pure(),
    this.image = '',
    this.status = FormzSubmissionStatus.initial,
    this.isLoading = false,
    this.errorMessage,
    this.isNewImage = false
  });

  ProfileFormState copyWith({
    Email? email,
    Fullname? fullname,
    Role? role,
    Telephone? telephone,
    Active? active,
    Language? language,
    ThemeInput? theme,
    String? image,
    FormzSubmissionStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool? isNewImage
  }) {
    return ProfileFormState(
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      role: role ?? this.role,
      telephone: telephone ?? this.telephone,
      active: active ?? this.active,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      image: image ?? this.image,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isNewImage: isNewImage ?? this.isNewImage
    );
  }
}

/// 📌 Notifier para manejar el formulario
class ProfileNotifier extends StateNotifier<ProfileFormState> {
  final AuthRepositoryImpl authRepository;
  final Ref ref; // ✅ Para leer otros providers
  final LoginFormState loginState;

  ProfileNotifier(UserEntity? user, this.authRepository, this.ref, this.loginState)
      : super(user != null
            ? ProfileFormState(
                email: Email.dirty(user.email),
                fullname: Fullname.dirty(user.fullname),
                role: Role.dirty(user.role),
                telephone: Telephone.dirty(user.telephone ??''),
                active: Active.dirty(user.active),
                language: Language.dirty(user.language),
                theme: ThemeInput.dirty(user.theme),
                image: user.image,
              )
            : const ProfileFormState());

  Future<void> selectImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Ajusta la calidad de la imagen
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      // ✅ Asegurar que la UI ya está construida antes de actualizar el estado
      Future.delayed(Duration.zero, () {
        state = state.copyWith(image: imageFile.path, status: _validateForm(), isNewImage: true); 
      });
    }
  }


  Future<void> updateUser(BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedUser  = UserEntity(
        id: ref.read(authProvider).user!.id, 
        email: state.email.value,
        fullname: state.fullname.value,
        role: state.role.value,
        telephone: state.telephone.value.isEmpty ? null : state.telephone.value,
        image: state.image, // 🔥 Ahora es un archivo, no Base64
        active: state.active.value,
        theme: state.theme.value,
        language: state.language.value,
      );

      final UserUpdatedResponse userUpdated  = await authRepository.updateUser(updatedUser );

      //print("📤 Respuesta del backend: ${userUpdated}");

      final UserEntity userTempUpdated = UserEntity(
        id: userUpdated.id,
        active: userUpdated.active,
        email: userUpdated.email,
        fullname: userUpdated.fullname,
        language: userUpdated.language,
        role: userUpdated.role,
        theme: userUpdated.theme,
        image: userUpdated.image,
        telephone: userUpdated.telephone
      );
      
      
      //actualizar en authState
      ref.read(authProvider.notifier).updateUser(userTempUpdated);


      if (mounted) {
        state = state.copyWith(isLoading: false, isNewImage: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al actualizar el perfil');
    }
  }

  void resetUserProfile() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      Future.delayed(Duration.zero, () {
        state = state.copyWith(image: user.image);
      });
    }
  }

  void emailChanged(String value) {
    final email = Email.dirty(value);
    state = state.copyWith(
      email: email,
      status: _validateForm(),
    );
  }

  void fullnameChanged(String value) {
    final fullname = Fullname.dirty(value);
    state = state.copyWith(
      fullname: fullname,
      status: _validateForm(),
    );
  }

  void roleChanged(String value) {
    final role = Role.dirty(value);
    state = state.copyWith(
      role: role,
      status: _validateForm(),
    );
  }

  void telephoneChanged(String value) {
    final telephone = Telephone.dirty(value);
    state = state.copyWith(
      telephone: telephone,
      status: _validateForm(),
    );
  }

  void activeChanged(bool value) {
    final active = Active.dirty(value);
    state = state.copyWith(
      active: active,
      status: _validateForm(),
    );
  }

  void languageChanged(String? value) {
    final language = Language.dirty(value ?? '');
    state = state.copyWith(
      language: language,
      status: _validateForm(),
    );
  }

  void themeChanged(int value) {
    final theme = ThemeInput.dirty(value);
    state = state.copyWith(
      theme: theme,
      status: _validateForm(),
    );
  }

  /// 📌 Método para validar el formulario
  FormzSubmissionStatus _validateForm() {
    return Formz.validate([
      state.fullname,
      state.role,
      state.telephone,
      state.language,
      state.email
    ])
        ? FormzSubmissionStatus.success
        : FormzSubmissionStatus.failure;
  }

  /// 🔥 Método para resetear el formulario
  void resetForm(UserEntity user) {
    state = ProfileFormState(
      email: Email.dirty(user.email),
      fullname: Fullname.dirty(user.fullname),
      role: Role.dirty(user.role),
      telephone: Telephone.dirty(user.telephone ?? ''),
      active: Active.dirty(user.active),
      language: Language.dirty(user.language),
      theme: ThemeInput.dirty(user.theme),
    );
  }
}
