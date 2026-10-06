import '../../models/historico_model.dart';
import '../../models/patrimonio_criacao_model.dart';
import '../../models/patrimonio_model.dart';
import '../../models/status_patrimonio.dart';
import 'api_client.dart';

/// Categorias usadas no filtro da listagem (RF07a).
///
/// O backend não expõe um endpoint de categorias, então a lista é
/// mantida aqui. São exatamente as quatro que a API documenta como
/// exemplo em `GET /patrimonios?categoria=`.
const List<String> categoriasPatrimonio = [
  'Informática',
  'Audiovisual',
  'Laboratório',
  'Eletrônicos',
];

/// Estados de conservação oferecidos no formulário de cadastro.
const List<String> estadosConservacao = [
  'Novo',
  'Excelente',
  'Bom',
  'Regular',
  'Ruim',
];

/// Camada de acesso aos endpoints de Patrimônio.
///
/// Este Service não sabe nada de Flutter: traduz Model ↔ JSON e delega
/// o transporte ao [ApiClient]. É o Controller que decide o que fazer
/// com o resultado.
///
/// ## RBAC (RN03)
///
/// A API decide o que cada papel enxerga, e o app respeita:
///
/// | Endpoint | Professor | Coordenador |
/// |----------|-----------|-------------|
/// | `GET /patrimonios` | só os bens vinculados a ele | todo o acervo |
/// | `GET /patrimonios/{id}` | só se o bem for dele | qualquer bem |
/// | `POST`/`PUT`/`DELETE` | **403** | permitido |
/// | `GET .../historico` | — | permitido |
///
/// Nenhum método aqui "disfarça" a restrição: quando o docente chama
/// [criar], a API devolve 403 e o `chamar()` transforma em
/// `AppException` com a mensagem do servidor.
class PatrimonioService {
  PatrimonioService(this._api);

  final ApiClient _api;

  // -------------------------------------------------------------------------
  // GET /patrimonios — RF07a (listagem com busca e filtros)
  // -------------------------------------------------------------------------

  /// Lista o acervo, opcionalmente filtrado.
  ///
  /// Os quatro parâmetros são exatamente os aceitos pela API:
  /// `busca` (tombamento, nome, marca, modelo), `status`, `categoria` e
  /// `professor_id`. Valores nulos ou vazios são **omitidos** da query —
  /// mandar `busca=` faria o backend filtrar pela string vazia em vez de
  /// listar tudo.
  ///
  /// Devolve os modelos já ordenados como a API enviou.
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    final json = await _api.get(
      '/patrimonios',
      query: _query(
        busca: busca,
        status: status,
        categoria: categoria,
        professorId: professorId,
      ),
    );
    return _itens(json);
  }

  /// Monta o dicionário de query descartando filtros não aplicáveis.
  ///
  /// Isolar isso em um método privado deixa a regra auditável e
  /// testável sem precisar subir um servidor.
  static Map<String, dynamic> _query({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) {
    final query = <String, dynamic>{};

    final termo = busca?.trim() ?? '';
    if (termo.isNotEmpty) query['busca'] = termo;

    if (status != null && status.api.isNotEmpty) {
      query['status'] = status.api;
    }

    final categoriaLimpa = categoria?.trim() ?? '';
    if (categoriaLimpa.isNotEmpty) query['categoria'] = categoriaLimpa;

    if (professorId != null) query['professor_id'] = professorId;

    return query;
  }

  /// Lê `items` de `PatrimoniosListResponse`, tolerando lista ausente.
  static List<PatrimonioModel> _itens(Map<String, dynamic> json) {
    final lista = json['items'];
    if (lista is! List) return const <PatrimonioModel>[];

    return lista
        .whereType<Map>()
        .map((item) => PatrimonioModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // -------------------------------------------------------------------------
  // GET /patrimonios/{id} — RF07a (tela de detalhe)
  // -------------------------------------------------------------------------

  /// Detalhe de um bem.
  ///
  /// Um docente que tentar abrir um bem que não é dele recebe 403 e a
  /// Controller mostra a mensagem em vez de uma tela em branco.
  Future<PatrimonioModel> detalhe(int id) async {
    final json = await _api.get('/patrimonios/$id');
    return PatrimonioModel.fromJson(json);
  }

  // -------------------------------------------------------------------------
  // POST /patrimonios — RF07a (cadastro de bem)
  // -------------------------------------------------------------------------

  /// Cadastra um bem.
  ///
  /// A resposta do backend é enxuta — `message`, `patrimonioId`,
  /// `codigo`, `status` — e **não** traz o bem completo. Por isso o
  /// retorno é um [PatrimonioCriacaoModel], e quem chama decide se
  /// recarrega a lista ou já abre o detalhe pelo `id`.
  ///
  /// Falha com 409 quando o tombamento já existe e com 400 quando
  /// `codigo`/`nome` faltarem.
  Future<PatrimonioCriacaoModel> criar(PatrimonioModel patrimonio) async {
    final json = await _api.post('/patrimonios', body: patrimonio.toJson());
    return PatrimonioCriacaoModel.fromJson(json);
  }

  // -------------------------------------------------------------------------
  // PUT /patrimonios/{id} — RF07a (edição)
  // -------------------------------------------------------------------------

  /// Atualiza os dados de um bem.
  ///
  /// O `codigo` (tombamento) não é enviado: a API não o aceita no
  /// `UpdatePatrimonioRequest`, e mandá-lo seria fingir que dá para
  /// renumerar o acervo pelo formulário.
  Future<void> atualizar(int id, PatrimonioModel patrimonio) async {
    await _api.put(
      '/patrimonios/$id',
      body: patrimonio.toJsonAtualizacao(),
    );
  }

  // -------------------------------------------------------------------------
  // DELETE /patrimonios/{id} — RF07a (exclusão)
  // -------------------------------------------------------------------------

  /// Exclui um bem do acervo.
  ///
  /// Operação destrutiva e irreversível: a Controller deve pedir
  /// confirmação antes de chamar este método.
  Future<void> excluir(int id) async {
    await _api.delete('/patrimonios/$id');
  }

  // -------------------------------------------------------------------------
  // GET /admin/patrimonios/{id}/historico — RF07b (linha do tempo)
  // -------------------------------------------------------------------------
  //
  // O histórico pertence à camada de dados do Patrimônio e mora aqui
  // porque é o mesmo recurso: mesmo bem, mesmo endpoint base. Quem
  // desenha a linha do tempo é o Controller do ciclo de vida.

  /// Movimentações registradas de um bem, da mais recente para a mais
  /// antiga.
  Future<HistoricoPatrimonioModel> historico(int id) async {
    final json = await _api.get('/admin/patrimonios/$id/historico');
    return HistoricoPatrimonioModel.fromJson(json);
  }
}
