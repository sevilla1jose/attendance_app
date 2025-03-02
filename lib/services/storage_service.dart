import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:attendance_app/core/errors/exceptions.dart';

/// Interfaz para el servicio de almacenamiento
abstract class StorageService {
  /// Guarda una foto localmente
  Future<String> savePhoto(Uint8List photoBytes, String userId);

  /// Guarda una firma localmente
  Future<String> saveSignature(Uint8List signatureBytes, String userId);

  /// Obtiene un archivo como bytes
  Future<Uint8List> getFileBytes(String filePath);

  /// Elimina un archivo
  Future<bool> deleteFile(String filePath);

  /// Crea un directorio si no existe
  Future<String> ensureDirectoryExists(String dirPath);

  /// Obtiene el directorio de almacenamiento temporal
  Future<String> getTemporaryDirectory();

  /// Obtiene el directorio de documentos
  Future<String> getDocumentsDirectory();

  /// Genera un nombre de archivo único
  String generateUniqueFileName(String extension);
}

/// Implementación del servicio de almacenamiento
class StorageServiceImpl implements StorageService {
  @override
  Future<String> savePhoto(Uint8List photoBytes, String userId) async {
    try {
      if (kIsWeb) {
        // En web, retornamos un identificador único que se usará como referencia
        // Los bytes se almacenarían en IndexedDB o en localStorage si son pocos
        // Para este ejemplo, solo devolvemos un path virtual
        return 'photos/$userId/${generateUniqueFileName("jpg")}';
      }

      // Obtener el directorio de almacenamiento
      final String dirPath = await ensureDirectoryExists(
          path.join(await getDocumentsDirectory(), 'photos', userId));

      // Generar nombre de archivo único
      final String fileName = generateUniqueFileName('jpg');

      // Path completo del archivo
      final String filePath = path.join(dirPath, fileName);

      // Escribir el archivo
      final File file = File(filePath);
      await file.writeAsBytes(photoBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error al guardar la foto: $e');
      throw StorageException('Error al guardar la foto: ${e.toString()}');
    }
  }

  @override
  Future<String> saveSignature(Uint8List signatureBytes, String userId) async {
    try {
      if (kIsWeb) {
        // Similar a savePhoto para web
        return 'signatures/$userId/${generateUniqueFileName("png")}';
      }

      // Obtener el directorio de almacenamiento
      final String dirPath = await ensureDirectoryExists(
          path.join(await getDocumentsDirectory(), 'signatures', userId));

      // Generar nombre de archivo único
      final String fileName = generateUniqueFileName('png');

      // Path completo del archivo
      final String filePath = path.join(dirPath, fileName);

      // Escribir el archivo
      final File file = File(filePath);
      await file.writeAsBytes(signatureBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error al guardar la firma: $e');
      throw StorageException('Error al guardar la firma: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> getFileBytes(String filePath) async {
    try {
      if (kIsWeb) {
        // En web, recuperaríamos los bytes de IndexedDB o localStorage
        // Para este ejemplo, lanzamos una excepción ya que es solo el path virtual
        throw StorageException(
            'No se pueden obtener los bytes en web desde el path: $filePath');
      }

      // Verificar si el archivo existe
      final File file = File(filePath);
      if (!await file.exists()) {
        throw StorageException('El archivo no existe: $filePath');
      }

      // Leer los bytes del archivo
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error al obtener los bytes del archivo: $e');
      throw StorageException(
          'Error al obtener los bytes del archivo: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // En web, eliminaríamos los bytes de IndexedDB o localStorage
        // Para este ejemplo, simplemente retornamos true
        return true;
      }

      // Verificar si el archivo existe
      final File file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Eliminar el archivo
      await file.delete();

      return true;
    } catch (e) {
      debugPrint('Error al eliminar el archivo: $e');
      return false;
    }
  }

  @override
  Future<String> ensureDirectoryExists(String dirPath) async {
    try {
      if (kIsWeb) {
        // En web, no necesitamos crear directorios físicos
        return dirPath;
      }

      // Crear el directorio si no existe
      final Directory dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      return dirPath;
    } catch (e) {
      debugPrint('Error al crear el directorio: $e');
      throw StorageException('Error al crear el directorio: ${e.toString()}');
    }
  }

  @override
  Future<String> getTemporaryDirectory() async {
    try {
      if (kIsWeb) {
        // En web, retornamos un path virtual
        return 'temp';
      }

      final Directory dir = await getTemporaryDirectoryPath();
      return dir.path;
    } catch (e) {
      debugPrint('Error al obtener el directorio temporal: $e');
      throw StorageException(
          'Error al obtener el directorio temporal: ${e.toString()}');
    }
  }

  Future<Directory> getTemporaryDirectoryPath() async {
    return await getTemporaryDirectory();
  }

  @override
  Future<String> getDocumentsDirectory() async {
    try {
      if (kIsWeb) {
        // En web, retornamos un path virtual
        return 'documents';
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      debugPrint('Error al obtener el directorio de documentos: $e');
      throw StorageException(
          'Error al obtener el directorio de documentos: ${e.toString()}');
    }
  }

  @override
  String generateUniqueFileName(String extension) {
    // Generar un UUID v4
    final String uuid = const Uuid().v4();

    // Obtener timestamp actual
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Combinar para asegurar unicidad
    return '$uuid-$timestamp.$extension';
  }
}
