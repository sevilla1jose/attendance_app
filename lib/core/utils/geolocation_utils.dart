import 'dart:math';
import 'package:attendance_app/core/constants/app_constants.dart';

/// Utilidades para manejar ubicaciones geográficas
class GeolocationUtils {
  /// Radio de la tierra en metros
  static const double earthRadius = 6371000.0;

  /// Calcula la distancia en metros entre dos ubicaciones usando la fórmula de Haversine
  ///
  /// [lat1], [lon1]: Coordenadas del primer punto
  /// [lat2], [lon2]: Coordenadas del segundo punto
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Convertir a radianes
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distancia en metros
    return earthRadius * c;
  }

  /// Convierte grados a radianes
  static double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  /// Verifica si una ubicación está dentro del radio permitido de un local
  static bool isWithinRadius(
      double userLat, double userLon, double locationLat, double locationLon,
      {double? radius}) {
    final distance =
        calculateDistance(userLat, userLon, locationLat, locationLon);

    return distance <= (radius ?? AppConstants.locationValidityRadiusInMeters);
  }

  /// Genera un punto aleatorio dentro de un radio específico
  /// Útil para pruebas y simulaciones
  static Map<String, double> generateRandomPointWithinRadius(
      double centerLat, double centerLon, double radiusInMeters) {
    // Convertir radio a grados (aproximadamente)
    final radiusInDegrees = radiusInMeters / 111000.0;

    // Generar un punto aleatorio dentro del círculo
    final random = Random();
    final u = random.nextDouble();
    final v = random.nextDouble();

    final w = radiusInDegrees * sqrt(u);
    final t = 2 * pi * v;
    final x = w * cos(t);
    final y = w * sin(t);

    // Ajustar la coordenada de longitud por el factor de latitud
    final newLon = x / cos(_toRadians(centerLat)) + centerLon;
    final newLat = y + centerLat;

    return {
      'latitude': newLat,
      'longitude': newLon,
    };
  }

  /// Formatea una coordenada para mostrarla al usuario
  static String formatCoordinate(double coordinate, {bool isLatitude = true}) {
    final direction = isLatitude
        ? (coordinate >= 0 ? 'N' : 'S')
        : (coordinate >= 0 ? 'E' : 'W');

    final absCoordinate = coordinate.abs();
    final degrees = absCoordinate.floor();
    final minutes = ((absCoordinate - degrees) * 60).floor();
    final seconds =
        ((absCoordinate - degrees - minutes / 60) * 3600).toStringAsFixed(2);

    return '$degrees° $minutes\' $seconds" $direction';
  }

  /// Convierte coordenadas de grados decimales a grados, minutos, segundos
  static Map<String, dynamic> decimalToDMS(double coordinate) {
    final absCoordinate = coordinate.abs();
    final degrees = absCoordinate.floor();
    final minutes = ((absCoordinate - degrees) * 60).floor();
    final seconds = ((absCoordinate - degrees - minutes / 60) * 3600);

    return {
      'degrees': degrees,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  /// Convierte coordenadas de grados, minutos, segundos a grados decimales
  static double dmsToDecimal(int degrees, int minutes, double seconds,
      {bool isNegative = false}) {
    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    return isNegative ? -decimal : decimal;
  }

  /// Calcula el centro de un conjunto de coordenadas
  static Map<String, double> calculateCenter(
      List<Map<String, double>> coordinates) {
    if (coordinates.isEmpty) {
      return {'latitude': 0.0, 'longitude': 0.0};
    }

    if (coordinates.length == 1) {
      return coordinates.first;
    }

    double sumLat = 0.0;
    double sumLon = 0.0;

    for (final coordinate in coordinates) {
      sumLat += coordinate['latitude']!;
      sumLon += coordinate['longitude']!;
    }

    return {
      'latitude': sumLat / coordinates.length,
      'longitude': sumLon / coordinates.length,
    };
  }

  /// Calcula los límites (bounds) de un conjunto de coordenadas
  static Map<String, Map<String, double>> calculateBounds(
      List<Map<String, double>> coordinates) {
    if (coordinates.isEmpty) {
      return {
        'southwest': {'latitude': 0.0, 'longitude': 0.0},
        'northeast': {'latitude': 0.0, 'longitude': 0.0},
      };
    }

    double minLat = coordinates.first['latitude']!;
    double maxLat = coordinates.first['latitude']!;
    double minLon = coordinates.first['longitude']!;
    double maxLon = coordinates.first['longitude']!;

    for (final coordinate in coordinates) {
      if (coordinate['latitude']! < minLat) minLat = coordinate['latitude']!;
      if (coordinate['latitude']! > maxLat) maxLat = coordinate['latitude']!;
      if (coordinate['longitude']! < minLon) minLon = coordinate['longitude']!;
      if (coordinate['longitude']! > maxLon) maxLon = coordinate['longitude']!;
    }

    return {
      'southwest': {'latitude': minLat, 'longitude': minLon},
      'northeast': {'latitude': maxLat, 'longitude': maxLon},
    };
  }

  /// Verifica si dos coordenadas son aproximadamente iguales
  static bool areCoordinatesEqual(
      double lat1, double lon1, double lat2, double lon2,
      {double tolerance = 0.0001}) {
    return (lat1 - lat2).abs() < tolerance && (lon1 - lon2).abs() < tolerance;
  }

  /// Calcula el rumbo entre dos puntos en grados (0-360)
  static double calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);

    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);

    var bearing = atan2(y, x);
    bearing = bearing * 180 / pi; // Convertir a grados
    bearing = (bearing + 360) % 360; // Normalizar a 0-360

    return bearing;
  }
}
