import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/network/supabase_client_app.dart';
import 'package:attendance_app/core/utils/geolocation_utils.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/data/models/location_model.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Interfaz para el acceso a datos de asistencia remotos
abstract class AttendanceRemoteDataSource {
  /// Obtiene un registro de asistencia por su ID
  Future<AttendanceModel> getAttendanceById(String id);

  /// Obtiene todos los registros de asistencia
  Future<List<AttendanceModel>> getAllAttendanceRecords();

  /// Obtiene registros de asistencia con filtros
  Future<List<AttendanceModel>> getAttendanceRecords({
    String? userId,
    String? locationId,
    AttendanceType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isValid,
  });

  /// Crea un nuevo registro de asistencia
  Future<AttendanceModel> createAttendanceRecord({
    required String userId,
    required String locationId,
    required AttendanceType type,
    required List<int> photoBytes,
    required List<int> signatureBytes,
    double? latitude,
    double? longitude,
  });

  /// Actualiza un registro de asistencia existente
  Future<AttendanceModel> updateAttendanceRecord({
    required String id,
    AttendanceType? type,
    List<int>? photoBytes,
    List<int>? signatureBytes,
    double? latitude,
    double? longitude,
    bool? isValid,
    String? validationMessage,
  });

  /// Elimina un registro de asistencia
  Future<void> deleteAttendanceRecord(String id);

  /// Obtiene los registros de asistencia de un usuario en un día específico
  Future<List<AttendanceModel>> getUserAttendanceForDay({
    required String userId,
    required DateTime date,
  });

  /// Obtiene los registros de asistencia de un usuario en un período específico
  Future<List<AttendanceModel>> getUserAttendanceForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Valida la ubicación para un registro de asistencia
  Future<bool> validateAttendanceLocation({
    required String locationId,
    required double userLatitude,
    required double userLongitude,
  });

  /// Valida la identidad del usuario mediante reconocimiento facial
  Future<bool> validateUserIdentity({
    required String userId,
    required List<int> photoBytes,
  });
}

