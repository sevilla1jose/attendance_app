import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Enumera las plataformas soportadas
enum AppPlatform { android, iOS, web, windows, macOS, linux, unknown }

/// Abstracción para obtener información sobre la plataforma
abstract class PlatformInfo {
  /// Obtiene la plataforma actual
  AppPlatform get platform;

  /// Verifica si la plataforma es móvil (Android o iOS)
  bool get isMobile;

  /// Verifica si la plataforma es web
  bool get isWeb;

  /// Verifica si la plataforma es desktop (Windows, macOS o Linux)
  bool get isDesktop;

  /// Obtiene información del dispositivo
  Future<Map<String, dynamic>> getDeviceInfo();

  /// Obtiene información de la aplicación
  Future<PackageInfo> getAppInfo();

  /// Obtiene el estado de conectividad actual
  ConnectivityResult get currentConnectivity;

  /// Actualiza el estado de conectividad
  void updateConnectivity(ConnectivityResult result);
}

/// Implementación de [PlatformInfo]
class PlatformInfoImpl implements PlatformInfo {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;

  @override
  AppPlatform get platform {
    if (kIsWeb) {
      return AppPlatform.web;
    }

    if (Platform.isAndroid) {
      return AppPlatform.android;
    }

    if (Platform.isIOS) {
      return AppPlatform.iOS;
    }

    if (Platform.isWindows) {
      return AppPlatform.windows;
    }

    if (Platform.isMacOS) {
      return AppPlatform.macOS;
    }

    if (Platform.isLinux) {
      return AppPlatform.linux;
    }

    return AppPlatform.unknown;
  }

  @override
  bool get isMobile =>
      platform == AppPlatform.android || platform == AppPlatform.iOS;

  @override
  bool get isWeb => platform == AppPlatform.web;

  @override
  bool get isDesktop =>
      platform == AppPlatform.windows ||
      platform == AppPlatform.macOS ||
      platform == AppPlatform.linux;

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return {
          'browserName': webInfo.browserName.name,
          'platform': webInfo.platform,
          'userAgent': webInfo.userAgent,
        };
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return {
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        };
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
        };
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        return {
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        };
      }

      if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfoPlugin.macOsInfo;
        return {
          'computerName': macOsInfo.computerName,
          'hostName': macOsInfo.hostName,
          'arch': macOsInfo.arch,
          'model': macOsInfo.model,
          'kernelVersion': macOsInfo.kernelVersion,
          'osRelease': macOsInfo.osRelease,
        };
      }

      if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        return {
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
          'prettyName': linuxInfo.prettyName,
        };
      }

      return {'platform': 'unknown'};
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<PackageInfo> getAppInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('Error getting app info: $e');
      return PackageInfo(
        appName: 'Attendance App',
        packageName: 'com.example.attendance_app',
        version: '1.0.0',
        buildNumber: '1',
      );
    }
  }

  @override
  ConnectivityResult get currentConnectivity => _currentConnectivity;

  @override
  void updateConnectivity(ConnectivityResult result) {
    _currentConnectivity = result;
  }
}
