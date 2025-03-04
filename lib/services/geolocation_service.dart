import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/utils/geolocation_utils.dart';

/// Interfaz para el servicio de geolocalización
abstract class GeolocationService {
  /// Verifica si los servicios de geolocalización están habilitados
  Future<bool> isLocationServiceEnabled();

  /// Verifica si la aplicación tiene permiso para acceder a la geolocalización
  Future<bool> isLocationPermissionGranted();

  /// Solicita permiso para acceder a la geolocalización
  Future<bool> requestLocationPermission();

  /// Obtiene la ubicación actual del dispositivo
  Future<Position> getCurrentPosition();

  /// Obtiene la dirección a partir de coordenadas
  Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  );

  /// Obtiene las coordenadas a partir de una dirección
  Future<List<Location>> getCoordinatesFromAddress(String address);

  /// Calcula la distancia entre dos ubicaciones
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );

  /// Verifica si una ubicación está dentro del radio permitido
  bool isWithinRadius(
    double userLatitude,
    double userLongitude,
    double locationLatitude,
    double locationLongitude, {
    double? radius,
  });
}

/// Implementación del servicio de geolocalización
class GeolocationServiceImpl implements GeolocationService {
  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error verificando servicios de ubicación: $e');
      throw LocationExceptionApp(
          'Error verificando servicios de ubicación: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error verificando permisos de ubicación: $e');
      throw LocationExceptionApp(
          'Error verificando permisos de ubicación: ${e.toString()}');
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error solicitando permisos de ubicación: $e');
      throw LocationExceptionApp(
          'Error solicitando permisos de ubicación: ${e.toString()}');
    }
  }

  @override
  Future<Position> getCurrentPosition() async {
    try {
      // Verificar si el servicio está habilitado
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationExceptionApp(
            'Los servicios de ubicación están desactivados');
      }

      // Verificar permisos
      final permissionGranted = await isLocationPermissionGranted();
      if (!permissionGranted) {
        final permissionRequested = await requestLocationPermission();
        if (!permissionRequested) {
          throw LocationExceptionApp('Permiso de ubicación denegado');
        }
      }

      // Obtener la posición actual
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit:
            const Duration(seconds: AppConstants.networkTimeoutInSeconds),
      );
    } catch (e) {
      debugPrint('Error obteniendo la posición actual: $e');
      throw LocationExceptionApp(
          'Error obteniendo la posición actual: ${e.toString()}');
    }
  }

  @override
  Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      debugPrint('Error obteniendo dirección desde coordenadas: $e');
      throw LocationExceptionApp('Error obteniendo dirección: ${e.toString()}');
    }
  }

  @override
  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      debugPrint('Error obteniendo coordenadas desde dirección: $e');
      throw LocationExceptionApp(
          'Error obteniendo coordenadas: ${e.toString()}');
    }
  }

  @override
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return GeolocationUtils.calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  @override
  bool isWithinRadius(
    double userLatitude,
    double userLongitude,
    double locationLatitude,
    double locationLongitude, {
    double? radius,
  }) {
    return GeolocationUtils.isWithinRadius(
      userLatitude,
      userLongitude,
      locationLatitude,
      locationLongitude,
      radius: radius,
    );
  }
}
