import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/network/supabase_client_app.dart';
import 'package:attendance_app/core/utils/geolocation_utils.dart';
import 'package:attendance_app/data/models/location_model.dart';
import 'package:uuid/uuid.dart';

/// Interfaz para el acceso a datos de ubicaciones remotos
abstract class LocationRemoteDataSource {
  /// Obtiene una ubicación por su ID
  Future<LocationModel> getLocationById(String id);

  /// Obtiene todas las ubicaciones
  Future<List<LocationModel>> getAllLocations();

  /// Obtiene ubicaciones con filtros
  Future<List<LocationModel>> getLocations({
    bool? isActive,
    String? searchQuery,
  });

  /// Crea una nueva ubicación
  Future<LocationModel> createLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double? radius,
  });

  /// Actualiza una ubicación existente
  Future<LocationModel> updateLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  });

  /// Elimina una ubicación
  Future<void> deleteLocation(String id);

  /// Busca ubicaciones por nombre o dirección
  Future<List<LocationModel>> searchLocations(String query);

  /// Obtiene ubicaciones cercanas a unas coordenadas
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double maxDistance = 10000, // 10 km por defecto
  });
}

/// Implementación de [LocationRemoteDataSource] usando Supabase
class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final SupabaseClient supabaseClient;

  LocationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<LocationModel> getLocationById(String id) async {
    try {
      final locationData =
          await supabaseClient.getById(AppConstants.locationsTable, id);

      return LocationModel.fromSupabase(locationData);
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener la ubicación: ${e.toString()}');
    }
  }

  @override
  Future<List<LocationModel>> getAllLocations() async {
    try {
      final locationsData =
          await supabaseClient.query(AppConstants.locationsTable);

      return locationsData
          .map((locationData) => LocationModel.fromSupabase(locationData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener todas las ubicaciones: ${e.toString()}');
    }
  }

  @override
  Future<List<LocationModel>> getLocations({
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      Map<String, dynamic>? equals;

      // Construir filtros
      if (isActive != null) {
        equals = {'is_active': isActive};
      }

      var query =
          supabaseClient.client.from(AppConstants.locationsTable).select();

      // Aplicar filtros de igualdad
      if (equals != null) {
        equals.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Aplicar filtro de búsqueda
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query =
            query.or('name.ilike.%$searchQuery%,address.ilike.%$searchQuery%');
      }

      // Ordenar por nombre
      query = query.order('name', ascending: true);

      final response = await query;

      return (response as List)
          .map((locationData) => LocationModel.fromSupabase(locationData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener ubicaciones filtradas: ${e.toString()}');
    }
  }

  @override
  Future<LocationModel> createLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      // Generar un ID único
      final locationId = const Uuid().v4();

      // Crear la ubicación en la base de datos
      final now = DateTime.now();

      final locationData = {
        'id': locationId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius ?? AppConstants.locationValidityRadiusInMeters,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await supabaseClient.insert(
          AppConstants.locationsTable, locationData);

      return LocationModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message: 'Error al crear la ubicación: ${e.toString()}');
    }
  }

  @override
  Future<LocationModel> updateLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  }) async {
    try {
      // Preparar los datos a actualizar
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (radius != null) updateData['radius'] = radius;
      if (isActive != null) updateData['is_active'] = isActive;

      // Actualizar en la base de datos
      final response = await supabaseClient.update(
        AppConstants.locationsTable,
        updateData,
        id: id,
      );

      return LocationModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message: 'Error al actualizar la ubicación: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    try {
      // Eliminar la ubicación de la base de datos
      await supabaseClient.delete(AppConstants.locationsTable, id);
    } catch (e) {
      throw ServerException(
          message: 'Error al eliminar la ubicación: ${e.toString()}');
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllLocations();
      }

      final response = await supabaseClient.client
          .from(AppConstants.locationsTable)
          .select()
          .or('name.ilike.%$query%,address.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List)
          .map((locationData) => LocationModel.fromSupabase(locationData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al buscar ubicaciones: ${e.toString()}');
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
      // Nota: En un entorno de producción, sería recomendable
      // implementar una extensión de PostGIS en Supabase para
      // realizar esta operación de manera más eficiente en el servidor

      final allLocations = await getAllLocations();

      // Filtrar por distancia
      final nearbyLocations = allLocations.where((location) {
        final distance = GeolocationUtils.calculateDistance(
          latitude,
          longitude,
          location.latitude,
          location.longitude,
        );

        return distance <= maxDistance;
      }).toList();

      // Ordenar por cercanía
      nearbyLocations.sort((a, b) {
        final distanceA = GeolocationUtils.calculateDistance(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );

        final distanceB = GeolocationUtils.calculateDistance(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );

        return distanceA.compareTo(distanceB);
      });

      return nearbyLocations;
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener ubicaciones cercanas: ${e.toString()}');
    }
  }
}
