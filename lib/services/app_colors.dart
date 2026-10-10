import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF151A16) : const Color(0xFFFBF6EC);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF202720) : Colors.white;

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF293229) : const Color(0xFFF5EEDF);

  static Color text(BuildContext context) =>
      isDark(context) ? const Color(0xFFF3F1E8) : const Color(0xFF3A3226);

  static Color muted(BuildContext context) =>
      isDark(context) ? const Color(0xFFB5C0B5) : const Color(0xFF8A7F6B);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF3B483D) : const Color(0xFFE4D9C3);

  static Color greenAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFB8D99A) : const Color(0xFF3B6D11);

  static Color greenSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF263B2A) : const Color(0xFFDCEBCB);

  static Color orangeAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFFFB77F) : const Color(0xFFB95D20);

  static Color orangeSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF442F22) : const Color(0xFFFFE8D6);

  static const Color primaryGreen = Color(0xFF639922);
  static const Color primaryOrange = Color(0xFFE8813A);
}
