import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:attendance_app/core/platform/platform_info.dart';

/// Indicador de carga adaptado a la plataforma
class AppLoadingIndicator extends StatelessWidget {
  /// Color del indicador de carga
  final Color? color;

  /// Tamaño del indicador de carga
  final double size;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Texto que se muestra debajo del indicador (opcional)
  final String? text;

  /// Constructor del indicador de carga
  const AppLoadingIndicator({
    Key? key,
    this.color,
    this.size = 36.0,
    required this.platformInfo,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar diseño específico de plataforma
    final Widget indicator = platformInfo.platform == AppPlatform.iOS
        ? CupertinoActivityIndicator(
            radius: size / 2,
            color: color,
          )
        : SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 4.0,
              color: color ?? Theme.of(context).primaryColor,
            ),
          );

    // Si se proporciona texto, mostrar un diseño con texto
    if (text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16.0),
          Text(
            text!,
            style: TextStyle(
              fontSize: 16.0,
              color: color ?? Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Overlay de carga a pantalla completa
class FullScreenLoading extends StatelessWidget {
  /// Mensaje para mostrar (opcional)
  final String? message;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Color de fondo del overlay
  final Color? backgroundColor;

  /// Color del indicador y texto
  final Color? color;

  /// Constructor del overlay de carga
  const FullScreenLoading({
    Key? key,
    this.message,
    required this.platformInfo,
    this.backgroundColor,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 48.0,
            ),
            child: AppLoadingIndicator(
              platformInfo: platformInfo,
              color: color,
              text: message ?? 'Cargando...',
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget que muestra un indicador de carga mientras se evalúa un futuro
class FutureLoadingBuilder<T> extends StatelessWidget {
  /// Futuro a evaluar
  final Future<T> future;

  /// Constructor para el estado completado
  final Widget Function(BuildContext context, T data) builder;

  /// Widget a mostrar mientras carga
  final Widget? loadingWidget;

  /// Constructor para el estado de error
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del builder de carga
  const FutureLoadingBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              Center(
                child: AppLoadingIndicator(
                  platformInfo: platformInfo,
                ),
              );
        } else if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error);
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
        } else if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        } else {
          return const Center(child: Text('No hay datos disponibles'));
        }
      },
    );
  }
}
