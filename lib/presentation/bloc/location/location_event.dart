part of 'location_bloc.dart';

/// Clase base para todos los eventos de ubicaciones
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de ubicaciones
class LoadLocationsEvent extends LocationEvent {}

/// Evento para filtrar la lista de ubicaciones
class FilterLocationsEvent extends LocationEvent {
  final bool? isActive;
  final String? searchQuery;

  const FilterLocationsEvent({
    this.isActive,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [isActive, searchQuery];
}

/// Evento para agregar una nueva ubicación
class AddLocationEvent extends LocationEvent {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? radius;

  const AddLocationEvent({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius,
  });

  @override
  List<Object?> get props => [
        name,
        address,
        latitude,
        longitude,
        radius,
      ];
}

/// Evento para actualizar una ubicación existente
class UpdateLocationEvent extends LocationEvent {
  final String id;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final bool? isActive;

  const UpdateLocationEvent({
    required this.id,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.radius,
    this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        radius,
        isActive,
      ];
}
