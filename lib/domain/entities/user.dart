import 'package:equatable/equatable.dart';

/// Enumera los roles posibles de un usuario
enum UserRole { admin, supervisor, assistant }

/// Extensión para convertir UserRole a String y viceversa
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.assistant:
        return 'assistant';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'assistant':
        return UserRole.assistant;
      default:
        throw ArgumentError('Rol inválido: $value');
    }
  }
}

/// Entidad que representa un usuario en el sistema
class User extends Equatable {
  /// Identificador único del usuario
  final String id;

  /// Nombre completo del usuario
  final String name;

  /// Correo electrónico del usuario
  final String email;

  /// Rol del usuario en el sistema
  final UserRole role;

  /// Número de teléfono (opcional)
  final String? phone;

  /// Número de identificación (opcional)
  final String? identification;

  /// URL de la foto de perfil (opcional)
  final String? profilePicture;

  /// Indica si el usuario está activo
  final bool isActive;

  /// Fecha de creación del usuario
  final DateTime createdAt;

  /// Fecha de última actualización del usuario
  final DateTime updatedAt;

  /// Indica si el usuario está sincronizado con el servidor
  final bool isSynced;

  /// Constructor de la entidad Usuario
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.identification,
    this.profilePicture,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// Crea una copia del usuario con algunos campos modificados
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? identification,
    String? profilePicture,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      identification: identification ?? this.identification,
      profilePicture: profilePicture ?? this.profilePicture,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Verifica si el usuario es administrador
  bool get isAdmin => role == UserRole.admin;

  /// Verifica si el usuario es supervisor
  bool get isSupervisor => role == UserRole.supervisor;

  /// Verifica si el usuario es asistente
  bool get isAssistant => role == UserRole.assistant;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        phone,
        identification,
        profilePicture,
        isActive,
        createdAt,
        updatedAt,
        isSynced,
      ];
}
