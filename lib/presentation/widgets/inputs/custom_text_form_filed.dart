import 'package:flutter/material.dart';

class CustomTextFormFiled extends StatelessWidget {
  final IconData? prefixIcon;
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool? obscureText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? initialValue; // 🔥 Agregamos el parámetro

  const CustomTextFormFiled({
    super.key, 
    this.label, 
    this.hint, 
    this.errorMessage, 
    this.onChanged, 
    this.validator, 
    this.prefixIcon, 
    this.obscureText,
    this.initialValue, // ✅ Agregamos el nuevo parámetro
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return TextFormField(
      initialValue: initialValue, // ✅ Ahora soporta valores iniciales
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        enabledBorder: border.copyWith(borderSide: BorderSide(color: colors.primary)),
        focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary)),
        label: label != null 
          ? Text(label!, style: TextStyle(color: colors.primary)) 
          : null,
        focusColor: colors.primary,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colors.primary) : null,
        hintText: hint,
        errorText: errorMessage,
        errorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true, // Un poco más pequeño el input en general
      ),
    );
  }
}
