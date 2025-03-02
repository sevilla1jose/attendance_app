/// Excepción base para todos los errores en la aplicación
abstract class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// Excepción que ocurre cuando hay un problema de servidor
class ServerException extends AppException {
  final int? statusCode;

  ServerException({required String message, this.statusCode}) : super(message);
}

/// Excepción que ocurre por problemas con la base de datos local
class DatabaseException extends AppException {
  DatabaseException(String message) : super(message);
}

/// Excepción que ocurre cuando no hay conectividad
class NetworkException extends AppException {
  NetworkException() : super('No hay conexión a internet');
}

/// Excepción que ocurre por problemas de autenticación
class AuthException extends AppException {
  AuthException(String message) : super(message);
}

/// Excepción que ocurre cuando no se encuentran datos
class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}

/// Excepción que ocurre por problemas con la cámara
class CameraException extends AppException {
  CameraException(String message) : super(message);
}

/// Excepción que ocurre por problemas de geolocalización
class LocationException extends AppException {
  LocationException(String message) : super(message);
}

/// Excepción que ocurre cuando un usuario no tiene permisos suficientes
class PermissionException extends AppException {
  PermissionException(String message) : super(message);
}

/// Excepción que ocurre por problemas con el reconocimiento facial
class FaceRecognitionException extends AppException {
  FaceRecognitionException(String message) : super(message);
}

/// Excepción que ocurre cuando la validación falla
class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}

/// Excepción que ocurre cuando hay problemas con el almacenamiento
class StorageException extends AppException {
  StorageException(String message) : super(message);
}

/// Excepción que ocurre cuando hay problemas con la sincronización
class SyncException extends AppException {
  SyncException(String message) : super(message);
}

/// Excepción que ocurre durante la generación de reportes
class ReportException extends AppException {
  ReportException(String message) : super(message);
}
