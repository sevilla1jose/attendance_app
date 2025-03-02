import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/network/supabase_client_app.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:uuid/uuid.dart';

/// Interfaz para el acceso a datos de usuarios remotos
abstract class UserRemoteDataSource {
  /// Obtiene un usuario por su ID
  Future<UserModel> getUserById(String id);

  /// Obtiene todos los usuarios
  Future<List<UserModel>> getAllUsers();

  /// Obtiene usuarios con filtros
  Future<List<UserModel>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  });

  /// Crea un nuevo usuario
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? identification,
    String? profilePicture,
  });

  /// Actualiza un usuario existente
  Future<UserModel> updateUser({
    required String id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? identification,
    String? profilePicture,
    bool? isActive,
  });

  /// Cambia la contraseña de un usuario
  Future<void> changeUserPassword({
    required String id,
    required String newPassword,
  });

  /// Elimina un usuario
  Future<void> deleteUser(String id);

  /// Busca usuarios por nombre o correo
  Future<List<UserModel>> searchUsers(String query);

  /// Actualiza la foto de perfil de un usuario
  Future<String> updateProfilePicture({
    required String userId,
    required List<int> imageBytes,
  });
}

/// Implementación de [UserRemoteDataSource] usando Supabase
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabaseClient;

  UserRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final userData =
          await supabaseClient.getById(AppConstants.usersTable, id);

      return UserModel.fromSupabase(userData);
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener el usuario: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersData = await supabaseClient.query(AppConstants.usersTable);

      return usersData
          .map((userData) => UserModel.fromSupabase(userData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener todos los usuarios: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUsers({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      Map<String, dynamic>? equals;

      // Construir filtros
      if (role != null || isActive != null) {
        equals = {};

        if (role != null) {
          equals['role'] = role.value;
        }

        if (isActive != null) {
          equals['is_active'] = isActive;
        }
      }

      var query = supabaseClient.client.from(AppConstants.usersTable).select();

      // Aplicar filtros de igualdad
      if (equals != null) {
        equals.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Aplicar filtro de búsqueda
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query =
            query.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      // Ordenar por nombre
      query = query.order('name', ascending: true);

      final response = await query;

      return (response as List)
          .map((userData) => UserModel.fromSupabase(userData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al obtener usuarios filtrados: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? identification,
    String? profilePicture,
  }) async {
    try {
      // Crear el usuario en la autenticación de Supabase
      final authResponse = await supabaseClient.client.auth.admin.createUser(
        attributes: {
          'email': email,
          'password': password,
          'email_confirm': true,
        },
      );

      if (authResponse.user == null) {
        throw ServerException(message: 'Error al crear la cuenta de usuario');
      }

      final userId = authResponse.user!.id;

      // Crear el usuario en la base de datos
      final now = DateTime.now();

      final userData = {
        'id': userId,
        'name': name,
        'email': email,
        'role': role.value,
        'phone': phone,
        'identification': identification,
        'profile_picture': profilePicture,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response =
          await supabaseClient.insert(AppConstants.usersTable, userData);

      return UserModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message: 'Error al crear el usuario: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUser({
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
      // Obtener los datos actuales del usuario
      final currentUser = await getUserById(id);

      // Preparar los datos a actualizar
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (role != null) updateData['role'] = role.value;
      if (phone != null) updateData['phone'] = phone;
      if (identification != null) updateData['identification'] = identification;
      if (profilePicture != null)
        updateData['profile_picture'] = profilePicture;
      if (isActive != null) updateData['is_active'] = isActive;

      // Actualizar en la base de datos
      final response = await supabaseClient.update(
        AppConstants.usersTable,
        updateData,
        id: id,
      );

      return UserModel.fromSupabase(response);
    } catch (e) {
      throw ServerException(
          message: 'Error al actualizar el usuario: ${e.toString()}');
    }
  }

  @override
  Future<void> changeUserPassword({
    required String id,
    required String newPassword,
  }) async {
    try {
      // Cambiar la contraseña del usuario
      await supabaseClient.client.auth.admin.updateUserById(
        id,
        attributes: {
          'password': newPassword,
        },
      );
    } catch (e) {
      throw ServerException(
          message: 'Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      // Eliminar el usuario de la base de datos
      await supabaseClient.delete(AppConstants.usersTable, id);

      // Eliminar el usuario de la autenticación
      await supabaseClient.client.auth.admin.deleteUser(id);
    } catch (e) {
      throw ServerException(
          message: 'Error al eliminar el usuario: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      final response = await supabaseClient.client
          .from(AppConstants.usersTable)
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List)
          .map((userData) => UserModel.fromSupabase(userData))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Error al buscar usuarios: ${e.toString()}');
    }
  }

  @override
  Future<String> updateProfilePicture({
    required String userId,
    required List<int> imageBytes,
  }) async {
    try {
      // Generar un nombre único para el archivo
      final filename = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$filename';

      // Subir la imagen al storage
      final imagePath = await supabaseClient.uploadFile(
        AppConstants.profileImagesBucket,
        path,
        imageBytes,
        contentType: 'image/jpeg',
      );

      // Obtener la URL pública de la imagen
      final imageUrl = supabaseClient.getPublicUrl(
        AppConstants.profileImagesBucket,
        imagePath,
      );

      // Actualizar el usuario con la nueva URL de la imagen
      await updateUser(
        id: userId,
        profilePicture: imageUrl,
      );

      return imageUrl;
    } catch (e) {
      throw ServerException(
          message: 'Error al actualizar la foto de perfil: ${e.toString()}');
    }
  }
}
