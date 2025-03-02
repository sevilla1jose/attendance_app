import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:attendance_app/core/platform/platform_info.dart';

/// Tipos de SnackBar
enum SnackBarType {
  /// Informativo (azul)
  info,

  /// Éxito (verde)
  success,

  /// Advertencia (naranja)
  warning,

  /// Error (rojo)
  error,
}

/// Clase de utilidad para mostrar SnackBars personalizados
class AppSnackBar {
  /// Muestra un SnackBar personalizado adaptado a la plataforma
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    PlatformInfo? platformInfo,
  }) {
    // Si no se proporciona la plataforma, usar Material por defecto
    final isIOS = platformInfo?.platform == AppPlatform.iOS;

    // Obtener colores según el tipo
    final backgroundColor = _getBackgroundColor(type);
    final iconData = _getIcon(type);

    if (isIOS) {
      _showCupertinoSnackBar(
        context: context,
        message: message,
        backgroundColor: backgroundColor,
        iconData: iconData,
        duration: duration,
        action: action,
      );
    } else {
      _showMaterialSnackBar(
        context: context,
        message: message,
        backgroundColor: backgroundColor,
        iconData: iconData,
        duration: duration,
        action: action,
      );
    }
  }

  /// Muestra un SnackBar de éxito
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    PlatformInfo? platformInfo,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
      platformInfo: platformInfo,
    );
  }

  /// Muestra un SnackBar de error
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    PlatformInfo? platformInfo,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
      platformInfo: platformInfo,
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    PlatformInfo? platformInfo,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
      platformInfo: platformInfo,
    );
  }

  /// Muestra un SnackBar de información
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    PlatformInfo? platformInfo,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      action: action,
      platformInfo: platformInfo,
    );
  }

  /// Obtiene el color de fondo según el tipo
  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return Colors.blue;
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.warning:
        return Colors.orange;
      case SnackBarType.error:
        return Colors.red;
    }
  }

  /// Obtiene el icono según el tipo
  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return Icons.info_outline;
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_outlined;
      case SnackBarType.error:
        return Icons.error_outline;
    }
  }

  /// Muestra un SnackBar de estilo Material
  static void _showMaterialSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData iconData,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(iconData, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Muestra un SnackBar de estilo Cupertino
  static void _showCupertinoSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData iconData,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // Crear un overlay para simular un SnackBar en iOS
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(iconData, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      action.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      action.onPressed();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Mostrar el overlay
    Overlay.of(context).insert(overlay);

    // Eliminar después de la duración especificada
    Future.delayed(duration, () {
      overlay.remove();
    });
  }
}
