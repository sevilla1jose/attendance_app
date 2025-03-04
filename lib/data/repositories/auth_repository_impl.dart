import 'package:dartz/dartz.dart';

import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/core/network/network_info.dart';
import 'package:attendance_app/data/datasources/local/auth_local_data_source.dart';
import 'package:attendance_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Intentar obtener el usuario desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final remoteUser = await remoteDataSource.getCurrentUser();

          if (remoteUser != null) {
            // Guardar en la caché local
            await localDataSource.saveCurrentUser(remoteUser);
            return Right(remoteUser);
          }
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final localUser = await localDataSource.getCurrentUser();
      return Right(localUser);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final auth = await remoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );

      // Guardar en la caché local
      await localDataSource.saveAuth(auth);
      await localDataSource.saveCurrentUser(auth.user);

      return Right(auth.user);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final auth = await remoteDataSource.loginWithGoogle();

      // Guardar en la caché local
      await localDataSource.saveAuth(auth);
      await localDataSource.saveCurrentUser(auth.user);

      return Right(auth.user);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Intentar cerrar sesión remotamente si hay conexión
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
          // Si falla, solo continuar con el cierre de sesión local
        }
      }

      // Limpiar datos locales
      await localDataSource.clearAuth();

      return const Right(null);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on DatabaseExceptionApp catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await localDataSource.getToken();
      return Right(token != null);
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String?>> getAuthToken() async {
    try {
      final token = await localDataSource.getToken();
      return Right(token);
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateCurrentUser({
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final updatedUser = await remoteDataSource.updateUserProfile(
        name: name,
        phone: phone,
        profilePicture: profilePicture,
      );

      // Actualizar la caché local
      await localDataSource.saveCurrentUser(updatedUser);

      return Right(updatedUser);
    } on AuthExceptionApp catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
}
