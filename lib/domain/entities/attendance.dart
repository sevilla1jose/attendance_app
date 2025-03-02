import 'package:equatable/equatable.dart';

/// Enumera los tipos de registro de asistencia
enum AttendanceType { checkIn, checkOut, lunchOut, lunchIn }

/// Extensión para convertir AttendanceType a String y viceversa
extension AttendanceTypeExtension on AttendanceType {
  String get value {
    switch (this) {
      case AttendanceType.checkIn:
        return 'check_in';
      case AttendanceType.checkOut:
        return 'check_out';
      case AttendanceType.lunchOut:
        return 'lunch_out';
      case AttendanceType.lunchIn:
        return 'lunch_in';
    }
  }

  static AttendanceType fromString(String value) {
    switch (value) {
      case 'check_in':
        return AttendanceType.checkIn;
      case 'check_out':
        return AttendanceType.checkOut;
      case 'lunch_out':
        return AttendanceType.lunchOut;
      case 'lunch_in':
        return AttendanceType.lunchIn;
      default:
        throw ArgumentError('Tipo de asistencia inválido: $value');
    }
  }
}

/// Entidad que representa un registro de asistencia en el sistema
class Attendance extends Equatable {
  /// Identificador único del registro de asistencia
  final String id;

  /// ID del usuario que registra la asistencia
  final String userId;

  /// ID de la ubicación donde se registra la asistencia
  final String locationId;

  /// Tipo de registro de asistencia
  final AttendanceType type;

  /// Ruta de la foto tomada al registrar la asistencia
  final String photoPath;

  /// Ruta de la firma capturada al registrar la asistencia
  final String signaturePath;

  /// Coordenada de latitud donde se registró la asistencia (opcional)
  final double? latitude;

  /// Coordenada de longitud donde se registró la asistencia (opcional)
  final double? longitude;

  /// Indica si el registro de asistencia es válido
  final bool isValid;

  /// Mensaje de validación (en caso de que no sea válido)
  final String? validationMessage;

  /// Fecha y hora de creación del registro
  final DateTime createdAt;

  /// Indica si el registro está sincronizado con el servidor
  final bool isSynced;

  /// Constructor de la entidad Asistencia
  const Attendance({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.type,
    required this.photoPath,
    required this.signaturePath,
    this.latitude,
    this.longitude,
    this.isValid = true,
    this.validationMessage,
    required this.createdAt,
    this.isSynced = false,
  });

  /// Crea una copia del registro de asistencia con algunos campos modificados
  Attendance copyWith({
    String? id,
    String? userId,
    String? locationId,
    AttendanceType? type,
    String? photoPath,
    String? signaturePath,
    double? latitude,
    double? longitude,
    bool? isValid,
    String? validationMessage,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      type: type ?? this.type,
      photoPath: photoPath ?? this.photoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isValid: isValid ?? this.isValid,
      validationMessage: validationMessage ?? this.validationMessage,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Obtiene las coordenadas como un mapa (si están disponibles)
  Map<String, double>? get coordinates {
    if (latitude == null || longitude == null) {
      return null;
    }

    return {
      'latitude': latitude!,
      'longitude': longitude!,
    };
  }

  /// Verifica si es un registro de entrada
  bool get isCheckIn => type == AttendanceType.checkIn;

  /// Verifica si es un registro de salida
  bool get isCheckOut => type == AttendanceType.checkOut;

  /// Verifica si es un registro de salida a almuerzo
  bool get isLunchOut => type == AttendanceType.lunchOut;

  /// Verifica si es un registro de regreso de almuerzo
  bool get isLunchIn => type == AttendanceType.lunchIn;

  @override
  List<Object?> get props => [
        id,
        userId,
        locationId,
        type,
        photoPath,
        signaturePath,
        latitude,
        longitude,
        isValid,
        validationMessage,
        createdAt,
        isSynced,
      ];
}
