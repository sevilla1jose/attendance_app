import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión con correo electrónico y contraseña
class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// [params] - Parámetros necesarios para iniciar sesión
  ///
  /// Retorna el usuario autenticado si el inicio de sesión es exitoso
  Future<Either<Failure, User>> call(Params params) async {
    return await repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

/// Parámetros para el caso de uso LoginWithEmail
class Params extends Equatable {
  final String email;
  final String password;

  const Params({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
