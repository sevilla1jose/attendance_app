part of 'user_bloc.dart';

/// Clase base para todos los estados de usuarios
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar usuarios
class UserInitial extends UserState {}

/// Estado cuando se está procesando una operación de usuarios
class UserLoading extends UserState {}

/// Estado cuando se han cargado los usuarios
class UsersLoaded extends UserState {
  final List<User> users;

  const UsersLoaded({
    required this.users,
  });

  @override
  List<Object> get props => [users];
}

/// Estado cuando se ha agregado un usuario
class UserAdded extends UsersLoaded {
  final User user;

  const UserAdded({
    required this.user,
    required List<User> users,
  }) : super(users: users);

  @override
  List<Object> get props => [user, users];
}

/// Estado cuando se ha actualizado un usuario
class UserUpdated extends UsersLoaded {
  final User user;

  const UserUpdated({
    required this.user,
    required List<User> users,
  }) : super(users: users);

  @override
  List<Object> get props => [user, users];
}

/// Estado cuando ocurre un error en el proceso de usuarios
class UserError extends UserState {
  final String message;

  const UserError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
