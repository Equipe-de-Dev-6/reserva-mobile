import 'usuario_model.dart';

/// Resposta de login / renovação de token.
///
/// Formato real devolvido por `POST /api/auth/login`:
/// ```json
/// {
///   "token": "eyJhbGciOi...",
///   "refreshToken": "f0bb397effbe...",
///   "expiresIn": 900,
///   "tokenType": "Bearer",
///   "user": { "id": 1, "email": "...", "nome": "...", "role": "admin" },
///   "email": "admin@admin.com"
/// }
/// ```
class AuthRespostaModel {
  final String token;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final UsuarioModel usuario;

  AuthRespostaModel({
    required this.token,
    required this.refreshToken,
    this.expiresIn = 0,
    this.tokenType = 'Bearer',
    required this.usuario,
  });

  factory AuthRespostaModel.fromJson(Map<String, dynamic> json) {
    return AuthRespostaModel(
      token: (json['token'] ?? json['access_token'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? json['refresh_token'] ?? '')
          .toString(),
      expiresIn: _paraInt(json['expiresIn']) ?? 0,
      tokenType: (json['tokenType'] ?? 'Bearer').toString(),
      usuario: UsuarioModel.fromJson(
        Map<String, dynamic>.from(json['user'] ?? json['usuario'] ?? {}),
      ),
    );
  }

  static int? _paraInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }
}
