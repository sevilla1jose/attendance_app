import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:attendance_app/core/errors/exceptions.dart';
import 'package:attendance_app/core/network/supabase_client.dart';
import 'package:attendance_app/data/models/auth_model.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/domain/entities/user.dart';

/// Interfaz para el acceso a datos de autenticación remotos
abstract class AuthRemoteDataSource {
  /// Inicia sesión con correo electrónico y contraseña
  Future<AuthModel> loginWithEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con Google
  Future<AuthModel> loginWithGoogle();

  /// Cierra la sesión actual
  Future<void> logout();

  /// Obtiene el usuario autenticado actualmente
  Future<UserModel?> getCurrentUser();

  /// Obtiene el token de autenticación
  Future<String?> getToken();

  /// Restablece la contraseña del usuario
  Future<void> resetPassword(String email);

  /// Cambia la contraseña del usuario autenticado
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Actualiza el perfil del usuario autenticado
  Future<UserModel> updateUserProfile({
    String? name,
    String? phone,
    String? profilePicture,
  });
}

/// Implementación de [AuthRemoteDataSource] usando Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  AuthRemoteDataSourceImpl({
    required this.supabaseClient,
  });

  @override
  Future<AuthModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Autenticar con Supabase
      final response = await supabaseClient.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Error en la autenticación: usuario no encontrado');
      }

      // Obtener los datos del usuario
      final userData = await supabaseClient.query(
        'users',
        equals: {'id': response.user!.id},
      );

      if (userData.isEmpty) {
        throw AuthException('Usuario no encontrado en la base de datos');
      }

      final user = UserModel.fromSupabase(userData.first);

      return AuthModel.fromSupabase(
        {
          'access_token': response.session?.accessToken ?? '',
          'refresh_token': response.session?.refreshToken,
          'expires_at': response.session?.expiresAt ?? 0,
        },
        user,
      );
    } catch (e) {
      throw AuthException('Error al iniciar sesión con email: ${e.toString()}');
    }
  }

  @override
  Future<AuthModel> loginWithGoogle() async {
    try {
      // Autenticar con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Inicio de sesión con Google cancelado');
      }

      // Obtener credenciales de autenticación de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear credenciales para Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase
      final firebase_auth.UserCredential authResult =
          await _firebaseAuth.signInWithCredential(credential);

      // Obtener token de Firebase para autenticar con Supabase
      final String? idToken = await authResult.user?.getIdToken();

      if (idToken == null) {
        throw AuthException('No se pudo obtener el token de ID');
      }

      // Autenticar con Supabase usando OAuth
      final response = await supabaseClient.client.auth.signInWithIdToken(
        provider: 'google',
        idToken: idToken,
      );

      if (response.user == null) {
        throw AuthException('Error en la autenticación con Supabase');
      }

      // Verificar si el usuario existe en la base de datos
      final userData = await supabaseClient.query(
        'users',
        equals: {'id': response.user!.id},
      );

      UserModel user;

      if (userData.isEmpty) {
        // Crear un nuevo usuario en caso de que no exista
        final newUser = UserModel(
          id: response.user!.id,
          name: authResult.user?.displayName ?? 'Usuario de Google',
          email: authResult.user?.email ?? googleUser.email,
          role: UserRole.assistant, // Rol por defecto para nuevos usuarios
          profilePicture: authResult.user?.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Guardar el nuevo usuario en la base de datos
        await supabaseClient.insert('users', newUser.toSupabase());

        user = newUser;
      } else {
        user = UserModel.fromSupabase(userData.first);
      }

      return AuthModel.fromSupabase(
        {
          'access_token': response.session?.accessToken ?? '',
          'refresh_token': response.session?.refreshToken,
          'expires_at': response.session?.expiresAt ?? 0,
        },
        user,
      );
    } catch (e) {
      throw AuthException(
          'Error al iniciar sesión con Google: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Cerrar sesión en Supabase
      await supabaseClient.client.auth.signOut();

      // Cerrar sesión en Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Cerrar sesión en Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Error al cerrar sesión: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = supabaseClient.client.auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      // Obtener los datos del usuario
      final userData = await supabaseClient.query(
        'users',
        equals: {'id': currentUser.id},
      );

      if (userData.isEmpty) {
        return null;
      }

      return UserModel.fromSupabase(userData.first);
    } catch (e) {
      throw AuthException(
          'Error al obtener el usuario actual: ${e.toString()}');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final session = supabaseClient.client.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      throw AuthException(
          'Error al obtener el token de autenticación: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException(
          'Error al restablecer la contraseña: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = supabaseClient.client.auth.currentUser;

      if (currentUser == null) {
        throw AuthException('No hay un usuario autenticado');
      }

      // Verificar contraseña actual
      await supabaseClient.client.auth.signInWithPassword(
        email: currentUser.email ?? '',
        password: currentPassword,
      );

      // Cambiar la contraseña
      await supabaseClient.client.auth.updateUser(
        password: newPassword,
      );
    } catch (e) {
      throw AuthException('Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final currentUser = supabaseClient.client.auth.currentUser;

      if (currentUser == null) {
        throw AuthException('No hay un usuario autenticado');
      }

      // Obtener los datos actuales del usuario
      final userData = await supabaseClient.query(
        'users',
        equals: {'id': currentUser.id},
      );

      if (userData.isEmpty) {
        throw AuthException('Usuario no encontrado en la base de datos');
      }

      final user = UserModel.fromSupabase(userData.first);

      // Crear el mapa de datos a actualizar
      final updatedData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updatedData['name'] = name;
      if (phone != null) updatedData['phone'] = phone;
      if (profilePicture != null)
        updatedData['profile_picture'] = profilePicture;

      // Actualizar los datos del usuario
      final updatedUser = await supabaseClient.update(
        'users',
        updatedData,
        id: currentUser.id,
      );

      return UserModel.fromSupabase(updatedUser);
    } catch (e) {
      throw AuthException('Error al actualizar el perfil: ${e.toString()}');
    }
  }
}
