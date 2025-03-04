import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/core/constants/app_constants.dart';

/// Modelo para la entidad Ubicación en la capa de datos
class LocationModel extends Location {
  /// Constructor del modelo
  const LocationModel({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double radius = AppConstants.locationValidityRadiusInMeters,
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isSynced = false,
  }) : super(
          id: id,
          name: name,
          address: address,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isSynced: isSynced,
        );

  /// Crea una copia del modelo con algunos campos modificados
  @override
  LocationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Crea un modelo a partir de un mapa de datos JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? AppConstants.locationValidityRadiusInMeters,
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: json['synced'] == 1,
    );
  }

  /// Convierte el modelo a un mapa de datos JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': isSynced ? 1 : 0,
    };
  }

  /// Crea un modelo a partir de un mapa de datos de Supabase
  factory LocationModel.fromSupabase(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? AppConstants.locationValidityRadiusInMeters,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: true, // Si viene de Supabase, está sincronizado
    );
  }

  /// Convierte el modelo a un mapa de datos para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
