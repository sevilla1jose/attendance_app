import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/domain/entities/user.dart';

/// Interfaz que define las operaciones relacionadas con usuarios
abstract class UserRepository {
  /// Obtiene un usuario por su ID
  Future<Either<Failure, User>> getUserById(String id);

  /// Obtiene todos los usuarios
  Future<Either<Failure, List<User>>> getAllUsers();

  /// Obtiene usuarios con filtros
  Future<Either<Failure, List<User>>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  });

  /// Crea un nuevo usuario
  Future<Either<Failure, User>> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? identification,
    String? profilePicture,
  });

  /// Actualiza un usuario existente
  Future<Either<Failure, User>> updateUser({
    required String id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? identification,
    String? profilePicture,
    bool? isActive,
  });

  /// Cambia la contraseña de un usuario
  Future<Either<Failure, void>> changeUserPassword({
    required String id,
    required String newPassword,
  });

  /// Elimina un usuario
  Future<Either<Failure, void>> deleteUser(String id);

  /// Busca usuarios por nombre o correo
  Future<Either<Failure, List<User>>> searchUsers(String query);

  /// Actualiza la foto de perfil de un usuario
  Future<Either<Failure, String>> updateProfilePicture({
    required String userId,
    required List<int> imageBytes,
  });

  /// Sincroniza los usuarios con el servidor
  Future<Either<Failure, void>> syncUsers();
}
