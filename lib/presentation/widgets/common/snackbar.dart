import 'package:flutter/material.dart';

/// Clase para mostrar Snackbars personalizados en la aplicación
class AppSnackBar {
  /// Muestra un Snackbar de éxito
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Muestra un Snackbar de error
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Muestra un Snackbar de advertencia
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Muestra un Snackbar informativo
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// Muestra un Snackbar personalizado
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Duration duration,
    SnackBarAction? action,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }
}

/// Extensión para mostrar Snackbars desde el contexto
extension SnackBarExtension on BuildContext {
  /// Muestra un Snackbar de éxito
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AppSnackBar.showSuccess(
      this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un Snackbar de error
  void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    AppSnackBar.showError(
      this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un Snackbar de advertencia
  void showWarningSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    AppSnackBar.showWarning(
      this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un Snackbar informativo
  void showInfoSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AppSnackBar.showInfo(
      this,
      message: message,
      duration: duration,
      action: action,
    );
  }
}
