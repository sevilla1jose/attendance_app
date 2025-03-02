import 'package:equatable/equatable.dart';
import 'package:attendance_app/data/models/user_model.dart';

/// Modelo que representa los datos de autenticación
class AuthModel extends Equatable {
  /// Token de acceso
  final String accessToken;

  /// Token de actualización (opcional)
  final String? refreshToken;

  /// Fecha de expiración del token
  final DateTime expiresAt;

  /// Usuario autenticado
  final UserModel user;

  /// Constructor
  const AuthModel({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  /// Crea una copia del modelo con algunos campos modificados
  AuthModel copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    UserModel? user,
  }) {
    return AuthModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  /// Crea un modelo a partir de un mapa de datos JSON
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
      user: UserModel.fromJson(json['user']),
    );
  }

  /// Convierte el modelo a un mapa de datos JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  /// Crea un modelo a partir de datos de Supabase
  factory AuthModel.fromSupabase(Map<String, dynamic> session, UserModel user) {
    return AuthModel(
      accessToken: session['access_token'],
      refreshToken: session['refresh_token'],
      expiresAt:
          DateTime.fromMillisecondsSinceEpoch(session['expires_at'] * 1000),
      user: user,
    );
  }

  /// Verifica si el token ha expirado
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}
