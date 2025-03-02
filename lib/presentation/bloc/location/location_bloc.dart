import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/usecases/location/add_location.dart';
import 'package:attendance_app/domain/usecases/location/get_locations.dart';
import 'package:attendance_app/domain/usecases/location/update_location.dart';

part 'location_event.dart';
part 'location_state.dart';

/// BLoC para gestionar el estado de ubicaciones
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetLocations getLocations;
  final AddLocation addLocation;
  final UpdateLocation updateLocation;

  LocationBloc({
    required this.getLocations,
    required this.addLocation,
    required this.updateLocation,
  }) : super(LocationInitial()) {
    // Cargar la lista de ubicaciones
    on<LoadLocationsEvent>(_onLoadLocations);

    // Filtrar ubicaciones
    on<FilterLocationsEvent>(_onFilterLocations);

    // Agregar una nueva ubicación
    on<AddLocationEvent>(_onAddLocation);

    // Actualizar una ubicación existente
    on<UpdateLocationEvent>(_onUpdateLocation);
  }

  /// Maneja el evento para cargar ubicaciones
  Future<void> _onLoadLocations(
    LoadLocationsEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await getLocations(Params.all());

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (locations) => emit(LocationsLoaded(locations: locations)),
    );
  }

  /// Maneja el evento para filtrar ubicaciones
  Future<void> _onFilterLocations(
    FilterLocationsEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await getLocations(
      Params(
        isActive: event.isActive,
        searchQuery: event.searchQuery,
      ),
    );

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (locations) => emit(LocationsLoaded(locations: locations)),
    );
  }

  /// Maneja el evento para agregar una ubicación
  Future<void> _onAddLocation(
    AddLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await addLocation(
      Params(
        name: event.name,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
      ),
    );

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (location) async {
        // Recargar la lista de ubicaciones
        final locationsResult = await getLocations(Params.all());

        locationsResult.fold(
          (failure) => emit(LocationError(message: failure.message)),
          (locations) =>
              emit(LocationAdded(location: location, locations: locations)),
        );
      },
    );
  }

  /// Maneja el evento para actualizar una ubicación
  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final result = await updateLocation(
      Params(
        id: event.id,
        name: event.name,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (location) async {
        // Recargar la lista de ubicaciones
        final locationsResult = await getLocations(Params.all());

        locationsResult.fold(
          (failure) => emit(LocationError(message: failure.message)),
          (locations) =>
              emit(LocationUpdated(location: location, locations: locations)),
        );
      },
    );
  }
}
