import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/repositories/attendance_repository.dart';

/// Caso de uso para obtener registros de asistencia con filtros
class GetAttendanceRecords {
  final AttendanceRepository repository;

  GetAttendanceRecords(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros opcionales para filtrar registros de asistencia
  ///
  /// Retorna la lista de registros que coinciden con los filtros
  Future<Either<Failure, List<Attendance>>> call(
      GetAttendanceRecordsParams params) async {
    return await repository.getAttendanceRecords(
      userId: params.userId,
      locationId: params.locationId,
      type: params.type,
      startDate: params.startDate,
      endDate: params.endDate,
      isValid: params.isValid,
    );
  }
}

/// Parámetros para el caso de uso GetAttendanceRecords
class GetAttendanceRecordsParams extends Equatable {
  final String? userId;
  final String? locationId;
  final AttendanceType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isValid;

  const GetAttendanceRecordsParams({
    this.userId,
    this.locationId,
    this.type,
    this.startDate,
    this.endDate,
    this.isValid,
  });

  /// Constructor para obtener registros de un usuario específico para un día
  factory GetAttendanceRecordsParams.forUserAndDay({
    required String userId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return GetAttendanceRecordsParams(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Constructor para obtener todos los registros sin filtros
  factory GetAttendanceRecordsParams.all() =>
      const GetAttendanceRecordsParams();

  @override
  List<Object?> get props => [
        userId,
        locationId,
        type,
        startDate,
        endDate,
        isValid,
      ];
}
