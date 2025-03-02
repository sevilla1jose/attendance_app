import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/usecases/attendance/create_attendance_record.dart';
import 'package:attendance_app/domain/usecases/attendance/get_attendance_records.dart';
import 'package:attendance_app/domain/usecases/attendance/validate_attendance_location.dart';
import 'package:attendance_app/services/face_recognition_service.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

/// BLoC para gestionar el estado de asistencias
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CreateAttendanceRecord createAttendanceRecord;
  final GetAttendanceRecords getAttendanceRecords;
  final ValidateAttendanceLocation validateAttendanceLocation;
  final FaceRecognitionService faceRecognitionService;

  AttendanceBloc({
    required this.createAttendanceRecord,
    required this.getAttendanceRecords,
    required this.validateAttendanceLocation,
    required this.faceRecognitionService,
  }) : super(AttendanceInitial()) {
    // Cargar los registros de asistencia
    on<LoadAttendanceRecordsEvent>(_onLoadAttendanceRecords);

    // Filtrar registros de asistencia
    on<FilterAttendanceRecordsEvent>(_onFilterAttendanceRecords);

    // Verificar ubicación para registro de asistencia
    on<CheckLocationEvent>(_onCheckLocation);

    // Verificar identidad mediante reconocimiento facial
    on<VerifyIdentityEvent>(_onVerifyIdentity);

    // Crear un nuevo registro de asistencia
    on<CreateAttendanceEvent>(_onCreateAttendance);

    // Cargar registros de asistencia diarios de un usuario
    on<LoadUserDailyAttendanceEvent>(_onLoadUserDailyAttendance);
  }

  /// Maneja el evento para cargar registros de asistencia
  Future<void> _onLoadAttendanceRecords(
    LoadAttendanceRecordsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result =
        await getAttendanceRecords(GetAttendanceRecords.Params.all());

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (records) => emit(AttendanceRecordsLoaded(records: records)),
    );
  }

  /// Maneja el evento para filtrar registros de asistencia
  Future<void> _onFilterAttendanceRecords(
    FilterAttendanceRecordsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await getAttendanceRecords(
      GetAttendanceRecords.Params(
        userId: event.userId,
        locationId: event.locationId,
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        isValid: event.isValid,
      ),
    );

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (records) => emit(AttendanceRecordsLoaded(records: records)),
    );
  }

  /// Maneja el evento para verificar la ubicación
  Future<void> _onCheckLocation(
    CheckLocationEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await validateAttendanceLocation(
      ValidateAttendanceLocation.Params(
        locationId: event.locationId,
        userLatitude: event.userLatitude,
        userLongitude: event.userLongitude,
      ),
    );

    result.fold(
      (failure) => emit(LocationCheckFailed(message: failure.message)),
      (isValid) {
        if (isValid) {
          emit(LocationCheckPassed());
        } else {
          emit(const LocationCheckFailed(
            message:
                'No estás dentro del área permitida para registrar asistencia.',
          ));
        }
      },
    );
  }

  /// Maneja el evento para verificar la identidad
  Future<void> _onVerifyIdentity(
    VerifyIdentityEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      // Obtener la foto del perfil del usuario
      // En una implementación real, se obtendría desde un repositorio

      // Para este ejemplo, asumimos que la verificación es exitosa
      // En una aplicación real, se utilizaría un servicio real de reconocimiento facial
      final isValid = await faceRecognitionService.verifyFaces(
        event.photoBytes,
        event.referencePhotoBytes,
      );

      if (isValid) {
        emit(IdentityVerificationPassed());
      } else {
        emit(const IdentityVerificationFailed(
          message:
              'No se pudo verificar tu identidad. Inténtalo de nuevo con mejor iluminación.',
        ));
      }
    } catch (e) {
      emit(const IdentityVerificationFailed(
        message: 'Error al verificar identidad. Inténtalo de nuevo.',
      ));
    }
  }

  /// Maneja el evento para crear un registro de asistencia
  Future<void> _onCreateAttendance(
    CreateAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await createAttendanceRecord(
      CreateAttendanceRecord.Params(
        userId: event.userId,
        locationId: event.locationId,
        type: event.type,
        photoBytes: event.photoBytes,
        signatureBytes: event.signatureBytes,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (record) => emit(AttendanceRecordCreated(record: record)),
    );
  }

  /// Maneja el evento para cargar registros de asistencia diarios de un usuario
  Future<void> _onLoadUserDailyAttendance(
    LoadUserDailyAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    final result = await getAttendanceRecords(
      GetAttendanceRecords.Params.forUserAndDay(
        userId: event.userId,
        date: event.date,
      ),
    );

    result.fold(
      (failure) => emit(AttendanceError(message: failure.message)),
      (records) => emit(UserDailyAttendanceLoaded(
        userId: event.userId,
        date: event.date,
        records: records,
      )),
    );
  }
}
