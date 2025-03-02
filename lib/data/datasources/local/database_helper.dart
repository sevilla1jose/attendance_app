import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';

/// Clase de ayuda para gestionar la base de datos SQLite local
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  /// Obtiene la instancia de la base de datos, creándola si es necesario
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Configuración para web
      databaseFactory = databaseFactoryFfiWeb;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Tabla de usuarios
      await txn.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          role TEXT NOT NULL,
          phone TEXT,
          identification TEXT,
          profile_picture TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tabla de ubicaciones
      await txn.execute('''
        CREATE TABLE locations (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius REAL NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tabla de registros de asistencia
      await txn.execute('''
        CREATE TABLE attendance_records (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          type TEXT NOT NULL,
          photo_path TEXT NOT NULL,
          signature_path TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          is_valid INTEGER NOT NULL DEFAULT 1,
          validation_message TEXT,
          created_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
        )
      ''');

      // Tabla de configuración
      await txn.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          value TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabla de logs de sincronización
      await txn.execute('''
        CREATE TABLE sync_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity TEXT NOT NULL,
          action TEXT NOT NULL,
          record_id TEXT NOT NULL,
          status TEXT NOT NULL,
          message TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    });
  }

  /// Actualiza la base de datos cuando cambia la versión
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Lógica para migraciones futuras
    if (oldVersion < 2) {
      // Migraciones para la versión 2
    }
  }

  /// Inserta un registro en la base de datos
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error insertando en $table: $e');
      throw DatabaseException('Error insertando datos: ${e.toString()}');
    }
  }

  /// Actualiza un registro en la base de datos
  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    try {
      final db = await database;
      return await db.update(
        table,
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error actualizando en $table: $e');
      throw DatabaseException('Error actualizando datos: ${e.toString()}');
    }
  }

  /// Elimina un registro de la base de datos
  Future<int> delete(String table, String id) async {
    try {
      final db = await database;
      return await db.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error eliminando en $table: $e');
      throw DatabaseException('Error eliminando datos: ${e.toString()}');
    }
  }

  /// Obtiene un registro por su ID
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    try {
      final db = await database;
      final results = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return results.first;
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo datos de $table: $e');
      throw DatabaseException('Error obteniendo datos: ${e.toString()}');
    }
  }

  /// Obtiene todos los registros de una tabla
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final db = await database;
      return await db.query(table);
    } catch (e) {
      debugPrint('Error obteniendo todos los datos de $table: $e');
      throw DatabaseException('Error obteniendo datos: ${e.toString()}');
    }
  }

  /// Obtiene registros con filtros personalizados
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error consultando $table: $e');
      throw DatabaseException('Error consultando datos: ${e.toString()}');
    }
  }

  /// Ejecuta una consulta SQL personalizada
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      debugPrint('Error ejecutando consulta: $e');
      throw DatabaseException('Error ejecutando consulta: ${e.toString()}');
    }
  }

  /// Obtiene los registros pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingSyncRecords(String table) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: 'synced = ?',
        whereArgs: [0],
      );
    } catch (e) {
      debugPrint('Error obteniendo registros pendientes de $table: $e');
      throw DatabaseException(
          'Error obteniendo registros pendientes: ${e.toString()}');
    }
  }

  /// Marca un registro como sincronizado
  Future<int> markAsSynced(String table, String id) async {
    try {
      final db = await database;
      return await db.update(
        table,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error marcando como sincronizado en $table: $e');
      throw DatabaseException(
          'Error marcando como sincronizado: ${e.toString()}');
    }
  }

  /// Registra un log de sincronización
  Future<int> logSync(
      String entity, String action, String recordId, String status,
      {String? message}) async {
    try {
      final db = await database;
      return await db.insert(
        'sync_logs',
        {
          'entity': entity,
          'action': action,
          'record_id': recordId,
          'status': status,
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error registrando log de sincronización: $e');
      return -1; // No lanzamos excepción para evitar cascada de errores
    }
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Elimina la base de datos (usado principalmente para pruebas)
  Future<void> deleteDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    await databaseFactory.deleteDatabase(path);
  }
}
