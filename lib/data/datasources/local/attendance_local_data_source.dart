import 'package:uuid/uuid.dart';

import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/data/datasources/local/database_helper.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/domain/entities/attendance.dart';

/// Interfaz para el acceso a datos de asistencia almacenados localmente
abstract class AttendanceLocalDataSource {
  /// Obtiene un registro de asistencia por su ID
  Future<AttendanceModel?> getAttendanceById(String id);

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
  Future<AttendanceModel> createAttendanceRecord(AttendanceModel attendance);

  /// Actualiza un registro de asistencia existente
  Future<AttendanceModel> updateAttendanceRecord(AttendanceModel attendance);

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

  /// Obtiene los registros de asistencia pendientes de sincronización
  Future<List<AttendanceModel>> getPendingSyncAttendanceRecords();

  /// Marca un registro de asistencia como sincronizado
  Future<void> markAttendanceAsSynced(String id);
}

/// Implementación de [AttendanceLocalDataSource] usando SQLite
class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final DatabaseHelper databaseHelper;

  AttendanceLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<AttendanceModel?> getAttendanceById(String id) async {
    try {
      final attendanceData = await databaseHelper.getById(
        'attendance_records',
        id,
      );

      if (attendanceData == null) {
        return null;
      }

      return AttendanceModel.fromJson(attendanceData);
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener el registro de asistencia: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getAllAttendanceRecords() async {
    try {
      final attendanceData = await databaseHelper.getAll('attendance_records');

      return attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener todos los registros de asistencia: ${e.toString()}',
      );
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
      // Construir la consulta
      final conditions = <String>[];
      final whereArgs = <dynamic>[];

      if (userId != null) {
        conditions.add('user_id = ?');
        whereArgs.add(userId);
      }

      if (locationId != null) {
        conditions.add('location_id = ?');
        whereArgs.add(locationId);
      }

      if (type != null) {
        conditions.add('type = ?');
        whereArgs.add(type.value);
      }

      if (startDate != null) {
        conditions.add('created_at >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        conditions.add('created_at <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (isValid != null) {
        conditions.add('is_valid = ?');
        whereArgs.add(isValid ? 1 : 0);
      }

      String? where;
      if (conditions.isNotEmpty) {
        where = conditions.join(' AND ');
      }

      final attendanceData = await databaseHelper.query(
        'attendance_records',
        where: where,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      return attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener registros de asistencia filtrados: ${e.toString()}',
      );
    }
  }

  @override
  Future<AttendanceModel> createAttendanceRecord(
      AttendanceModel attendance) async {
    try {
      // Generar un ID único si no se proporciona
      final attendanceId =
          attendance.id.isEmpty ? const Uuid().v4() : attendance.id;

      // Preparar el modelo con el ID generado
      final attendanceToCreate = attendance.copyWith(
        id: attendanceId,
        createdAt: attendance.createdAt,
        isSynced: false,
      );

      // Insertar en la base de datos
      await databaseHelper.insert(
        'attendance_records',
        attendanceToCreate.toJson(),
      );

      return attendanceToCreate;
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al crear el registro de asistencia: ${e.toString()}',
      );
    }
  }

  @override
  Future<AttendanceModel> updateAttendanceRecord(
    AttendanceModel attendance,
  ) async {
    try {
      // Preparar el modelo para la actualización
      final attendanceToUpdate = attendance.copyWith(
        isSynced: false,
      );

      // Actualizar en la base de datos
      await databaseHelper.update(
          'attendance_records', attendanceToUpdate.toJson(), attendance.id);

      return attendanceToUpdate;
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al actualizar el registro de asistencia: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    try {
      await databaseHelper.delete('attendance_records', id);
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al eliminar el registro de asistencia: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getUserAttendanceForDay({
    required String userId,
    required DateTime date,
  }) async {
    try {
      // Obtener el inicio y fin del día
      final startOfDay = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      // Construir la consulta
      final attendanceData = await databaseHelper.query(
        'attendance_records',
        where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
        whereArgs: [
          userId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        orderBy: 'created_at ASC',
      );

      return attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener registros de asistencia diarios: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getUserAttendanceForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Construir la consulta
      final attendanceData = await databaseHelper.query(
        'attendance_records',
        where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
        whereArgs: [
          userId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'created_at ASC',
      );

      return attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener registros de asistencia del período: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getPendingSyncAttendanceRecords() async {
    try {
      final attendanceData = await databaseHelper.query(
        'attendance_records',
        where: 'synced = ?',
        whereArgs: [0],
      );

      return attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al obtener registros de asistencia pendientes de sincronización: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markAttendanceAsSynced(String id) async {
    try {
      await databaseHelper.update(
        'attendance_records',
        {'synced': 1},
        id,
      );
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al marcar el registro de asistencia como sincronizado: ${e.toString()}',
      );
    }
  }
}
