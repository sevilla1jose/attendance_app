part of 'auth_bloc.dart';

/// Clase base para todos los eventos de autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación
class CheckAuthStatusEvent extends AuthEvent {}

/// Evento para iniciar sesión con correo y contraseña
class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Evento para iniciar sesión con Google
class LoginWithGoogleEvent extends AuthEvent {}

/// Evento para cerrar sesión
class LogoutEvent extends AuthEvent {}
