import 'package:dartz/dartz.dart';

import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/core/network/network_info.dart';
import 'package:attendance_app/data/datasources/local/user_local_data_source.dart';
import 'package:attendance_app/data/datasources/remote/user_remote_data_source.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/user_repository.dart';

/// Implementación del repositorio de usuarios
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserById(String id) async {
    try {
      // Intentar obtener el usuario desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final user = await remoteDataSource.getUserById(id);

          // Guardar en la caché local
          await localDataSource.createUser(user);

          return Right(user);
        } on ServerExceptionApp catch (e) {
          // Si falla, intentar obtener desde la fuente local
          return Left(ServerFailure(message: e.message));
        }
      }

      // Obtener desde la fuente local
      final user = await localDataSource.getUserById(id);

      if (user != null) {
        return Right(user);
      } else {
        return Left(NotFoundFailure('Usuario no encontrado'));
      }
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      // Intentar obtener los usuarios desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final users = await remoteDataSource.getAllUsers();

          // Guardar en la caché local
          for (final user in users) {
            await localDataSource.createUser(user);
          }

          return Right(users);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final users = await localDataSource.getAllUsers();
      return Right(users);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // Intentar obtener los usuarios desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final users = await remoteDataSource.getUsers(
            role: role,
            isActive: isActive,
            searchQuery: searchQuery,
          );

          // Guardar en la caché local
          for (final user in users) {
            await localDataSource.createUser(user);
          }

          return Right(users);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final users = await localDataSource.getUsers(
        role: role,
        isActive: isActive,
        searchQuery: searchQuery,
      );

      return Right(users);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? identification,
    String? profilePicture,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final user = await remoteDataSource.createUser(
        name: name,
        email: email,
        passwordIn: password,
        role: role,
        phone: phone,
        identification: identification,
        profilePicture: profilePicture,
      );

      // Guardar en la caché local
      await localDataSource.createUser(user);

      return Right(user);
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateUser({
    required String id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? identification,
    String? profilePicture,
    bool? isActive,
  }) async {
    try {
      UserModel user;

      if (await networkInfo.isConnected) {
        try {
          // Actualizar en el servidor
          user = await remoteDataSource.updateUser(
            id: id,
            name: name,
            email: email,
            role: role,
            phone: phone,
            identification: identification,
            profilePicture: profilePicture,
            isActive: isActive,
          );

          // Actualizar en la caché local
          await localDataSource.updateUser(user);

          return Right(user);
        } on ServerExceptionApp catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      } else {
        // Si no hay conexión, actualizar localmente
        final currentUser = await localDataSource.getUserById(id);

        if (currentUser == null) {
          return Left(NotFoundFailure('Usuario no encontrado'));
        }

        // Actualizar los campos proporcionados
        user = currentUser.copyWith(
          name: name,
          email: email,
          role: role,
          phone: phone,
          identification: identification,
          profilePicture: profilePicture,
          isActive: isActive,
        );

        // Guardar los cambios localmente
        await localDataSource.updateUser(user);

        return Right(user);
      }
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changeUserPassword({
    required String id,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      await remoteDataSource.changeUserPassword(
        id: id,
        newPassword: newPassword,
      );

      return const Right(null);
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          // Eliminar en el servidor
          await remoteDataSource.deleteUser(id);
        } on ServerExceptionApp catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      }

      // Eliminar localmente (incluso si la operación remota falla)
      try {
        await localDataSource.deleteUser(id);
      } on DatabaseExceptionApp catch (e) {
        return Left(DatabaseFailure(e.message));
      }

      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<User>>> searchUsers(String query) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final users = await remoteDataSource.searchUsers(query);

          // Guardar en la caché local
          for (final user in users) {
            await localDataSource.createUser(user);
          }

          return Right(users);
        } catch (e) {
          // Si falla, intentar buscar localmente
        }
      }

      // Buscar localmente
      final users = await localDataSource.searchUsers(query);

      return Right(users);
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> updateProfilePicture({
    required String userId,
    required List<int> imageBytes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final imageUrl = await remoteDataSource.updateProfilePicture(
        userId: userId,
        imageBytes: imageBytes,
      );

      // Actualizar también en la base de datos local
      final user = await localDataSource.getUserById(userId);

      if (user != null) {
        await localDataSource.updateUser(
          user.copyWith(profilePicture: imageUrl),
        );
      }

      return Right(imageUrl);
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> syncUsers() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      // Obtener usuarios pendientes de sincronización
      final pendingUsers = await localDataSource.getPendingSyncUsers();

      // Sincronizar cada usuario
      for (final user in pendingUsers) {
        try {
          await remoteDataSource.updateUser(
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            identification: user.identification,
            profilePicture: user.profilePicture,
            isActive: user.isActive,
          );

          // Marcar como sincronizado
          await localDataSource.markUserAsSynced(user.id);
        } catch (e) {
          // Continuar con el siguiente usuario si este falla
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Error al sincronizar usuarios'));
    }
  }
}
