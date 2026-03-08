import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ViVuTextField extends StatelessWidget {
  const ViVuTextField({
    super.key,
    this.label, // BỎ required ở đây
    required this.hint,
    required this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.onChanged,
  });

  final String? label; // Thêm dấu ? để cho phép giá trị null
  final String hint;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHỈ hiển thị Label và khoảng trống nếu label khác null và không rỗng
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.brownDeep,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppColors.brownDeep,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
