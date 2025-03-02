import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/domain/usecases/auth/get_current_user.dart';
import 'package:attendance_app/domain/usecases/auth/login_with_email.dart';
import 'package:attendance_app/domain/usecases/auth/login_with_google.dart';
import 'package:attendance_app/domain/usecases/auth/logout.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC para gestionar el estado de autenticación
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final Logout logout;

  AuthBloc({
    required this.getCurrentUser,
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.logout,
  }) : super(AuthInitial()) {
    // Verificar el estado de autenticación actual
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);

    // Iniciar sesión con correo y contraseña
    on<LoginWithEmailEvent>(_onLoginWithEmail);

    // Iniciar sesión con Google
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);

    // Cerrar sesión
    on<LogoutEvent>(_onLogout);
  }

  /// Maneja el evento para verificar el estado de autenticación
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await getCurrentUser();

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  /// Maneja el evento para iniciar sesión con correo y contraseña
  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginWithEmail(
      Params(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  /// Maneja el evento para iniciar sesión con Google
  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginWithGoogle();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  /// Maneja el evento para cerrar sesión
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await logout();

    result.fold(
      (failure) {
        // Aún si falla, asumimos que el usuario está desconectado
        emit(AuthUnauthenticated());
      },
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
