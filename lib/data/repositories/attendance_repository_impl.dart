import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/errors/failures.dart';
import 'package:attendance_app/core/network/network_info.dart';
import 'package:attendance_app/data/datasources/local/attendance_local_data_source.dart';
import 'package:attendance_app/data/datasources/remote/attendance_remote_data_source.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/repositories/attendance_repository.dart';

/// Implementación del repositorio de registros de asistencia
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final AttendanceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Attendance>> getAttendanceById(String id) async {
    try {
      // Intentar obtener el registro desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final attendance = await remoteDataSource.getAttendanceById(id);

          // Guardar en la caché local
          await localDataSource.createAttendanceRecord(attendance);

          return Right(attendance);
        } on ServerException catch (e) {
          // Si falla, intentar obtener desde la fuente local
          return Left(ServerFailure(message: e.message));
        }
      }

      // Obtener desde la fuente local
      final attendance = await localDataSource.getAttendanceById(id);

      if (attendance != null) {
        return Right(attendance);
      } else {
        return Left(NotFoundFailure('Registro de asistencia no encontrado'));
      }
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAllAttendanceRecords() async {
    try {
      // Intentar obtener los registros desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final records = await remoteDataSource.getAllAttendanceRecords();

          // Guardar en la caché local
          for (final record in records) {
            await localDataSource.createAttendanceRecord(record);
          }

          return Right(records);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final records = await localDataSource.getAllAttendanceRecords();
      return Right(records);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendanceRecords({
    String? userId,
    String? locationId,
    AttendanceType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isValid,
  }) async {
    try {
      // Intentar obtener los registros desde la fuente remota si hay conexión
      if (await networkInfo.isConnected) {
        try {
          final records = await remoteDataSource.getAttendanceRecords(
            userId: userId,
            locationId: locationId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            isValid: isValid,
          );

          // Guardar en la caché local
          for (final record in records) {
            await localDataSource.createAttendanceRecord(record);
          }

          return Right(records);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final records = await localDataSource.getAttendanceRecords(
        userId: userId,
        locationId: locationId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        isValid: isValid,
      );

      return Right(records);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Attendance>> createAttendanceRecord({
    required String userId,
    required String locationId,
    required AttendanceType type,
    required List<int> photoBytes,
    required List<int> signatureBytes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Validar la ubicación si se proporcionan coordenadas
      if (latitude != null && longitude != null) {
        final isLocationValid = await validateAttendanceLocation(
          locationId: locationId,
          userLatitude: latitude,
          userLongitude: longitude,
        );

        if (isLocationValid.isLeft()) {
          return Left(LocationFailure('No se pudo validar la ubicación'));
        }

        if (!(isLocationValid.getOrElse(() => false))) {
          return Left(ValidationFailure(
              'La ubicación no es válida para registrar la asistencia'));
        }
      }

      // Validar la identidad del usuario con la foto
      if (await networkInfo.isConnected) {
        try {
          final isIdentityValid = await remoteDataSource.validateUserIdentity(
            userId: userId,
            photoBytes: photoBytes,
          );

          if (!isIdentityValid) {
            return Left(FaceRecognitionFailure(
                'No se pudo validar la identidad del usuario'));
          }
        } catch (e) {
          // Si falla la validación, continuar pero marcar como no válido
          // En un entorno de producción, la política podría ser más estricta
        }
      }

      AttendanceModel attendance;

      if (await networkInfo.isConnected) {
        try {
          // Crear en el servidor
          attendance = await remoteDataSource.createAttendanceRecord(
            userId: userId,
            locationId: locationId,
            type: type,
            photoBytes: photoBytes,
            signatureBytes: signatureBytes,
            latitude: latitude,
            longitude: longitude,
          );

          // Guardar en la caché local
          await localDataSource.createAttendanceRecord(attendance);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      } else {
        // Si no hay conexión, crear localmente
        final now = DateTime.now();

        // Generar nombres de archivo temporales para las imágenes
        final photoPath =
            'temp/${userId}_${now.millisecondsSinceEpoch}_photo.jpg';
        final signaturePath =
            'temp/${userId}_${now.millisecondsSinceEpoch}_signature.png';

        // TODO: Almacenar las imágenes localmente en los archivos temporales
        // (Implementar un servicio de almacenamiento local)

        // Crear el registro localmente
        attendance = AttendanceModel(
          id: '', // ID temporal, será generado por la fuente de datos local
          userId: userId,
          locationId: locationId,
          type: type,
          photoPath: photoPath,
          signaturePath: signaturePath,
          latitude: latitude,
          longitude: longitude,
          isValid:
              true, // Asumir válido (la validación se realizará en la sincronización)
          createdAt: now,
          isSynced: false,
        );

        attendance = await localDataSource.createAttendanceRecord(attendance);
      }

      return Right(attendance);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Attendance>> updateAttendanceRecord({
    required String id,
    AttendanceType? type,
    List<int>? photoBytes,
    List<int>? signatureBytes,
    double? latitude,
    double? longitude,
    bool? isValid,
    String? validationMessage,
  }) async {
    try {
      AttendanceModel attendance;

      if (await networkInfo.isConnected) {
        try {
          // Actualizar en el servidor
          attendance = await remoteDataSource.updateAttendanceRecord(
            id: id,
            type: type,
            photoBytes: photoBytes,
            signatureBytes: signatureBytes,
            latitude: latitude,
            longitude: longitude,
            isValid: isValid,
            validationMessage: validationMessage,
          );

          // Actualizar en la caché local
          await localDataSource.updateAttendanceRecord(attendance);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      } else {
        // Si no hay conexión, actualizar localmente
        final currentAttendance = await localDataSource.getAttendanceById(id);

        if (currentAttendance == null) {
          return Left(NotFoundFailure('Registro de asistencia no encontrado'));
        }

        // TODO: Si se proporcionan nuevas imágenes, almacenarlas localmente
        // (Implementar un servicio de almacenamiento local)

        // Actualizar los campos proporcionados
        attendance = currentAttendance.copyWith(
          type: type,
          photoPath: photoBytes != null
              ? 'temp/${currentAttendance.userId}_${DateTime.now().millisecondsSinceEpoch}_photo.jpg'
              : null,
          signaturePath: signatureBytes != null
              ? 'temp/${currentAttendance.userId}_${DateTime.now().millisecondsSinceEpoch}_signature.png'
              : null,
          latitude: latitude,
          longitude: longitude,
          isValid: isValid,
          validationMessage: validationMessage,
          isSynced: false,
        );

        // Guardar los cambios localmente
        attendance = await localDataSource.updateAttendanceRecord(attendance);
      }

      return Right(attendance);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttendanceRecord(String id) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          // Eliminar en el servidor
          await remoteDataSource.deleteAttendanceRecord(id);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      }

      // Eliminar localmente (incluso si la operación remota falla)
      try {
        await localDataSource.deleteAttendanceRecord(id);
      } on DatabaseException catch (e) {
        return Left(DatabaseFailure(e.message));
      }

      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getUserAttendanceForDay({
    required String userId,
    required DateTime date,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final records = await remoteDataSource.getUserAttendanceForDay(
            userId: userId,
            date: date,
          );

          // Guardar en la caché local
          for (final record in records) {
            await localDataSource.createAttendanceRecord(record);
          }

          return Right(records);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final records = await localDataSource.getUserAttendanceForDay(
        userId: userId,
        date: date,
      );

      return Right(records);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getUserAttendanceForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final records = await remoteDataSource.getUserAttendanceForPeriod(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          );

          // Guardar en la caché local
          for (final record in records) {
            await localDataSource.createAttendanceRecord(record);
          }

          return Right(records);
        } catch (e) {
          // Si falla, intentar obtener desde la fuente local
        }
      }

      // Obtener desde la fuente local
      final records = await localDataSource.getUserAttendanceForPeriod(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(records);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> validateAttendanceLocation({
    required String locationId,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final isValid = await remoteDataSource.validateAttendanceLocation(
            locationId: locationId,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );

          return Right(isValid);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      }

      // Si no hay conexión, la validación no puede realizarse de manera precisa
      // Depende de la política de la aplicación, pero en este ejemplo permitimos
      // el registro de asistencia asumiendo que es válido

      return const Right(true);
    } catch (e) {
      return Left(LocationFailure('Error al validar la ubicación'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateUserIdentity({
    required String userId,
    required List<int> photoBytes,
  }) async {
    if (!await networkInfo.isConnected) {
      // Si no hay conexión, asumir que es válido
      // En una aplicación real, esto dependerá de la política de seguridad
      return const Right(true);
    }

    try {
      final isValid = await remoteDataSource.validateUserIdentity(
        userId: userId,
        photoBytes: photoBytes,
      );

      return Right(isValid);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
          FaceRecognitionFailure('Error al validar la identidad del usuario'));
    }
  }

  @override
  Future<Either<Failure, void>> syncAttendanceRecords() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      // Obtener registros pendientes de sincronización
      final pendingRecords =
          await localDataSource.getPendingSyncAttendanceRecords();

      // Sincronizar cada registro
      for (final record in pendingRecords) {
        try {
          if (record.id.isEmpty) {
            // Es un nuevo registro que debe crearse en el servidor

            // Obtener los bytes de las imágenes almacenadas localmente
            // TODO: Implementar la obtención de las imágenes locales

            // Crear el registro en el servidor
            await remoteDataSource.createAttendanceRecord(
              userId: record.userId,
              locationId: record.locationId,
              type: record.type,
              photoBytes: [], // Aquí irían los bytes de la foto
              signatureBytes: [], // Aquí irían los bytes de la firma
              latitude: record.latitude,
              longitude: record.longitude,
            );
          } else {
            // Es un registro existente que debe actualizarse
            // TODO: Si las imágenes se actualizaron, obtener los bytes

            await remoteDataSource.updateAttendanceRecord(
              id: record.id,
              type: record.type,
              isValid: record.isValid,
              validationMessage: record.validationMessage,
            );
          }

          // Marcar como sincronizado
          await localDataSource.markAttendanceAsSynced(record.id);
        } catch (e) {
          // Continuar con el siguiente registro si este falla
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Error al sincronizar registros de asistencia'));
    }
  }
}
