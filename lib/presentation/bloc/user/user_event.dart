part of 'user_bloc.dart';

/// Clase base para todos los eventos de usuarios
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de usuarios
class LoadUsersEvent extends UserEvent {}

/// Evento para filtrar la lista de usuarios
class FilterUsersEvent extends UserEvent {
  final UserRole? role;
  final bool? isActive;
  final String? searchQuery;

  const FilterUsersEvent({
    this.role,
    this.isActive,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [role, isActive, searchQuery];
}

/// Evento para agregar un nuevo usuario
class AddUserEvent extends UserEvent {
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? phone;
  final String? identification;
  final String? profilePicture;

  const AddUserEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.identification,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        role,
        phone,
        identification,
        profilePicture,
      ];
}

/// Evento para actualizar un usuario existente
class UpdateUserEvent extends UserEvent {
  final String id;
  final String? name;
  final String? email;
  final UserRole? role;
  final String? phone;
  final String? identification;
  final String? profilePicture;
  final bool? isActive;

  const UpdateUserEvent({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.phone,
    this.identification,
    this.profilePicture,
    this.isActive,
  });

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
      ];
}
