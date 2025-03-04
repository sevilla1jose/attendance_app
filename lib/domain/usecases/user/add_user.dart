import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/user_repository.dart';

/// Caso de uso para agregar un nuevo usuario
class AddUser {
  final UserRepository repository;

  AddUser(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para crear un usuario
  ///
  /// Retorna el usuario creado si la operación es exitosa
  Future<Either<Failure, User>> call(AddUserParams params) async {
    return await repository.createUser(
      name: params.name,
      email: params.email,
      password: params.password,
      role: params.role,
      phone: params.phone,
      identification: params.identification,
      profilePicture: params.profilePicture,
    );
  }
}

/// Parámetros para el caso de uso AddUser
class AddUserParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? phone;
  final String? identification;
  final String? profilePicture;

  const AddUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.identification,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        role,
        phone,
        identification,
        profilePicture,
      ];
}
