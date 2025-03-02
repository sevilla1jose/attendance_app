import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/repositories/location_repository.dart';

/// Caso de uso para agregar una nueva ubicación
class AddLocation {
  final LocationRepository repository;

  AddLocation(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para crear una ubicación
  ///
  /// Retorna la ubicación creada si la operación es exitosa
  Future<Either<Failure, Location>> call(Params params) async {
    return await repository.createLocation(
      name: params.name,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
    );
  }
}

/// Parámetros para el caso de uso AddLocation
class Params extends Equatable {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? radius;

  const Params({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius,
  });

  @override
  List<Object?> get props => [name, address, latitude, longitude, radius];
}
