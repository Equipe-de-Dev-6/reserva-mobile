import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../models/usuario_model.dart';

/// Guarda a sessão do usuário (tokens JWT + perfil) de forma persistente
/// e segura.
///
/// O token **não** fica em SharedPreferences: ele é gravado em
/// `FlutterSecureStorage`, que no Android usa o EncryptedSharedPreferences
/// e no iOS o Keychain — o requisito de segurança do RF01.
///
/// É um [GetxService] para ser inicializada uma única vez, via
/// `Get.putAsync`, antes de qualquer rota ser desenhada.
class SessaoService extends GetxService {
  static const _kToken = 'auth_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUsuario = 'auth_usuario';

  /// Criptografia: no Android usa o EncryptedSharedPreferences, no iOS e
  /// macOS o Keychain e no Windows o DPAPI do próprio sistema.
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // --- Estado reativo observável pela UI --------------------------------
  final RxString token = ''.obs;
  final RxString refreshToken = ''.obs;
  final Rx<UsuarioModel?> usuario = Rx<UsuarioModel?>(null);

  bool get autenticado => token.value.isNotEmpty && usuario.value != null;

  /// Lê a sessão salva e restaura o estado em memória.
  Future<SessaoService> init() async {
    try {
      token.value = await _storage.read(key: _kToken) ?? '';
      refreshToken.value = await _storage.read(key: _kRefreshToken) ?? '';

      final usuarioSalvo = await _storage.read(key: _kUsuario);
      if (usuarioSalvo != null && usuarioSalvo.isNotEmpty) {
        usuario.value = UsuarioModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(usuarioSalvo) as Map),
        );
      }
    } catch (_) {
      // Se o armazenamento seguro falhar (ex.: desktop sem keychain),
      // o app continua funcionando apenas com sessão em memória.
      await limpar();
    }
    return this;
  }

  /// Persiste a sessão retornada por um login/refresh bem-sucedido.
  Future<void> salvar({
    required String token,
    required String refreshToken,
    required UsuarioModel usuario,
  }) async {
    this.token.value = token;
    this.refreshToken.value = refreshToken;
    this.usuario.value = usuario;

    try {
      await _storage.write(key: _kToken, value: token);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
      await _storage.write(key: _kUsuario, value: jsonEncode(usuario.toJson()));
    } catch (_) {
      // Falha de persistência não impede o uso na sessão atual.
    }
  }

  /// Atualiza apenas o perfil (usado pela tela de Perfil, RF09).
  Future<void> atualizarUsuario(UsuarioModel novo) async {
    usuario.value = novo;
    try {
      await _storage.write(key: _kUsuario, value: jsonEncode(novo.toJson()));
    } catch (_) {
      // Ver comentário em [salvar].
    }
  }

  /// Troca somente o access token, mantendo refresh token e perfil.
  Future<void> atualizarToken(String novoToken) async {
    token.value = novoToken;
    try {
      await _storage.write(key: _kToken, value: novoToken);
    } catch (_) {
      // Ver comentário em [salvar].
    }
  }

  /// RF04 / Logout: encerra a sessão e apaga o token do dispositivo.
  Future<void> limpar() async {
    token.value = '';
    refreshToken.value = '';
    usuario.value = null;
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kRefreshToken);
      await _storage.delete(key: _kUsuario);
    } catch (_) {
      // Ver comentário em [salvar].
    }
  }
}
