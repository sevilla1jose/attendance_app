import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/repositories/location_repository.dart';

/// Caso de uso para actualizar una ubicación existente
class UpdateLocation {
  final LocationRepository repository;

  UpdateLocation(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para actualizar una ubicación
  ///
  /// Retorna la ubicación actualizada si la operación es exitosa
  Future<Either<Failure, Location>> call(Params params) async {
    return await repository.updateLocation(
      id: params.id,
      name: params.name,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
      isActive: params.isActive,
    );
  }
}

/// Parámetros para el caso de uso UpdateLocation
class Params extends Equatable {
  final String id;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final bool? isActive;

  const Params({
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
