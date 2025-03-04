import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:attendance_app/core/platform/platform_info.dart';

/// Proporciona widgets adaptados a la plataforma actual
class PlatformWidgetFactory {
  final PlatformInfo platformInfo;

  PlatformWidgetFactory({required this.platformInfo});

  /// Crea un AppBar adaptado a la plataforma
  PreferredSizeWidget createAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool centerTitle = false,
    Color? backgroundColor,
    double elevation = 8.0,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: actions != null && actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              )
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.lightBackgroundGray,
            width: 0.5,
          ),
        ),
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        elevation: elevation,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      );
    }
  }

  /// Crea un botón adaptado a la plataforma
  Widget createButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isDestructive = false,
    IconData? icon,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isDestructive
            ? CupertinoColors.destructiveRed
            : (isPrimary ? CupertinoTheme.of(context).primaryColor : null),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? Colors.red
              : (isPrimary ? Theme.of(context).primaryColor : null),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      );
    }
  }

  /// Crea un campo de texto adaptado a la plataforma
  Widget createTextField({
    required BuildContext context,
    required String placeholder,
    TextEditingController? controller,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    Widget? prefix,
    Widget? suffix,
    bool autofocus = false,
    bool enabled = true,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        prefix: prefix,
        suffix: suffix,
        autofocus: autofocus,
        enabled: enabled,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: errorText != null
                ? CupertinoColors.destructiveRed
                : CupertinoColors.lightBackgroundGray,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    } else {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: placeholder,
          errorText: errorText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        enabled: enabled,
      );
    }
  }

  /// Crea un diálogo adaptado a la plataforma
  Future<T?> showAlertDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
  }

  /// Crea un modal bottom sheet adaptado a la plataforma
  Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [child],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: isDismissible,
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(child: child),
      );
    }
  }

  /// Crea un indicador de carga adaptado a la plataforma
  Widget createLoadingIndicator({Color? color}) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoActivityIndicator(
        color: color,
      );
    } else {
      return CircularProgressIndicator(
        color: color,
      );
    }
  }

  /// Crea un switch adaptado a la plataforma
  Widget createSwitch({
    required BuildContext context,
    required bool value,
    required Function(bool) onChanged,
    Color? activeColor,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }

  /// Crea un selector de fecha adaptado a la plataforma
  Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    if (platformInfo.platform == AppPlatform.iOS) {
      DateTime? selectedDate;
      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoButton(
                        child: const Text('Aceptar'),
                        onPressed: () => Navigator.of(context)
                            .pop(selectedDate ?? initialDate),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      mode: CupertinoDatePickerMode.date,
                      onDateTimeChanged: (DateTime value) {
                        selectedDate = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return showMaterialDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  /// Crea un selector de fecha en Material Design
  Future<DateTime?> showMaterialDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
