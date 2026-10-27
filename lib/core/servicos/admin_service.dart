import '../../models/admin_stats_model.dart';
import '../../models/usuario_admin_model.dart';
import 'api_client.dart';

/// Acesso aos endpoints de Administração Geral do Coordenador (Parte 6).
///
/// Três rotas: listagem de usuários, alteração de papel e métricas do
/// sistema. Todas são `/admin/...` e o backend exige role `admin` — um
/// docente que tentar chamar recebe `403 Forbidden` (RN03).
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  static const String _base = '/admin';

  // -------------------------------------------------------------------------
  // GET /admin/users — lista de usuários
  // -------------------------------------------------------------------------

  /// Lista todos os usuários da escola com id, nome, e-mail, papel,
  /// matrícula, departamento, telefone e total de bens.
  ///
  /// Resposta real:
  /// ```json
  /// { "total": 9,
  ///   "users": [ { "id": 2, "email": "professor@escola.com",
  ///     "nome": "Prof. Carlos Drummond", "role": "professor",
  ///     "matricula": "PROF-2024-01", "departamento": "...",
  ///     "telefone": "(11) 98765-1001", "totalPatrimonios": 0,
  ///     "createdAt": "2026-10-20T11:26:42Z" } ]
  /// }
  /// ```
  ///
  /// O endpoint não aceita parâmetro de busca; o recorte por termo é
  /// feito no Controller sobre a lista completa.
  Future<List<UsuarioAdminModel>> listarUsuarios() async {
    final json = await _api.get('$_base/users');

    final lista = (json['users'] as List?) ?? const [];
    return lista
        .whereType<Map>()
        .map((m) => UsuarioAdminModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  // -------------------------------------------------------------------------
  // PATCH /admin/users/{id}/role — alterar papel
  // -------------------------------------------------------------------------

  /// Promove ou rebaixa o papel de um usuário (`admin` ↔ `professor` ↔
  /// `user`).
  ///
  /// O corpo é `{"role": "..."}`. Erros esperados: `400` (papel
  /// inválido), `403` (quem chamou não é admin), `404` (usuário
  /// inexistente).
  Future<void> alterarPapel(int id, String role) async {
    await _api.patch('$_base/users/$id/role', body: {'role': role});
  }

  // -------------------------------------------------------------------------
  // GET /admin/stats — métricas do sistema
  // -------------------------------------------------------------------------

  /// Métricas gerais: total de usuários, admins, professores, usuários
  /// comuns, sessões ativas e códigos de recuperação pendentes.
  ///
  /// Somente o Coordenador tem acesso: o backend responde `403` para
  /// qualquer outro papel.
  Future<AdminStatsModel> estatisticas() async {
    final json = await _api.get('$_base/stats');
    return AdminStatsModel.fromJson(json);
  }
}
