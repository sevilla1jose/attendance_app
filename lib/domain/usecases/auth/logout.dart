import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// Cierra la sesión del usuario actual
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
