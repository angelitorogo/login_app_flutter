import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_app/config/constants/environment.dart';
import 'package:login_app/infraestructure/inputs/inputs.dart';
import 'package:login_app/presentation/providers/auth/auth_provider.dart';
import 'package:login_app/presentation/providers/forms/profile_provider.dart';
import 'package:login_app/presentation/widgets/inputs/custom_text_form_filed.dart';
import 'dart:io';

class ProfileScreen extends ConsumerWidget {
  static const name = 'profile-screen';

  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider); // Estado de autenticación
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    
    
    String? userImage = profileState.image;
    //final bool isNewImage = userImage != null && userImage.isNotEmpty && File(userImage).existsSync();

    if( userImage != null && !File(userImage).existsSync()) {
      userImage = null;
    }

    // 🔥 Resetear perfil cada vez que se entra a la pantalla
    //ref.read(profileProvider.notifier).resetUserProfile();
    
    final String imageUrl = "${Environment.apiUrl}/files/${authState.user?.image}";

    final colors = Theme.of(context).colorScheme;


    return PopScope(
      canPop: true, // Permite el pop
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) {
          // Resetea el estado antes de salir
          ref.read(profileProvider.notifier).resetUserProfile();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
      
                // Imagen de perfil
                ClipOval(
                  child: GestureDetector(
                    onTap: () => _showImagePickerDialog(context, ref),
                    child: profileState.isNewImage
                        ? Image.file(
                            File(userImage!), // ✅ Muestra la imagen nueva seleccionada antes de enviarla
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            imageUrl, // ✅ Si no hay nueva imagen, muestra la del backend
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 90,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
      
                const SizedBox(height: 20),
      
                // Fullname
                CustomTextFormFiled(
                  label: 'Nombre Completo',
                  prefixIcon: Icons.person,
                  initialValue: profileState.fullname.value,
                  onChanged: profileNotifier.fullnameChanged,
                  validator: (_) => Fullname.fullnameErrorMessage(profileState.fullname.error),
                ),
                const SizedBox(height: 20),
      
                // Email
                CustomTextFormFiled(
                  label: 'Email',
                  prefixIcon: Icons.mail,
                  initialValue: profileState.email.value,
                  onChanged: profileNotifier.emailChanged,
                  validator: (_) => Email.emailErrorMessage(profileState.email.error),
                ),
                const SizedBox(height: 20),
      
                // Role
                CustomTextFormFiled(
                  label: 'Rol',
                  prefixIcon: Icons.work,
                  initialValue: profileState.role.value,
                  onChanged: profileNotifier.roleChanged,
                  validator: (_) => Role.roleErrorMessage(profileState.role.error),
                ),
                const SizedBox(height: 20),
      
                // Telephone
                CustomTextFormFiled(
                  label: 'Teléfono',
                  prefixIcon: Icons.phone,
                  initialValue: profileState.telephone.value,
                  onChanged: profileNotifier.telephoneChanged,
                  validator: (_) => Telephone.telephoneErrorMessage(profileState.telephone.error),
                ),
                const SizedBox(height: 20),
      
                (!profileState.isLoading)
                    ? SizedBox(
                        width: 160,
                        height: 50,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return const Color(0xFF566D79);
                              }
                              return colors.onPrimaryFixedVariant;
                            }),
                            foregroundColor: WidgetStateProperty.all(Colors.white),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                          onPressed: () async {
                            await profileNotifier.updateUser(context);
                          },
                          child: const Text('Actualizar'),
                        ),
                      )
                    : SizedBox(
                        width: 150,
                        height: 50,
                        child: TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            backgroundColor: colors.onPrimaryFixedVariant,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showImagePickerDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(profileProvider.notifier).selectImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(profileProvider.notifier).selectImage(fromCamera: false);
              },
            ),
          ],
        ),
      );
    },
  );
}
