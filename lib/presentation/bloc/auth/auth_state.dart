part of 'auth_bloc.dart';

/// Clase base para todos los estados de autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de verificar la autenticación
class AuthInitial extends AuthState {}

/// Estado cuando se está procesando una operación de autenticación
class AuthLoading extends AuthState {}

/// Estado cuando el usuario está autenticado
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object> get props => [user];
}

/// Estado cuando el usuario no está autenticado
class AuthUnauthenticated extends AuthState {}

/// Estado cuando ocurre un error en el proceso de autenticación
class AuthError extends AuthState {
  final String message;

  const AuthError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
