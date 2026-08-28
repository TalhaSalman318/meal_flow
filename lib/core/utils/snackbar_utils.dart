import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppSnackbars {
  AppSnackbars._();

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.primary);
  }

  static void _show(BuildContext context, String message, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color == AppColors.error
              ? AppColors.error
              : AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
