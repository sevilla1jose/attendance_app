import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/constants/app_constants.dart';

/// Wrapper para el cliente de Supabase que proporciona funcionalidades comunes
abstract class SupabaseClient {
  /// Obtiene el cliente de Supabase
  SupabaseFlutterClient get client;

  /// Inserta datos en una tabla
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data);

  /// Actualiza datos en una tabla
  Future<Map<String, dynamic>> update(String table, Map<String, dynamic> data,
      {required String id});

  /// Elimina datos de una tabla
  Future<void> delete(String table, String id);

  /// Obtiene un registro por ID
  Future<Map<String, dynamic>> getById(String table, String id);

  /// Obtiene registros basados en una consulta
  Future<List<Map<String, dynamic>>> query(
    String table, {
    Map<String, dynamic>? equals,
    String? orderBy,
    bool descending = false,
    int? limit,
    int? offset,
  });

  /// Sube un archivo a un bucket
  Future<String> uploadFile(String bucket, String path, List<int> bytes,
      {String? contentType});

  /// Descarga un archivo desde un bucket
  Future<List<int>> downloadFile(String bucket, String path);

  /// Elimina un archivo de un bucket
  Future<void> deleteFile(String bucket, String path);

  /// Obtiene una URL pública para un archivo
  String getPublicUrl(String bucket, String path);

  /// Suscribe a los cambios de una tabla
  Stream<List<Map<String, dynamic>>> subscribe(String table,
      {String? event, String? filterColumn, dynamic filterValue});
}

/// Implementación de [SupabaseClient]
class SupabaseClientImpl implements SupabaseClient {
  SupabaseClientImpl();

  @override
  SupabaseFlutterClient get client => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> insert(
      String table, Map<String, dynamic> data) async {
    try {
      final response = await client.from(table).insert(data).select().single();

      return response;
    } catch (e) {
      debugPrint('Error inserting data in $table: $e');
      throw ServerException(message: 'Error inserting data: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> update(String table, Map<String, dynamic> data,
      {required String id}) async {
    try {
      final response =
          await client.from(table).update(data).eq('id', id).select().single();

      return response;
    } catch (e) {
      debugPrint('Error updating data in $table: $e');
      throw ServerException(message: 'Error updating data: ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting data from $table: $e');
      throw ServerException(message: 'Error deleting data: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getById(String table, String id) async {
    try {
      final response = await client.from(table).select().eq('id', id).single();

      return response;
    } catch (e) {
      debugPrint('Error getting data from $table: $e');
      throw ServerException(message: 'Error getting data: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    Map<String, dynamic>? equals,
    String? orderBy,
    bool descending = false,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from(table).select();

      // Aplica los filtros si se proporcionan
      if (equals != null) {
        equals.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Aplica ordenamiento si se proporciona
      if (orderBy != null) {
        query = query.order(orderBy, ascending: !descending);
      }

      // Aplica paginación si se proporciona
      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error querying data from $table: $e');
      throw ServerException(message: 'Error querying data: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadFile(String bucket, String path, List<int> bytes,
      {String? contentType}) async {
    try {
      final response = await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      return response;
    } catch (e) {
      debugPrint('Error uploading file to $bucket/$path: $e');
      throw StorageException('Error uploading file: ${e.toString()}');
    }
  }

  @override
  Future<List<int>> downloadFile(String bucket, String path) async {
    try {
      final response = await client.storage.from(bucket).download(path);
      return response;
    } catch (e) {
      debugPrint('Error downloading file from $bucket/$path: $e');
      throw StorageException('Error downloading file: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting file from $bucket/$path: $e');
      throw StorageException('Error deleting file: ${e.toString()}');
    }
  }

  @override
  String getPublicUrl(String bucket, String path) {
    try {
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error getting public URL for $bucket/$path: $e');
      throw StorageException('Error getting public URL: ${e.toString()}');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> subscribe(String table,
      {String? event, String? filterColumn, dynamic filterValue}) {
    try {
      final channel = client.channel('public:$table');

      var filter = PostgrestFilter(channel
          .on(RealtimeListenTypes.postgresChanges, callback: (payload) {}));

      // Configura el filtro para la suscripción
      if (event != null) {
        filter = filter.eq('event', event);
      }

      if (filterColumn != null && filterValue != null) {
        filter = filter.eq('new.$filterColumn', filterValue);
      }

      // Aplica el filtro a la tabla
      filter.eq('table', table);

      // Suscribe al canal
      channel.subscribe();

      // Convierte los eventos en un stream de datos
      return channel.stream.map((event) {
        if (event.payload.containsKey('new')) {
          return [Map<String, dynamic>.from(event.payload['new'])];
        }
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint('Error subscribing to $table: $e');
      throw ServerException(
          message: 'Error subscribing to table: ${e.toString()}');
    }
  }
}
