import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:attendance_app/core/errors/exceptions.dart';

/// Wrapper para el cliente de Supabase que proporciona funcionalidades comunes
abstract class SupabaseClientApp {
  /// Obtiene el cliente de Supabase
  SupabaseClient get clientApp;

  /// Inserta datos en una tabla
  Future<Map<String, dynamic>> insertApp(
    String tableApp,
    Map<String, dynamic> dataApp,
  );

  /// Actualiza datos en una tabla
  Future<Map<String, dynamic>> updateApp(
    String tableApp,
    Map<String, dynamic> dataApp, {
    required String idApp,
  });

  /// Elimina datos de una tabla
  Future<void> deleteApp(String tableApp, String idApp);

  /// Obtiene un registro por ID
  Future<Map<String, dynamic>> getByIdApp(String tableApp, String idApp);

  /// Obtiene registros basados en una consulta
  Future<List<Map<String, dynamic>>> queryApp(
    String tableApp, {
    Map<String, dynamic>? equalsApp,
    String? orderByApp,
    bool descendingApp = false,
    int? limitApp,
    int? offsetApp,
  });

  /// Sube un archivo a un bucket
  Future<String> uploadFileApp(
    String bucketApp,
    String pathApp,
    List<int> bytesApp, {
    String? contentTypeApp,
  });

  /// Descarga un archivo desde un bucket
  Future<List<int>> downloadFileApp(String bucketApp, String pathApp);

  /// Elimina un archivo de un bucket
  Future<void> deleteFileApp(String bucketApp, String pathApp);

  /// Obtiene una URL pública para un archivo
  String getPublicUrlApp(String bucketApp, String pathApp);

  /// Suscribe a los cambios de una tabla
  /* Stream<List<Map<String, dynamic>>> subscribeApp(
    String tableApp, {
    String? eventApp,
    String? filterColumnApp,
    dynamic filterValueApp,
  }); */
}

/// Implementación de [SupabaseClientApp]
class SupabaseClientAppImpl implements SupabaseClientApp {
  @override
  SupabaseClient get clientApp => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> insertApp(
    String tableApp,
    Map<String, dynamic> dataApp,
  ) async {
    try {
      final responseApp =
          await clientApp.from(tableApp).insert(dataApp).select().single();

      return responseApp;
    } catch (e) {
      debugPrint('Error inserting data in $tableApp: $e');
      throw ServerExceptionApp(
        message: 'Error inserting data: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateApp(
    String tableApp,
    Map<String, dynamic> dataApp, {
    required String idApp,
  }) async {
    try {
      final responseApp = await clientApp
          .from(tableApp)
          .update(dataApp)
          .eq('id', idApp)
          .select()
          .single();

      return responseApp;
    } catch (e) {
      debugPrint('Error updating data in $tableApp: $e');
      throw ServerExceptionApp(
        message: 'Error updating data: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteApp(String tableApp, String idApp) async {
    try {
      await clientApp.from(tableApp).delete().eq('id', idApp);
    } catch (e) {
      debugPrint('Error deleting data from $tableApp: $e');
      throw ServerExceptionApp(
        message: 'Error deleting data: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getByIdApp(String tableApp, String idApp) async {
    try {
      final responseApp =
          await clientApp.from(tableApp).select().eq('id', idApp).single();

      return responseApp;
    } catch (e) {
      debugPrint('Error getting data from $tableApp: $e');
      throw ServerExceptionApp(
        message: 'Error getting data: ${e.toString()}',
      );
    }
  }

  @override
  Future<String> uploadFileApp(
    String bucketApp,
    String pathApp,
    List<int> bytesApp, {
    String? contentTypeApp,
  }) async {
    try {
      final responseApp = await clientApp.storage.from(bucketApp).uploadBinary(
            pathApp,
            Uint8List.fromList(bytesApp),
            fileOptions: FileOptions(
              contentType: contentTypeApp,
              upsert: true,
            ),
          );

      return responseApp;
    } catch (e) {
      debugPrint('Error uploading file to $bucketApp/$pathApp: $e');
      throw StorageExceptionApp(
        'Error uploading file: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<int>> downloadFileApp(String bucketApp, String pathApp) async {
    try {
      final responseApp =
          await clientApp.storage.from(bucketApp).download(pathApp);
      return responseApp;
    } catch (e) {
      debugPrint('Error downloading file from $bucketApp/$pathApp: $e');
      throw StorageExceptionApp(
        'Error downloading file: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteFileApp(String bucketApp, String pathApp) async {
    try {
      await clientApp.storage.from(bucketApp).remove([pathApp]);
    } catch (e) {
      debugPrint('Error deleting file from $bucketApp/$pathApp: $e');
      throw StorageExceptionApp(
        'Error deleting file: ${e.toString()}',
      );
    }
  }

  @override
  String getPublicUrlApp(String bucketApp, String pathApp) {
    try {
      return clientApp.storage.from(bucketApp).getPublicUrl(pathApp);
    } catch (e) {
      debugPrint('Error getting public URL for $bucketApp/$pathApp: $e');
      throw StorageExceptionApp(
        'Error getting public URL: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryApp(
    String tableApp, {
    Map<String, dynamic>? equalsApp,
    String? orderByApp,
    bool descendingApp = false,
    int? limitApp,
    int? offsetApp,
  }) async {
    try {
      var queryApp = clientApp.from(tableApp).select();

      // Aplicar filtros de igualdad
      if (equalsApp != null) {
        equalsApp.forEach((keyApp, valueApp) {
          queryApp = queryApp.eq(keyApp, valueApp);
        });
      }

      final responseApp = await queryApp;
      return List<Map<String, dynamic>>.from(responseApp);
    } catch (e) {
      debugPrint('Error querying data from $tableApp: $e');
      throw ServerExceptionApp(
        message: 'Error querying data: ${e.toString()}',
      );
    }
  }
}
