import '../../models/auth_requests.dart';
import '../../models/auth_resposta.dart';
import 'api_client.dart';
import 'sessao_service.dart';

/// Camada de acesso aos endpoints do módulo de Autenticação.
///
/// Este Service não sabe nada de Flutter: ele apenas traduz Model ↔ JSON
/// e delega o transporte ao [ApiClient]. É o Controller quem decide o que
/// fazer com o resultado (navegar, exibir erro, etc.).
class AuthService {
  AuthService(this._api, this._sessao);

  final ApiClient _api;
  final SessaoService _sessao;

  // -------------------------------------------------------------------------
  // POST /auth/login — RF01
  // -------------------------------------------------------------------------
  Future<AuthRespostaModel> login(String email, String senha) async {
    final json = await _api.post(
      '/auth/login',
      body: LoginRequestModel(email: email, senha: senha).toJson(),
      autenticado: false,
    );
    return AuthRespostaModel.fromJson(json);
  }

  // -------------------------------------------------------------------------
  // POST /auth/register — RF02 / RN01
  // Cria exclusivamente um Coordenador (role "admin"). O backend recusa
  // qualquer tentativa de auto-cadastro de professor.
  // -------------------------------------------------------------------------
  Future<void> cadastrarCoordenador(CadastroAdminRequestModel dados) async {
    await _api.post(
      '/auth/register',
      body: dados.toJson(),
      autenticado: false,
    );
  }

  // -------------------------------------------------------------------------
  // POST /auth/logout — RF04
  // Invalida o refresh token no servidor. O access token em memória é
  // descartado localmente pelo SessaoService.
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    final refreshToken = _sessao.refreshToken.value;
    if (refreshToken.isEmpty) return;

    await _api.post(
      '/auth/logout',
      body: RefreshTokenRequestModel(refreshToken: refreshToken).toJson(),
    );
  }

  // -------------------------------------------------------------------------
  // POST /auth/forgot-password — RF03 (etapa 1)
  // -------------------------------------------------------------------------
  Future<SolicitarCodigoRespostaModel> solicitarCodigo(String email) async {
    final json = await _api.post(
      '/auth/forgot-password',
      body: SolicitarCodigoRequestModel(email: email).toJson(),
      autenticado: false,
    );
    return SolicitarCodigoRespostaModel.fromJson(json);
  }

  // -------------------------------------------------------------------------
  // POST /auth/verify-code — RF03 (etapa 2)
  // -------------------------------------------------------------------------
  Future<void> verificarCodigo(String email, String codigo) async {
    await _api.post(
      '/auth/verify-code',
      body: VerificarCodigoRequestModel(email: email, codigo: codigo).toJson(),
      autenticado: false,
    );
  }

  // -------------------------------------------------------------------------
  // POST /auth/reset-password — RF03 (etapa 3)
  // -------------------------------------------------------------------------
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    await _api.post(
      '/auth/reset-password',
      body: RedefinirSenhaRequestModel(
        email: email,
        codigo: codigo,
        novaSenha: novaSenha,
      ).toJson(),
      autenticado: false,
    );
  }
}
