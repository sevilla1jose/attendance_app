import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/location.dart';

/// Interfaz que define las operaciones relacionadas con ubicaciones
abstract class LocationRepository {
  /// Obtiene una ubicación por su ID
  Future<Either<Failure, Location>> getLocationById(String id);

  /// Obtiene todas las ubicaciones
  Future<Either<Failure, List<Location>>> getAllLocations();

  /// Obtiene ubicaciones con filtros
  Future<Either<Failure, List<Location>>> getLocations({
    bool? isActive,
    String? searchQuery,
  });

  /// Crea una nueva ubicación
  Future<Either<Failure, Location>> createLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double? radius,
  });

  /// Actualiza una ubicación existente
  Future<Either<Failure, Location>> updateLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  });

  /// Elimina una ubicación
  Future<Either<Failure, void>> deleteLocation(String id);

  /// Busca ubicaciones por nombre o dirección
  Future<Either<Failure, List<Location>>> searchLocations(String query);

  /// Obtiene ubicaciones cercanas a unas coordenadas
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double maxDistance = 10000, // 10 km por defecto
  });

  /// Sincroniza las ubicaciones con el servidor
  Future<Either<Failure, void>> syncLocations();
}
