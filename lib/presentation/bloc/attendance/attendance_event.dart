part of 'attendance_bloc.dart';

/// Clase base para todos los eventos de asistencias
abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los registros de asistencia
class LoadAttendanceRecordsEvent extends AttendanceEvent {}

/// Evento para filtrar registros de asistencia
class FilterAttendanceRecordsEvent extends AttendanceEvent {
  final String? userId;
  final String? locationId;
  final AttendanceType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isValid;

  const FilterAttendanceRecordsEvent({
    this.userId,
    this.locationId,
    this.type,
    this.startDate,
    this.endDate,
    this.isValid,
  });

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

/// Evento para verificar la ubicación para registro de asistencia
class CheckLocationEvent extends AttendanceEvent {
  final String locationId;
  final double userLatitude;
  final double userLongitude;

  const CheckLocationEvent({
    required this.locationId,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  List<Object> get props => [
        locationId,
        userLatitude,
        userLongitude,
      ];
}

/// Evento para verificar la identidad mediante reconocimiento facial
class VerifyIdentityEvent extends AttendanceEvent {
  final Uint8List photoBytes;
  final Uint8List referencePhotoBytes;

  const VerifyIdentityEvent({
    required this.photoBytes,
    required this.referencePhotoBytes,
  });

  @override
  List<Object> get props => [
        photoBytes,
        referencePhotoBytes,
      ];
}

/// Evento para crear un nuevo registro de asistencia
class CreateAttendanceEvent extends AttendanceEvent {
  final String userId;
  final String locationId;
  final AttendanceType type;
  final List<int> photoBytes;
  final List<int> signatureBytes;
  final double? latitude;
  final double? longitude;

  const CreateAttendanceEvent({
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

/// Evento para cargar registros de asistencia diarios de un usuario
class LoadUserDailyAttendanceEvent extends AttendanceEvent {
  final String userId;
  final DateTime date;

  const LoadUserDailyAttendanceEvent({
    required this.userId,
    required this.date,
  });

  @override
  List<Object> get props => [userId, date];
}
