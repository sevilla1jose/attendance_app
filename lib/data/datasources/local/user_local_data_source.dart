import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/data/datasources/local/database_helper.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:uuid/uuid.dart';

/// Interfaz para el acceso a datos de usuarios almacenados localmente
abstract class UserLocalDataSource {
  /// Obtiene un usuario por su ID
  Future<UserModel?> getUserById(String id);

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers();

  /// Obtiene usuarios con filtros
  Future<List<UserModel>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  });

  /// Crea un nuevo usuario
  Future<UserModel> createUser(UserModel user);

  /// Actualiza un usuario existente
  Future<UserModel> updateUser(UserModel user);

  /// Elimina un usuario
  Future<void> deleteUser(String id);

  /// Busca usuarios por nombre o correo
  Future<List<UserModel>> searchUsers(String query);

  /// Obtiene los usuarios pendientes de sincronización
  Future<List<UserModel>> getPendingSyncUsers();

  /// Marca un usuario como sincronizado
  Future<void> markUserAsSynced(String id);
}

/// Implementación de [UserLocalDataSource] usando SQLite
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper databaseHelper;

  UserLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      final userData = await databaseHelper.getById('users', id);

      if (userData == null) {
        return null;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      throw DatabaseException('Error al obtener el usuario: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersData = await databaseHelper.getAll('users');

      return usersData.map((userData) => UserModel.fromJson(userData)).toList();
    } catch (e) {
      throw DatabaseException(
          'Error al obtener todos los usuarios: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // Construir la consulta
      String? where;
      List<dynamic>? whereArgs;

      if (role != null || isActive != null || searchQuery != null) {
        final conditions = <String>[];
        whereArgs = <dynamic>[];

        if (role != null) {
          conditions.add('role = ?');
          whereArgs.add(role.value);
        }

        if (isActive != null) {
          conditions.add('is_active = ?');
          whereArgs.add(isActive ? 1 : 0);
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          conditions.add('(name LIKE ? OR email LIKE ?)');
          whereArgs.add('%$searchQuery%');
          whereArgs.add('%$searchQuery%');
        }

        where = conditions.join(' AND ');
      }

      final usersData = await databaseHelper.query(
        'users',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      return usersData.map((userData) => UserModel.fromJson(userData)).toList();
    } catch (e) {
      throw DatabaseException(
          'Error al obtener usuarios filtrados: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      // Generar un ID único si no se proporciona
      final userId = user.id.isEmpty ? const Uuid().v4() : user.id;

      // Preparar el modelo con el ID generado
      final userToCreate = user.copyWith(
        id: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Insertar en la base de datos
      await databaseHelper.insert('users', userToCreate.toJson());

      return userToCreate;
    } catch (e) {
      throw DatabaseException('Error al crear el usuario: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      // Preparar el modelo con la fecha de actualización
      final userToUpdate = user.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Actualizar en la base de datos
      await databaseHelper.update('users', userToUpdate.toJson(), user.id);

      return userToUpdate;
    } catch (e) {
      throw DatabaseException(
          'Error al actualizar el usuario: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await databaseHelper.delete('users', id);
    } catch (e) {
      throw DatabaseException('Error al eliminar el usuario: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      final usersData = await databaseHelper.query(
        'users',
        where: 'name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return usersData.map((userData) => UserModel.fromJson(userData)).toList();
    } catch (e) {
      throw DatabaseException('Error al buscar usuarios: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getPendingSyncUsers() async {
    try {
      final usersData = await databaseHelper.query(
        'users',
        where: 'synced = ?',
        whereArgs: [0],
      );

      return usersData.map((userData) => UserModel.fromJson(userData)).toList();
    } catch (e) {
      throw DatabaseException(
          'Error al obtener usuarios pendientes de sincronización: ${e.toString()}');
    }
  }

  @override
  Future<void> markUserAsSynced(String id) async {
    try {
      await databaseHelper.update(
        'users',
        {'synced': 1, 'updated_at': DateTime.now().toIso8601String()},
        id,
      );
    } catch (e) {
      throw DatabaseException(
          'Error al marcar el usuario como sincronizado: ${e.toString()}');
    }
  }
}
