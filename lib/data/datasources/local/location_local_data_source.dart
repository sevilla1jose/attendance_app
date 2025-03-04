import 'package:uuid/uuid.dart';

import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/utils/geolocation_utils.dart';
import 'package:attendance_app/data/datasources/local/database_helper.dart';
import 'package:attendance_app/data/models/location_model.dart';

/// Interfaz para el acceso a datos de ubicaciones almacenados localmente
abstract class LocationLocalDataSource {
  /// Obtiene una ubicación por su ID
  Future<LocationModel?> getLocationById(String id);

  /// Obtiene todas las ubicaciones
  Future<List<LocationModel>> getAllLocations();

  /// Obtiene ubicaciones con filtros
  Future<List<LocationModel>> getLocations({
    bool? isActive,
    String? searchQuery,
  });

  /// Crea una nueva ubicación
  Future<LocationModel> createLocation(LocationModel location);

  /// Actualiza una ubicación existente
  Future<LocationModel> updateLocation(LocationModel location);

  /// Elimina una ubicación
  Future<void> deleteLocation(String id);

  /// Busca ubicaciones por nombre o dirección
  Future<List<LocationModel>> searchLocations(String query);

  /// Obtiene las ubicaciones cercanas a unas coordenadas
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double maxDistance = 10000, // 10 km por defecto
  });

  /// Obtiene las ubicaciones pendientes de sincronización
  Future<List<LocationModel>> getPendingSyncLocations();

  /// Marca una ubicación como sincronizada
  Future<void> markLocationAsSynced(String id);
}

/// Implementación de [LocationLocalDataSource] usando SQLite
class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  final DatabaseHelper databaseHelper;
  final GeolocationUtils geolocationUtils;

  LocationLocalDataSourceImpl({
    required this.databaseHelper,
    required this.geolocationUtils,
  });

  @override
  Future<LocationModel?> getLocationById(String id) async {
    try {
      final locationData = await databaseHelper.getById('locations', id);

      if (locationData == null) {
        return null;
      }

      return LocationModel.fromJson(locationData);
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener la ubicación: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LocationModel>> getAllLocations() async {
    try {
      final locationsData = await databaseHelper.getAll('locations');

      return locationsData
          .map((locationData) => LocationModel.fromJson(locationData))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener todas las ubicaciones: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LocationModel>> getLocations({
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // Construir la consulta
      String? where;
      List<dynamic>? whereArgs;

      if (isActive != null || searchQuery != null) {
        final conditions = <String>[];
        whereArgs = <dynamic>[];

        if (isActive != null) {
          conditions.add('is_active = ?');
          whereArgs.add(isActive ? 1 : 0);
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          conditions.add('(name LIKE ? OR address LIKE ?)');
          whereArgs.add('%$searchQuery%');
          whereArgs.add('%$searchQuery%');
        }

        where = conditions.join(' AND ');
      }

      final locationsData = await databaseHelper.query(
        'locations',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      return locationsData
          .map((locationData) => LocationModel.fromJson(locationData))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener ubicaciones filtradas: ${e.toString()}',
      );
    }
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    try {
      // Generar un ID único si no se proporciona
      final locationId = location.id.isEmpty ? const Uuid().v4() : location.id;

      // Preparar el modelo con el ID generado
      final locationToCreate = location.copyWith(
        id: locationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Insertar en la base de datos
      await databaseHelper.insert('locations', locationToCreate.toJson());

      return locationToCreate;
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al crear la ubicación: ${e.toString()}',
      );
    }
  }

  @override
  Future<LocationModel> updateLocation(LocationModel location) async {
    try {
      // Preparar el modelo con la fecha de actualización
      final locationToUpdate = location.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Actualizar en la base de datos
      await databaseHelper.update(
          'locations', locationToUpdate.toJson(), location.id);

      return locationToUpdate;
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al actualizar la ubicación: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    try {
      await databaseHelper.delete('locations', id);
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al eliminar la ubicación: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllLocations();
      }

      final locationsData = await databaseHelper.query(
        'locations',
        where: 'name LIKE ? OR address LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return locationsData
          .map((locationData) => LocationModel.fromJson(locationData))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al buscar ubicaciones: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double maxDistance = 10000,
  }) async {
    try {
      // Obtener todas las ubicaciones
      final allLocations = await getAllLocations();

      // Filtrar y calcular distancias utilizando GeolocationUtils
      final nearbyLocations = allLocations
          .map((location) {
            final distance = GeolocationUtils.calculateDistance(
              latitude,
              longitude,
              location.latitude,
              location.longitude,
            );
            return (location: location, distance: distance);
          })
          .where((item) => item.distance <= maxDistance)
          .toList();

      // Ordenar por cercanía
      nearbyLocations.sort((a, b) => a.distance.compareTo(b.distance));

      // Devolver solo las ubicaciones
      return nearbyLocations.map((item) => item.location).toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener ubicaciones cercanas: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LocationModel>> getPendingSyncLocations() async {
    try {
      final locationsData = await databaseHelper.query(
        'locations',
        where: 'synced = ?',
        whereArgs: [0],
      );

      return locationsData
          .map((locationData) => LocationModel.fromJson(locationData))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener ubicaciones pendientes de sincronización: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markLocationAsSynced(String id) async {
    try {
      await databaseHelper.update(
        'locations',
        {'synced': 1, 'updated_at': DateTime.now().toIso8601String()},
        id,
      );
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al marcar la ubicación como sincronizada: ${e.toString()}',
      );
    }
  }
}
