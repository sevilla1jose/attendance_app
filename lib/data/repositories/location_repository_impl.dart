import 'package:dartz/dartz.dart';

import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/core/network/network_info.dart';
import 'package:attendance_app/data/datasources/local/location_local_data_source.dart';
import 'package:attendance_app/data/datasources/remote/location_remote_data_source.dart';
import 'package:attendance_app/data/models/location_model.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/repositories/location_repository.dart';

/// Implementación del repositorio de ubicaciones
class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final LocationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Location>> getLocationById(String id) async {
    try {
      // Intentar obtener la ubicación desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final location = await remoteDataSource.getLocationById(id);

          // Guardar en la caché local
          await localDataSource.createLocation(location);

          return Right(location);
        } on ServerExceptionApp catch (e) {
          // Si falla, intentar obtener desde la fuente local
          return Left(ServerFailure(message: e.message));
        }
      }

      // Obtener desde la fuente local
      final location = await localDataSource.getLocationById(id);

      if (location != null) {
        return Right(location);
      } else {
        return Left(NotFoundFailure('Ubicación no encontrada'));
      }
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Location>>> getAllLocations() async {
    try {
      // Intentar obtener las ubicaciones desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final locations = await remoteDataSource.getAllLocations();

          // Guardar en la caché local
          for (final location in locations) {
            await localDataSource.createLocation(location);
          }

          return Right(locations);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final locations = await localDataSource.getAllLocations();
      return Right(locations);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Location>>> getLocations({
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // Intentar obtener las ubicaciones desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final locations = await remoteDataSource.getLocations(
            isActive: isActive,
            searchQuery: searchQuery,
          );

          // Guardar en la caché local
          for (final location in locations) {
            await localDataSource.createLocation(location);
          }

          return Right(locations);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final locations = await localDataSource.getLocations(
        isActive: isActive,
        searchQuery: searchQuery,
      );

      return Right(locations);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Location>> createLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      LocationModel location;

      if (await networkInfo.isConnected) {
        try {
          // Crear en el servidor
          location = await remoteDataSource.createLocation(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          );

          // Guardar en la caché local
          await localDataSource.createLocation(location);
        } on ServerExceptionApp catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      } else {
        // Si no hay conexión, crear localmente
        final now = DateTime.now();

        location = LocationModel(
          id: '', // ID temporal, será generado por la fuente de datos local
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
          radius: radius ?? 100.0, // Radio por defecto
          isActive: true,
          createdAt: now,
          updatedAt: now,
          isSynced: false,
        );

        location = await localDataSource.createLocation(location);
      }

      return Right(location);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Location>> updateLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  }) async {
    try {
      LocationModel location;

      if (await networkInfo.isConnected) {
        try {
          // Actualizar en el servidor
          location = await remoteDataSource.updateLocation(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            isActive: isActive,
          );

          // Actualizar en la caché local
          await localDataSource.updateLocation(location);
        } on ServerExceptionApp catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      } else {
        // Si no hay conexión, actualizar localmente
        final currentLocation = await localDataSource.getLocationById(id);

        if (currentLocation == null) {
          return Left(NotFoundFailure('Ubicación no encontrada'));
        }

        // Actualizar los campos proporcionados
        location = currentLocation.copyWith(
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          isActive: isActive,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        // Guardar los cambios localmente
        location = await localDataSource.updateLocation(location);
      }

      return Right(location);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocation(String id) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          // Eliminar en el servidor
          await remoteDataSource.deleteLocation(id);
        } on ServerExceptionApp catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      }

      // Eliminar localmente (incluso si la operación remota falla)
      try {
        await localDataSource.deleteLocation(id);
      } on DatabaseExceptionApp catch (e) {
        return Left(DatabaseFailure(e.message));
      }

      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Location>>> searchLocations(String query) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final locations = await remoteDataSource.searchLocations(query);

          // Guardar en la caché local
          for (final location in locations) {
            await localDataSource.createLocation(location);
          }

          return Right(locations);
        } catch (e) {
          // Si falla, intentar buscar localmente
        }
      }

      // Buscar localmente
      final locations = await localDataSource.searchLocations(query);

      return Right(locations);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double maxDistance = 10000, // 10 km por defecto
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final locations = await remoteDataSource.getNearbyLocations(
            latitude: latitude,
            longitude: longitude,
            maxDistance: maxDistance,
          );

          return Right(locations);
        } catch (e) {
          // Si falla, intentar buscar localmente
        }
      }

      // Buscar localmente
      final locations = await localDataSource.getNearbyLocations(
        latitude: latitude,
        longitude: longitude,
        maxDistance: maxDistance,
      );

      return Right(locations);
    } on LocationExceptionApp catch (e) {
      return Left(LocationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> syncLocations() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      // Obtener ubicaciones pendientes de sincronización
      final pendingLocations = await localDataSource.getPendingSyncLocations();

      // Sincronizar cada ubicación
      for (final location in pendingLocations) {
        try {
          if (location.id.isEmpty) {
            // Es una nueva ubicación que debe crearse en el servidor
            await remoteDataSource.createLocation(
              name: location.name,
              address: location.address,
              latitude: location.latitude,
              longitude: location.longitude,
              radius: location.radius,
            );
          } else {
            // Es una ubicación existente que debe actualizarse
            await remoteDataSource.updateLocation(
              id: location.id,
              name: location.name,
              address: location.address,
              latitude: location.latitude,
              longitude: location.longitude,
              radius: location.radius,
              isActive: location.isActive,
            );
          }

          // Marcar como sincronizada
          await localDataSource.markLocationAsSynced(location.id);
        } catch (e) {
          // Continuar con la siguiente ubicación si esta falla
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Error al sincronizar ubicaciones'));
    }
  }
}
