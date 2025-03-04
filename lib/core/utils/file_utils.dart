import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;

/// Utilidades para el manejo de archivos
class FileUtils {
  /// Obtiene un directorio temporal para guardar archivos
  static Future<String> getTemporaryDirectoryApp() async {
    if (kIsWeb) {
      return '';
    }

    final directory = await getTemporaryDirectoryPathApp();
    return directory;
  }

  /// Obtiene la ruta del directorio temporal
  static Future<String> getTemporaryDirectoryPathApp() async {
    if (kIsWeb) {
      return '';
    }

    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// Obtiene un directorio para guardar archivos de la aplicación
  static Future<String> getApplicationDirectory() async {
    if (kIsWeb) {
      return '';
    }

    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Genera un nombre único para un archivo
  static String generateUniqueFileName(String extension) {
    final uuid = const Uuid().v4();
    return '$uuid.$extension';
  }

  /// Guarda un archivo en el sistema de archivos
  static Future<String> saveFile({
    required Uint8List bytes,
    required String fileName,
    String? directory,
  }) async {
    if (kIsWeb) {
      return _saveFileWeb(bytes, fileName);
    } else {
      return _saveFileNative(bytes, fileName, directory);
    }
  }

  /// Guarda un archivo en navegadores web
  static Future<String> _saveFileWeb(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName;

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    return fileName;
  }

  /// Guarda un archivo en dispositivos nativos
  static Future<String> _saveFileNative(
      Uint8List bytes, String fileName, String? directory) async {
    String filePath;

    if (directory != null) {
      filePath = '$directory/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } else {
      filePath = await FileSaver.instance.saveFile(
        name: fileName.split('.').first,
        bytes: bytes,
        ext: fileName.split('.').last,
      );
    }

    return filePath;
  }

  /// Abre un archivo con la aplicación predeterminada del sistema
  static Future<void> openFile(String filePath) async {
    if (kIsWeb) {
      // No es posible abrir un archivo directamente en web
      return;
    }

    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint('Error opening file: ${result.message}');
    }
  }

  /// Selecciona un archivo del sistema
  static Future<Uint8List?> pickFile({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      return result.files.first.bytes;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Guarda un PDF en el sistema
  static Future<String> savePdf(Uint8List bytes, String fileName) async {
    return await saveFile(
      bytes: bytes,
      fileName: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
    );
  }

  /// Guarda un Excel en el sistema
  static Future<String> saveExcel(Uint8List bytes, String fileName) async {
    return await saveFile(
      bytes: bytes,
      fileName: fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx',
    );
  }

  /// Guarda una imagen en el sistema
  static Future<String> saveImage(Uint8List bytes, String fileName,
      {String format = 'png'}) async {
    final extension = fileName.split('.').last.toLowerCase();

    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      fileName = '$fileName.$format';
    }

    return await saveFile(
      bytes: bytes,
      fileName: fileName,
    );
  }

  /// Elimina un archivo del sistema
  static Future<bool> deleteFile(String filePath) async {
    if (kIsWeb) {
      return false;
    }

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Convierte una imagen a bytes
  static Future<Uint8List?> imageToBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      debugPrint('Error converting image to bytes: $e');
      return null;
    }
  }

  /// Obtiene el tamaño de un archivo en formato legible
  static String getFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(2);
      return '$kb KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
      return '$gb GB';
    }
  }
}
