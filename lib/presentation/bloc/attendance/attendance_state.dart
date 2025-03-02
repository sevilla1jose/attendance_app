part of 'attendance_bloc.dart';

/// Clase base para todos los estados de asistencias
abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar asistencias
class AttendanceInitial extends AttendanceState {}

/// Estado cuando se está procesando una operación de asistencia
class AttendanceLoading extends AttendanceState {}

/// Estado cuando se han cargado los registros de asistencia
class AttendanceRecordsLoaded extends AttendanceState {
  final List<Attendance> records;

  const AttendanceRecordsLoaded({
    required this.records,
  });

  @override
  List<Object> get props => [records];
}

/// Estado cuando se ha creado un registro de asistencia
class AttendanceRecordCreated extends AttendanceState {
  final Attendance record;

  const AttendanceRecordCreated({
    required this.record,
  });

  @override
  List<Object> get props => [record];
}

/// Estado cuando se han cargado los registros de asistencia diarios de un usuario
class UserDailyAttendanceLoaded extends AttendanceState {
  final String userId;
  final DateTime date;
  final List<Attendance> records;

  const UserDailyAttendanceLoaded({
    required this.userId,
    required this.date,
    required this.records,
  });

  @override
  List<Object> get props => [userId, date, records];
}

/// Estado cuando la verificación de ubicación es exitosa
class LocationCheckPassed extends AttendanceState {}

/// Estado cuando la verificación de ubicación falla
class LocationCheckFailed extends AttendanceState {
  final String message;

  const LocationCheckFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

/// Estado cuando la verificación de identidad es exitosa
class IdentityVerificationPassed extends AttendanceState {}

/// Estado cuando la verificación de identidad falla
class IdentityVerificationFailed extends AttendanceState {
  final String message;

  const IdentityVerificationFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

/// Estado cuando ocurre un error en el proceso de asistencia
class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
