import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/repositories/location_repository.dart';

/// Caso de uso para obtener ubicaciones con filtros
class GetLocations {
  final LocationRepository repository;

  GetLocations(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros opcionales para filtrar ubicaciones
  ///
  /// Retorna la lista de ubicaciones que coinciden con los filtros
  Future<Either<Failure, List<Location>>> call(
      GetLocationsParams params) async {
    return await repository.getLocations(
      isActive: params.isActive,
      searchQuery: params.searchQuery,
    );
  }
}

/// Parámetros para el caso de uso GetLocations
class GetLocationsParams extends Equatable {
  final bool? isActive;
  final String? searchQuery;

  const GetLocationsParams({
    this.isActive,
    this.searchQuery,
  });

  /// Constructor para obtener todas las ubicaciones sin filtros
  factory GetLocationsParams.all() => const GetLocationsParams();

  @override
  List<Object?> get props => [isActive, searchQuery];
}
