import 'package:attendance_app/domain/entities/user.dart';

/// Modelo para la entidad Usuario en la capa de datos
class UserModel extends User {
  /// Constructor del modelo
  const UserModel({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? identification,
    String? profilePicture,
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isSynced = false,
  }) : super(
          id: id,
          name: name,
          email: email,
          role: role,
          phone: phone,
          identification: identification,
          profilePicture: profilePicture,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isSynced: isSynced,
        );

  /// Crea una copia del modelo con algunos campos modificados
  @override
  UserModel copyWith({
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
    return UserModel(
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

  /// Crea un modelo a partir de un mapa de datos JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRoleExtension.fromString(json['role']),
      phone: json['phone'],
      identification: json['identification'],
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: json['synced'] == 1,
    );
  }

  /// Convierte el modelo a un mapa de datos JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.value,
      'phone': phone,
      'identification': identification,
      'profile_picture': profilePicture,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': isSynced ? 1 : 0,
    };
  }

  /// Crea un modelo a partir de un mapa de datos de Supabase
  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRoleExtension.fromString(json['role']),
      phone: json['phone'],
      identification: json['identification'],
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: true, // Si viene de Supabase, está sincronizado
    );
  }

  /// Convierte el modelo a un mapa de datos para Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.value,
      'phone': phone,
      'identification': identification,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
