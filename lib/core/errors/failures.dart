import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos de dominio en la aplicación
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Fallo que ocurre cuando hay un problema de servidor
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required String message, this.statusCode})
      : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Fallo que ocurre cuando hay un problema con la base de datos local
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

/// Fallo que ocurre cuando no hay conectividad
class NetworkFailure extends Failure {
  const NetworkFailure() : super('No hay conexión a internet');
}

/// Fallo que ocurre por problemas de autenticación
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

/// Fallo que ocurre cuando no se encuentran datos
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Fallo que ocurre por problemas con la cámara
class CameraFailure extends Failure {
  const CameraFailure(String message) : super(message);
}

/// Fallo que ocurre por problemas de geolocalización
class LocationFailure extends Failure {
  const LocationFailure(String message) : super(message);
}

/// Fallo que ocurre cuando un usuario no tiene permisos suficientes
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Fallo que ocurre por problemas con el reconocimiento facial
class FaceRecognitionFailure extends Failure {
  const FaceRecognitionFailure(String message) : super(message);
}

/// Fallo que ocurre cuando la validación falla
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Fallo que ocurre cuando hay problemas con el almacenamiento
class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message);
}

/// Fallo que ocurre cuando hay problemas con la sincronización
class SyncFailure extends Failure {
  const SyncFailure(String message) : super(message);
}

/// Fallo que ocurre durante la generación de reportes
class ReportFailure extends Failure {
  const ReportFailure(String message) : super(message);
}

/// Fallo inesperado o general
class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super('Ocurrió un error inesperado');
}
