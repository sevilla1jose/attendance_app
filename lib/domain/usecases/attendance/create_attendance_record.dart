import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/repositories/attendance_repository.dart';

/// Caso de uso para crear un nuevo registro de asistencia
class CreateAttendanceRecord {
  final AttendanceRepository repository;

  CreateAttendanceRecord(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para crear un registro de asistencia
  ///
  /// Retorna el registro creado si la operación es exitosa
  Future<Either<Failure, Attendance>> call(
      CreateAttendanceRecordParams params) async {
    return await repository.createAttendanceRecord(
      userId: params.userId,
      locationId: params.locationId,
      type: params.type,
      photoBytes: params.photoBytes,
      signatureBytes: params.signatureBytes,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

/// Parámetros para el caso de uso CreateAttendanceRecord
class CreateAttendanceRecordParams extends Equatable {
  final String userId;
  final String locationId;
  final AttendanceType type;
  final List<int> photoBytes;
  final List<int> signatureBytes;
  final double? latitude;
  final double? longitude;

  const CreateAttendanceRecordParams({
    required this.userId,
    required this.locationId,
    required this.type,
    required this.photoBytes,
    required this.signatureBytes,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        userId,
        locationId,
        type,
        photoBytes,
        signatureBytes,
        latitude,
        longitude,
      ];
}