/// Implementación de [AttendanceRemoteDataSource] usando Supabase
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  AttendanceRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<AttendanceModel> getAttendanceById(String id) async {
    try {
      final attendanceData =
          await supabaseClient.getById(AppConstants.attendanceTable, id);

      return AttendanceModel.fromSupabase(attendanceData);
    } catch (e) {
      throw ServerException(
          message:
              'Error al obtener el registro de asistencia: ${e.toString()}');
    }
  }

  @override
  Future<List<AttendanceModel>> getAllAttendanceRecords() async {
    try {
      final attendanceData =
          await supabaseClient.query(AppConstants.attendanceTable);

      return attendanceData
          .map((data) => AttendanceModel.fromSupabase(data))
          .toList();
    } catch (e) {
      throw ServerException(
          message:
              'Error al obtener todos los registros de asistencia: ${e.toString()}');
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendanceRecords({
    String? userId,
    String? locationId,
    AttendanceType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isValid,
  }) async {
    try {
      var query =
          supabaseClient.client.from(AppConstants.attendanceTable).select();

      // Aplicar filtros
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (locationId != null) {
        query = query.eq('location_id', locationId);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      if (isValid != null) {
        query = query.eq('is_valid', isValid);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Ordenar por fecha de creación (más reciente primero)
      query = query.order('created_at', ascending: false);

      final response = await query;

      return (response as List)
          .map((data) => AttendanceModel.fromSupabase(data))
          .toList();
    } catch (e) {
      throw ServerException(
          message:
              'Error al obtener registros de asistencia filtrados: ${e.toString()}');
    }
  }

  @override
  Future<AttendanceModel> createAttendanceRecord({
    required String userId,
    required String locationId,
    required AttendanceType type,
    required List<int> photoBytes,
    required List<int> signatureBytes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Generar un ID único
      final attendanceId = const Uuid().v4();
      final now = DateTime.now();

      // Subir la foto
      final photoFilename = '${userId}_${now.millisecondsSinceEpoch}_photo.jpg';
      final photoPath = '$userId/photos/$photoFilename';

      final photoStoragePath = await supabaseClient.uploadFile(
        AppConstants.attendancePhotosBucket,
        photoPath,
        photoBytes,
        contentType: 'image/jpeg',
      );

      // Subir la firma
      final signatureFilename =
          '${userId}_${now.millisecondsSinceEpoch}_signature.png';
      final signaturePath = '$userId/signatures/$signatureFilename';

      final signatureStoragePath = await supabaseClient.uploadFile(
        AppConstants.signaturesBucket,
        signaturePath,
        signatureBytes,
        contentType: 'image/png',
      );

      // Verificar la ubicación si se proporcionan coordenadas
      bool isValid = true;
      String? validationMessage;

      if (latitude != null && longitude != null) {
        final isLocationValid = await validateAttendanceLocation(
          locationId: locationId,
          userLatitude: latitude,
          userLongitude: longitude,
        );

        if (!isLocationValid) {
          isValid = false;
          validationMessage =
              'La ubicación no es válida para registrar la asistencia.';
        }
      }

      // Crear el registro en la base de datos
      final attendanceData = {
        'id': attendanceId,
        'user_id': userId,
        'location_id': locationId,
        'type': type.value,
        'photo_path': photoStoragePath,
        'signature_path': signatureStoragePath,
        'latitude': latitude,
        'longitude': longitude,
        'is_valid': isValid,
        'validation_message': validationMessage,
        'created_at': now.toIso8601String(),
      };

      final response = await supabaseClient.insert(
          AppConstants.attendanceTable, attendanceData);

      return AttendanceModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message: 'Error al crear el registro de asistencia: ${e.toString()}');
    }
  }

  @override
  Future<AttendanceModel> updateAttendanceRecord({
    required String id,
    AttendanceType? type,
    List<int>? photoBytes,
    List<int>? signatureBytes,
    double? latitude,
    double? longitude,
    bool? isValid,
    String? validationMessage,
  }) async {
    try {
      // Obtener el registro actual
      final currentAttendance = await getAttendanceById(id);

      // Preparar los datos a actualizar
      final updateData = <String, dynamic>{};

      if (type != null) {
        updateData['type'] = type.value;
      }

      // Actualizar la foto si se proporciona
      if (photoBytes != null) {
        final userId = currentAttendance.userId;
        final now = DateTime.now();

        final photoFilename =
            '${userId}_${now.millisecondsSinceEpoch}_photo.jpg';
        final photoPath = '$userId/photos/$photoFilename';

        final photoStoragePath = await supabaseClient.uploadFile(
          AppConstants.attendancePhotosBucket,
          photoPath,
          photoBytes,
          contentType: 'image/jpeg',
        );

        updateData['photo_path'] = photoStoragePath;
      }

      // Actualizar la firma si se proporciona
      if (signatureBytes != null) {
        final userId = currentAttendance.userId;
        final now = DateTime.now();

        final signatureFilename =
            '${userId}_${now.millisecondsSinceEpoch}_signature.png';
        final signaturePath = '$userId/signatures/$signatureFilename';

        final signatureStoragePath = await supabaseClient.uploadFile(
          AppConstants.signaturesBucket,
          signaturePath,
          signatureBytes,
          contentType: 'image/png',
        );

        updateData['signature_path'] = signatureStoragePath;
      }

      // Actualizar las coordenadas si se proporcionan
      if (latitude != null) {
        updateData['latitude'] = latitude;
      }

      if (longitude != null) {
        updateData['longitude'] = longitude;
      }

      // Actualizar la validez del registro si se proporciona
      if (isValid != null) {
        updateData['is_valid'] = isValid;
      }

      if (validationMessage != null) {
        updateData['validation_message'] = validationMessage;
      }

      // Si no hay datos que actualizar, devolver el registro actual
      if (updateData.isEmpty) {
        return currentAttendance;
      }

      // Actualizar en la base de datos
      final response = await supabaseClient.update(
        AppConstants.attendanceTable,
        updateData,
        id: id,
      );

      return AttendanceModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message:
              'Error al actualizar el registro de asistencia: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    try {
      // Obtener el registro para conocer las rutas de los archivos
      final attendance = await getAttendanceById(id);

      // Eliminar la foto y la firma (si existen)
      try {
        await supabaseClient.deleteFile(
          AppConstants.attendancePhotosBucket,
          attendance.photoPath,
        );
      } catch (e) {
        debugPrint('Error al eliminar la foto: ${e.toString()}');
      }

      try {
        await supabaseClient.deleteFile(
          AppConstants.signaturesBucket,
          attendance.signaturePath,
        );
      } catch (e) {
        debugPrint('Error al eliminar la firma: ${e.toString()}');
      }

      // Eliminar el registro de la base de datos
      await supabaseClient.delete(AppConstants.attendanceTable, id);
    } catch (e) {
      throw ServerException(
          message:
              'Error al eliminar el registro de asistencia: ${e.toString()}');
    }
  }

  @override
  Future<List<AttendanceModel>> getUserAttendanceForDay({
    required String userId,
    required DateTime date,
  }) async {
    try {
      // Obtener el inicio y fin del día
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      return getAttendanceRecords(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      throw ServerException(
          message:
              'Error al obtener registros de asistencia diarios: ${e.toString()}');
    }
  }

  @override
  Future<List<AttendanceModel>> getUserAttendanceForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return getAttendanceRecords(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw ServerException(
          message:
              'Error al obtener registros de asistencia del período: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateAttendanceLocation({
    required String locationId,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      // Obtener la ubicación
      final locationData =
          await supabaseClient.getById(AppConstants.locationsTable, locationId);
      final location = LocationModel.fromSupabase(locationData);

      // Verificar si el usuario está dentro del radio permitido
      return GeolocationUtils.isWithinRadius(
        userLatitude,
        userLongitude,
        location.latitude,
        location.longitude,
        radius: location.radius,
      );
    } catch (e) {
      throw ServerException(
          message: 'Error al validar la ubicación: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateUserIdentity({
    required String userId,
    required List<int> photoBytes,
  }) async {
    try {
      // En un entorno de producción, aquí se implementaría la lógica
      // para comparar la foto del usuario con la foto proporcionada
      // utilizando un servicio de reconocimiento facial

      // Para este prototipo, asumimos que siempre es válido
      // (La implementación real debería utilizar un servicio como AWS Rekognition o similar)

      return true;
    } catch (e) {
      throw ServerException(
          message:
              'Error al validar la identidad del usuario: ${e.toString()}');
    }
  }
}
