/// Excepción base para todos los errores en la aplicación
abstract class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// Excepción que ocurre cuando hay un problema de servidor
class ServerExceptionApp extends AppException {
  final int? statusCode;

  ServerExceptionApp({
    required String message,
    this.statusCode,
  }) : super(message);
}

/// Excepción que ocurre por problemas con la base de datos local
class DatabaseExceptionApp extends AppException {
  DatabaseExceptionApp(String message) : super(message);
}

/// Excepción que ocurre cuando no hay conectividad
class NetworkExceptionApp extends AppException {
  NetworkExceptionApp() : super('No hay conexión a internet');
}

/// Excepción que ocurre por problemas de autenticación
class AuthExceptionApp extends AppException {
  AuthExceptionApp(String message) : super(message);
}

/// Excepción que ocurre cuando no se encuentran datos
class NotFoundExceptionApp extends AppException {
  NotFoundExceptionApp(String message) : super(message);
}

/// Excepción que ocurre por problemas con la cámara
class CameraExceptionApp extends AppException {
  CameraExceptionApp(String message) : super(message);
}

/// Excepción que ocurre por problemas de geolocalización
class LocationExceptionApp extends AppException {
  LocationExceptionApp(String message) : super(message);
}

/// Excepción que ocurre cuando un usuario no tiene permisos suficientes
class PermissionExceptionApp extends AppException {
  PermissionExceptionApp(String message) : super(message);
}

/// Excepción que ocurre por problemas con el reconocimiento facial
class FaceRecognitionExceptioApp extends AppException {
  FaceRecognitionExceptioApp(String message) : super(message);
}

/// Excepción que ocurre cuando la validación falla
class ValidationExceptionApp extends AppException {
  ValidationExceptionApp(String message) : super(message);
}

/// Excepción que ocurre cuando hay problemas con el almacenamiento
class StorageExceptionApp extends AppException {
  StorageExceptionApp(String message) : super(message);
}

/// Excepción que ocurre cuando hay problemas con la sincronización
class SyncExceptionApp extends AppException {
  SyncExceptionApp(String message) : super(message);
}

/// Excepción que ocurre durante la generación de reportes
class ReportExceptionApp extends AppException {
  ReportExceptionApp(String message) : super(message);
}
