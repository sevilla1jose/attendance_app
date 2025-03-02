import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';

/// Interfaz que define las operaciones relacionadas con la autenticación
abstract class AuthRepository {
  /// Obtiene el usuario actualmente autenticado
  Future<Either<Failure, User?>> getCurrentUser();

  /// Inicia sesión con correo electrónico y contraseña
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con Google
  Future<Either<Failure, User>> loginWithGoogle();

  /// Cierra la sesión del usuario actual
  Future<Either<Failure, void>> logout();

  /// Verifica si hay un usuario autenticado
  Future<Either<Failure, bool>> isLoggedIn();

  /// Obtiene el token de autenticación actual
  Future<Either<Failure, String?>> getAuthToken();

  /// Restablece la contraseña de un usuario
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Cambia la contraseña del usuario actual
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Actualiza los datos del usuario actual
  Future<Either<Failure, User>> updateCurrentUser({
    String? name,
    String? phone,
    String? profilePicture,
  });
}
