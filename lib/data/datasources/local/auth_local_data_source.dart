import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/data/models/auth_model.dart';
import 'package:attendance_app/data/models/user_model.dart';

/// Interfaz para el acceso a datos de autenticación almacenados localmente
abstract class AuthLocalDataSource {
  /// Guarda los datos de autenticación
  Future<void> saveAuth(AuthModel auth);

  /// Obtiene los datos de autenticación almacenados
  Future<AuthModel?> getAuth();

  /// Borra los datos de autenticación
  Future<void> clearAuth();

  /// Obtiene el token de autenticación
  Future<String?> getToken();

  /// Guarda el usuario actual
  Future<void> saveCurrentUser(UserModel user);

  /// Obtiene el usuario actual
  Future<UserModel?> getCurrentUser();
}

/// Implementación de [AuthLocalDataSource] usando SharedPreferences
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveAuth(AuthModel auth) async {
    try {
      // Guardar el token
      await sharedPreferences.setString(
        AppConstants.userTokenKey,
        auth.accessToken,
      );

      // Guardar el modelo completo de autenticación
      final authJson = json.encode(auth.toJson());
      await sharedPreferences.setString(AppConstants.userDataKey, authJson);
    } catch (e) {
      throw DatabaseExceptionApp(
        'Error al guardar los datos de autenticación: $e',
      );
    }
  }

  @override
  Future<AuthModel?> getAuth() async {
    try {
      final authJson = sharedPreferences.getString(AppConstants.userDataKey);

      if (authJson == null) {
        return null;
      }

      final authMap = json.decode(authJson) as Map<String, dynamic>;
      return AuthModel.fromJson(authMap);
    } catch (e) {
      throw DatabaseExceptionApp(
          'Error al obtener los datos de autenticación: $e');
    }
  }

  @override
  Future<void> clearAuth() async {
    try {
      await sharedPreferences.remove(AppConstants.userTokenKey);
      await sharedPreferences.remove(AppConstants.userDataKey);
    } catch (e) {
      throw DatabaseExceptionApp(
          'Error al borrar los datos de autenticación: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return sharedPreferences.getString(AppConstants.userTokenKey);
    } catch (e) {
      throw DatabaseExceptionApp('Error al obtener el token: $e');
    }
  }

  @override
  Future<void> saveCurrentUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await sharedPreferences.setString('current_user', userJson);
    } catch (e) {
      throw DatabaseExceptionApp('Error al guardar el usuario actual: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = sharedPreferences.getString('current_user');

      if (userJson == null) {
        return null;
      }

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw DatabaseExceptionApp('Error al obtener el usuario actual: $e');
    }
  }
}
