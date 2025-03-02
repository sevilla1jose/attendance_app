import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:attendance_app/core/platform/platform_info.dart';

/// Indicador de carga adaptable a la plataforma
class AppLoadingIndicator extends StatelessWidget {
  /// Color del indicador
  final Color? color;

  /// Tamaño del indicador
  final double size;

  /// Texto a mostrar debajo del indicador
  final String? text;

  /// Estilo del texto
  final TextStyle? textStyle;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del indicador de carga
  const AppLoadingIndicator({
    Key? key,
    this.color,
    this.size = 36.0,
    this.text,
    this.textStyle,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = platformInfo.platform == AppPlatform.iOS
        ? CupertinoActivityIndicator(
            radius: size / 2,
            color: color,
          )
        : SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
              strokeWidth: 4.0,
            ),
          );

    if (text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            text!,
            style: textStyle ??
                TextStyle(
                  fontSize: 16,
                  color: color ?? Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Widget para pantalla completa de carga
class FullScreenLoading extends StatelessWidget {
  /// Mensaje a mostrar
  final String? message;

  /// Color de fondo
  final Color backgroundColor;

  /// Color del indicador
  final Color? indicatorColor;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del widget de carga a pantalla completa
  const FullScreenLoading({
    Key? key,
    this.message,
    this.backgroundColor = Colors.white,
    this.indicatorColor,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: AppLoadingIndicator(
          color: indicatorColor,
          text: message,
          platformInfo: platformInfo,
        ),
      ),
    );
  }
}

/// Widget para sobreponerse a un contenido mientras carga
class LoadingOverlay extends StatelessWidget {
  /// Si se debe mostrar el overlay
  final bool isLoading;

  /// Widget hijo a mostrar debajo del overlay
  final Widget child;

  /// Color de fondo del overlay
  final Color barrierColor;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del overlay de carga
  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.barrierColor = Colors.black54,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: barrierColor,
              child: Center(
                child: AppLoadingIndicator(
                  color: Colors.white,
                  platformInfo: platformInfo,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
