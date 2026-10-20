import '../../models/perfil_request.dart';
import '../../models/usuario_model.dart';
import 'api_client.dart';
import 'sessao_service.dart';

/// Acesso ao perfil do usuário autenticado (RF09 / RN06).
///
/// Diferente dos outros módulos, `/profile` é liberado para **os dois**
/// papéis: o Coordinator atualiza os próprios dados de contato e o
/// docente faz o mesmo (RN06). Não há nada de professor aqui — o
/// endpoint devolve sempre quem está logado, nunca um terceiro.
class PerfilService {
  PerfilService(this._api, this._sessao);

  final ApiClient _api;
  final SessaoService _sessao;

  static const String _rota = '/profile';

  // -------------------------------------------------------------------------
  // GET /profile — dados cadastrais do usuário autenticado
  // -------------------------------------------------------------------------
  Future<UsuarioModel> meuPerfil() async {
    final json = await _api.get(_rota);
    return UsuarioModel.fromJson(_desembrulhar(json));
  }

  // -------------------------------------------------------------------------
  // PUT /profile — dados cadastrais
  // -------------------------------------------------------------------------
  ///
  /// O corpo carrega apenas os campos alterados; um corpo vazio é
  /// recusado pelo backend com `400`.
  Future<UsuarioModel> atualizarDados(AtualizarPerfilRequestModel dados) async {
    return _enviar(dados.toJson());
  }

  // -------------------------------------------------------------------------
  // PUT /profile — redefinição de senha (RF09)
  // -------------------------------------------------------------------------
  ///
  /// A senha é trocada pelo **mesmo** endpoint, na chave `newPassword`.
  /// Não há rota separada de "change-password" no Swagger.
  Future<UsuarioModel> alterarSenha(AlterarSenhaRequestModel dados) async {
    return _enviar(dados.toJson());
  }

  // -------------------------------------------------------------------------
  // Interno
  // -------------------------------------------------------------------------
  Future<UsuarioModel> _enviar(Map<String, dynamic> body) async {
    final json = await _api.put(_rota, body: body);
    return UsuarioModel.fromJson(_desembrulhar(json));
  }

  /// O `GET` devolve o usuário solto; o `PUT` devolve o envelope
  /// `{"message": "...", "user": {...}}`. Esta função aceita os dois
  /// formatos para que uma mudança de contrato no backend não vire um
  /// usuário vazio na tela.
  static Map<String, dynamic> _desembrulhar(Map<String, dynamic> json) {
    final envelope = json['user'];
    if (envelope is Map) return Map<String, dynamic>.from(envelope);
    return json;
  }

  /// Devolve a sessão para quem precisa manter o perfil salvo em
  /// sincronia com o servidor (o Controller de Perfil usa).
  SessaoService get sessao => _sessao;
}
