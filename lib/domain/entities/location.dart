import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/constants/app_constants.dart';

/// Entidad que representa una ubicación (local) en el sistema
class Location extends Equatable {
  /// Identificador único de la ubicación
  final String id;

  /// Nombre del local
  final String name;

  /// Dirección completa del local
  final String address;

  /// Coordenada de latitud
  final double latitude;

  /// Coordenada de longitud
  final double longitude;

  /// Radio en metros para considerar válida la asistencia
  final double radius;

  /// Indica si la ubicación está activa
  final bool isActive;

  /// Fecha de creación de la ubicación
  final DateTime createdAt;

  /// Fecha de última actualización de la ubicación
  final DateTime updatedAt;

  /// Indica si la ubicación está sincronizada con el servidor
  final bool isSynced;

  /// Constructor de la entidad Ubicación
  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius = AppConstants.locationValidityRadiusInMeters,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// Crea una copia de la ubicación con algunos campos modificados
  Location copyWith({
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
    return Location(
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

  /// Obtiene las coordenadas como un mapa
  Map<String, double> get coordinates => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        radius,
        isActive,
        createdAt,
        updatedAt,
        isSynced,
      ];
}
