import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/user_repository.dart';

/// Caso de uso para actualizar un usuario existente
class UpdateUser {
  final UserRepository repository;

  UpdateUser(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para actualizar un usuario
  ///
  /// Retorna el usuario actualizado si la operación es exitosa
  Future<Either<Failure, User>> call(Params params) async {
    return await repository.updateUser(
      id: params.id,
      name: params.name,
      email: params.email,
      role: params.role,
      phone: params.phone,
      identification: params.identification,
      profilePicture: params.profilePicture,
      isActive: params.isActive,
    );
  }
}

/// Parámetros para el caso de uso UpdateUser
class Params extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final UserRole? role;
  final String? phone;
  final String? identification;
  final String? profilePicture;
  final bool? isActive;

  const Params({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.phone,
    this.identification,
    this.profilePicture,
    this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        phone,
        identification,
        profilePicture,
        isActive,
      ];
}
