import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/repositories/attendance_repository.dart';

/// Caso de uso para validar que un registro de asistencia se realiza dentro
/// del radio permitido de una ubicación
class ValidateAttendanceLocation {
  final AttendanceRepository repository;

  ValidateAttendanceLocation(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para validar la ubicación
  ///
  /// Retorna true si la ubicación es válida, false en caso contrario
  Future<Either<Failure, bool>> call(Params params) async {
    return await repository.validateAttendanceLocation(
      locationId: params.locationId,
      userLatitude: params.userLatitude,
      userLongitude: params.userLongitude,
    );
  }
}

/// Parámetros para el caso de uso ValidateAttendanceLocation
class Params extends Equatable {
  final String locationId;
  final double userLatitude;
  final double userLongitude;

  const Params({
    required this.locationId,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  List<Object> get props => [locationId, userLatitude, userLongitude];
}
