import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/attendance.dart';

/// Interfaz que define las operaciones relacionadas con registros de asistencia
abstract class AttendanceRepository {
  /// Obtiene un registro de asistencia por su ID
  Future<Either<Failure, Attendance>> getAttendanceById(String id);

  /// Obtiene todos los registros de asistencia
  Future<Either<Failure, List<Attendance>>> getAllAttendanceRecords();

  /// Obtiene registros de asistencia con filtros
  Future<Either<Failure, List<Attendance>>> getAttendanceRecords({
    String? userId,
    String? locationId,
    AttendanceType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isValid,
  });

  /// Crea un nuevo registro de asistencia
  Future<Either<Failure, Attendance>> createAttendanceRecord({
    required String userId,
    required String locationId,
    required AttendanceType type,
    required List<int> photoBytes,
    required List<int> signatureBytes,
    double? latitude,
    double? longitude,
  });

  /// Actualiza un registro de asistencia existente
  Future<Either<Failure, Attendance>> updateAttendanceRecord({
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
  Future<Either<Failure, void>> deleteAttendanceRecord(String id);

  /// Obtiene los registros de asistencia de un usuario en un día específico
  Future<Either<Failure, List<Attendance>>> getUserAttendanceForDay({
    required String userId,
    required DateTime date,
  });

  /// Obtiene los registros de asistencia de un usuario en un período específico
  Future<Either<Failure, List<Attendance>>> getUserAttendanceForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Valida la ubicación para un registro de asistencia
  Future<Either<Failure, bool>> validateAttendanceLocation({
    required String locationId,
    required double userLatitude,
    required double userLongitude,
  });

  /// Valida la identidad del usuario mediante reconocimiento facial
  Future<Either<Failure, bool>> validateUserIdentity({
    required String userId,
    required List<int> photoBytes,
  });

  /// Sincroniza los registros de asistencia con el servidor
  Future<Either<Failure, void>> syncAttendanceRecords();
}
