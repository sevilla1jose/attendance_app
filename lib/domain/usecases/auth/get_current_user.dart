import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';

/// Caso de uso para obtener el usuario actualmente autenticado
class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  /// Ejecuta el caso de uso
  ///
  /// Retorna el usuario actual o null si no hay ninguno autenticado
  Future<Either<Failure, User?>> call() async {
    return await repository.getCurrentUser();
  }
}
