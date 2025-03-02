part of 'location_bloc.dart';

/// Clase base para todos los estados de ubicaciones
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar ubicaciones
class LocationInitial extends LocationState {}

/// Estado cuando se está procesando una operación de ubicaciones
class LocationLoading extends LocationState {}

/// Estado cuando se han cargado las ubicaciones
class LocationsLoaded extends LocationState {
  final List<Location> locations;

  const LocationsLoaded({
    required this.locations,
  });

  @override
  List<Object> get props => [locations];
}

/// Estado cuando se ha agregado una ubicación
class LocationAdded extends LocationsLoaded {
  final Location location;

  const LocationAdded({
    required this.location,
    required List<Location> locations,
  }) : super(locations: locations);

  @override
  List<Object> get props => [location, locations];
}

/// Estado cuando se ha actualizado una ubicación
class LocationUpdated extends LocationsLoaded {
  final Location location;

  const LocationUpdated({
    required this.location,
    required List<Location> locations,
  }) : super(locations: locations);

  @override
  List<Object> get props => [location, locations];
}

/// Estado cuando ocurre un error en el proceso de ubicaciones
class LocationError extends LocationState {
  final String message;

  const LocationError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
