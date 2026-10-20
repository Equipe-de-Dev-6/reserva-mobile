import '../../models/professor_model.dart';
import '../../models/professor_request.dart';
import 'api_client.dart';

/// Acesso aos endpoints de gestão de professores do Coordenador (RF06).
///
/// Todas as rotas são `/admin/...` e o backend exige role `admin`: um
/// docente que tentar chamar recebe `403 Forbidden` (RN03). Este Service
/// só traduz Model ↔ JSON e entrega o transporte ao [ApiClient] — quem
/// decide o que exibir é o Controller.
class ProfessorService {
  ProfessorService(this._api);

  final ApiClient _api;

  /// Rota base do módulo. Fica num único lugar para não se espalhar
  /// por várias strings dentro do arquivo.
  static const String _base = '/admin/professores';

  // -------------------------------------------------------------------------
  // GET /admin/professores — listagem com o contador de bens (RF06)
  // -------------------------------------------------------------------------
  ///
  /// Resposta real:
  /// ```json
  /// { "total": 2,
  ///   "professores": [
  ///     { "id": 2, "nome": "Prof. Carlos Drummond",
  ///       "email": "professor@escola.com", "matricula": "PROF-2024-01",
  ///       "departamento": "Língua Portuguesa e Literatura",
  ///       "telefone": "(11) 98765-1001", "cpf": "", "role": "professor",
  ///       "totalPatrimonios": 3, "createdAt": "2026-09-22T16:48:21Z" }
  ///   ] }
  /// ```
  ///
  /// O endpoint **não** aceita parâmetro de busca; a busca da tela é
  /// feita no aparelho (ver `ProfessorModel.correspondeAoTermo`).
  Future<List<ProfessorModel>> listar() async {
    final json = await _api.get(_base);

    final lista = (json['professores'] as List?) ?? const [];
    return lista
        .whereType<Map>()
        .map((m) => ProfessorModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  // -------------------------------------------------------------------------
  // POST /admin/professores — cadastro centralizado (RF06 / RN02)
  // -------------------------------------------------------------------------
  ///
  /// O Coordenador autentado é quem cria o docente e quem define a
  /// senha provisória. Erros esperados do backend:
  /// `400` (nome/e-mail/senha obrigatórios), `409` (e-mail já existe)
  /// e `403` (quem chamou não é admin).
  Future<ProfessorModel> cadastrar(ProfessorRequestModel dados) async {
    final json = await _api.post(_base, body: dados.toJson());

    // O backend responde `{"message": "...", "professor": {...}}`.
    // Se um dia o envelope mudar, o Controller ainda recebe um Model
    // vazio em vez de um `null` — e a tela avisa em vez de quebrar.
    return ProfessorModel.fromJson(
      Map<String, dynamic>.from(json['professor'] ?? <String, dynamic>{}),
    );
  }

  // -------------------------------------------------------------------------
  // GET /admin/professores/{id} — docente + bens vinculados (RF06)
  // -------------------------------------------------------------------------
  ///
  /// `404` quando o id não pertence à gestão do coordenador logado —
  /// é a barreira da RN07 (isolamento multi-tenant) do lado do servidor.
  Future<ProfessorDetalheModel> detalhe(int id) async {
    final json = await _api.get('$_base/$id');
    return ProfessorDetalheModel.fromJson(json);
  }
}
