import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/user_repository.dart';

/// Caso de uso para obtener usuarios con filtros
class GetUsers {
  final UserRepository repository;

  GetUsers(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros opcionales para filtrar usuarios
  ///
  /// Retorna la lista de usuarios que coinciden con los filtros
  Future<Either<Failure, List<User>>> call(Params params) async {
    return await repository.getUsers(
      role: params.role,
      isActive: params.isActive,
      searchQuery: params.searchQuery,
    );
  }
}

/// Parámetros para el caso de uso GetUsers
class Params extends Equatable {
  final UserRole? role;
  final bool? isActive;
  final String? searchQuery;

  const Params({
    this.role,
    this.isActive,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [role, isActive, searchQuery];
}
