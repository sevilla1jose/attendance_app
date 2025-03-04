import 'package:attendance_app/domain/entities/attendance.dart';

/// Modelo para la entidad Asistencia en la capa de datos
class AttendanceModel extends Attendance {
  /// Constructor del modelo
  const AttendanceModel({
    required String id,
    required String userId,
    required String locationId,
    required AttendanceType type,
    required String photoPath,
    required String signaturePath,
    double? latitude,
    double? longitude,
    bool isValid = true,
    String? validationMessage,
    required DateTime createdAt,
    bool isSynced = false,
  }) : super(
          id: id,
          userId: userId,
          locationId: locationId,
          type: type,
          photoPath: photoPath,
          signaturePath: signaturePath,
          latitude: latitude,
          longitude: longitude,
          isValid: isValid,
          validationMessage: validationMessage,
          createdAt: createdAt,
          isSynced: isSynced,
        );

  /// Crea una copia del modelo con algunos campos modificados
  @override
  AttendanceModel copyWith({
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
    return AttendanceModel(
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

  /// Crea un modelo a partir de un mapa de datos JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      locationId: json['location_id'],
      type: AttendanceTypeExtension.fromString(json['type']),
      photoPath: json['photo_path'],
      signaturePath: json['signature_path'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isValid: json['is_valid'] == 1,
      validationMessage: json['validation_message'],
      createdAt: DateTime.parse(json['created_at']),
      isSynced: json['synced'] == 1,
    );
  }

  /// Convierte el modelo a un mapa de datos JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'location_id': locationId,
      'type': type.value,
      'photo_path': photoPath,
      'signature_path': signaturePath,
      'latitude': latitude,
      'longitude': longitude,
      'is_valid': isValid ? 1 : 0,
      'validation_message': validationMessage,
      'created_at': createdAt.toIso8601String(),
      'synced': isSynced ? 1 : 0,
    };
  }

  /// Crea un modelo a partir de un mapa de datos de Supabase
  factory AttendanceModel.fromSupabase(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      locationId: json['location_id'],
      type: AttendanceTypeExtension.fromString(json['type']),
      photoPath: json['photo_path'],
      signaturePath: json['signature_path'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isValid: json['is_valid'] ?? true,
      validationMessage: json['validation_message'],
      createdAt: DateTime.parse(json['created_at']),
      isSynced: true, // Si viene de Supabase, está sincronizado
    );
  }

  /// Convierte el modelo a un mapa de datos para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'location_id': locationId,
      'type': type.value,
      'photo_path': photoPath,
      'signature_path': signaturePath,
      'latitude': latitude,
      'longitude': longitude,
      'is_valid': isValid,
      'validation_message': validationMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
