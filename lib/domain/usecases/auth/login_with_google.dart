import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión con Google
class LoginWithGoogle {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// Retorna el usuario autenticado si el inicio de sesión es exitoso
  Future<Either<Failure, User>> call() async {
    return await repository.loginWithGoogle();
  }
}
