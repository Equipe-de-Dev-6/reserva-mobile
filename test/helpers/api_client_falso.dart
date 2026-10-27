import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';

/// Dublê do [ApiClient] para testar Services e Controllers sem rede.
///
/// Só os verbos HTTP são sobrescritos; assim o Service exercita o seu
/// código de tradução Model ↔ JSON de verdade, e o que se verifica é
/// justamente a camada que o app controla. O interceptor de token e o
/// tratamento de erro do Dio ficam de fora — eles são cobertos pelo
/// teste de integração contra a API real.
class ApiClientFalso extends ApiClient {
  ApiClientFalso(this._responder) : super(SessaoService());

  /// Resposta para qualquer chamada: recebe método, caminho e corpo.
  final Future<Map<String, dynamic>> Function(String metodo, String caminho,
      Object? body) _responder;

  /// Tudo que foi solicitado, em ordem: `['GET /admin/professores', ...]`.
  final List<String> chamadas = [];

  /// Corpos das requisições, na mesma ordem de [chamadas].
  final List<Object?> corpos = [];

  @override
  Future<Map<String, dynamic>> get(String caminho,
          {Map<String, dynamic>? query}) =>
      _registrar('GET', caminho, null);

  @override
  Future<Map<String, dynamic>> post(String caminho,
          {Object? body, bool autenticado = true}) =>
      _registrar('POST', caminho, body);

  @override
  Future<Map<String, dynamic>> put(String caminho, {Object? body}) =>
      _registrar('PUT', caminho, body);

  @override
  Future<Map<String, dynamic>> patch(String caminho, {Object? body}) =>
      _registrar('PATCH', caminho, body);

  @override
  Future<Map<String, dynamic>> delete(String caminho) =>
      _registrar('DELETE', caminho, null);

  Future<Map<String, dynamic>> _registrar(
    String metodo,
    String caminho,
    Object? body,
  ) {
    chamadas.add('$metodo $caminho');
    corpos.add(body);
    return _responder(metodo, caminho, body);
  }
}

/// Dublê que sempre falha, para exercitar os caminhos de erro dos
/// Controllers (403 do docente, 404 do professor, 409 do e-mail
/// duplicado, falha de rede…).
class ApiClientComErro extends ApiClient {
  ApiClientComErro(this.erro) : super(SessaoService());

  final AppException erro;

  @override
  Future<Map<String, dynamic>> get(String caminho,
          {Map<String, dynamic>? query}) async =>
      throw erro;

  @override
  Future<Map<String, dynamic>> post(String caminho,
          {Object? body, bool autenticado = true}) async =>
      throw erro;

  @override
  Future<Map<String, dynamic>> put(String caminho, {Object? body}) async =>
      throw erro;

  @override
  Future<Map<String, dynamic>> patch(String caminho, {Object? body}) async =>
      throw erro;

  @override
  Future<Map<String, dynamic>> delete(String caminho) async => throw erro;
}

// ---------------------------------------------------------------------------
// Payloads copiados das respostas reais do backend
// ---------------------------------------------------------------------------

/// `GET /api/admin/professores`
Map<String, dynamic> payloadListaProfessores() => {
      'total': 2,
      'professores': [
        {
          'id': 2,
          'nome': 'Prof. Carlos Drummond',
          'email': 'professor@escola.com',
          'matricula': 'PROF-2024-01',
          'departamento': 'Língua Portuguesa e Literatura',
          'telefone': '(11) 98765-1001',
          'cpf': '',
          'role': 'professor',
          'adminId': 1,
          'totalPatrimonios': 3,
          'createdAt': '2026-09-22T16:48:21Z',
        },
        {
          'id': 3,
          'nome': 'Profa. Maria Silva',
          'email': 'maria.silva@escola.com',
          'matricula': 'PROF-2024-02',
          'departamento': 'Ciências e Biologia',
          'telefone': '(11) 98765-1002',
          'cpf': '',
          'role': 'professor',
          'adminId': 1,
          'totalPatrimonios': 1,
          'createdAt': '2026-09-22T16:48:21Z',
        },
      ],
    };

/// `GET /api/admin/professors/{id}`
Map<String, dynamic> payloadDetalheProfessor() => {
      'professor': (payloadListaProfessores()['professores'] as List).first,
      'patrimonios': [
        {
          'id': 3,
          'codigo': 'PAT-2024-003',
          'nome': 'Tablet Samsung Galaxy Tab A8',
          'descricao': 'Tela 10.5 pol, 64GB, Wi-Fi',
          'categoria': 'Informática',
          'marca': 'Samsung',
          'modelo': 'Galaxy Tab A8 SM-X200',
          'numeroSerie': 'SM-77112',
          'estadoConservacao': 'Excelente',
          'localizacao': 'Gabinete dos Professores',
          'status': 'em_uso',
          'adminId': 1,
          'professorId': 2,
          'responsavelId': 2,
          'professorNome': 'Prof. Carlos Drummond',
          'responsavelNome': 'Prof. Carlos Drummond',
          'professorEmail': 'professor@escola.com',
          'dataAtribuicao': '2026-09-22T16:48:21Z',
          'observacoes': '',
          'createdAt': '2026-09-22T16:48:21Z',
        },
        {
          'id': 2,
          'codigo': 'PAT-2024-002',
          'nome': 'Projetor Epson PowerLite E20',
          'descricao': 'Projetor 3LCD 3400 lumens',
          'categoria': 'Audiovisual',
          'marca': 'Epson',
          'modelo': 'PowerLite E20',
          'numeroSerie': 'EP-44120',
          'estadoConservacao': 'Bom',
          'localizacao': 'Sala de Aula 102 - Bloco A',
          'status': 'em_uso',
          'professorId': 2,
          'professorNome': 'Prof. Carlos Drummond',
          'dataAtribuicao': '2026-09-22T16:48:21Z',
        },
      ],
    };

/// `GET /api/profile`
Map<String, dynamic> payloadPerfil() => {
      'id': 2,
      'email': 'professor@escola.com',
      'nome': 'Prof. Carlos Drummond',
      'role': 'professor',
      'cpf': '',
      'telefone': '(11) 98765-1001',
      'matricula': 'PROF-2024-01',
      'departamento': 'Língua Portuguesa e Literatura',
      'dataNascimento': '',
      'genero': '',
      'cep': '',
      'endereco': '',
      'cidadeUf': '',
      'contatoEmergencia': '',
      'tipoSanguineo': '',
      'alergias': '',
      'totalPatrimonios': 3,
      'createdAt': '2026-09-22T16:48:21Z',
    };

/// `PUT /api/profile` — Atenção: nesta rota o backend devolve
/// `totalPatrimonios` zerado, o que é tratado no `PerfilController`.
Map<String, dynamic> payloadPerfilAtualizado() => {
      'message': 'Perfil atualizado com sucesso',
      'user': {...payloadPerfil(), 'telefone': '(11) 98888-7777', 'totalPatrimonios': 0},
    };

// ---------------------------------------------------------------------------
// Payloads da Parte 6 — Administração Geral
// ---------------------------------------------------------------------------

/// `GET /api/admin/users`
Map<String, dynamic> payloadListaUsuarios() => {
      'total': 3,
      'users': [
        {
          'id': 1,
          'email': 'admin@admin.com',
          'nome': 'Coordenador Geral',
          'role': 'admin',
          'matricula': 'ADM-2024-01',
          'departamento': 'Coordenação',
          'telefone': '(11) 98765-1000',
          'totalPatrimonios': 0,
          'createdAt': '2026-10-20T11:26:42Z',
        },
        {
          'id': 2,
          'email': 'professor@escola.com',
          'nome': 'Prof. Carlos Drummond',
          'role': 'professor',
          'matricula': 'PROF-2024-01',
          'departamento': 'Língua Portuguesa e Literatura',
          'telefone': '(11) 98765-1001',
          'totalPatrimonios': 3,
          'createdAt': '2026-10-20T11:26:42Z',
        },
        {
          'id': 3,
          'email': 'usuario@escola.com',
          'nome': 'Usuário Comum',
          'role': 'user',
          'matricula': '',
          'departamento': '',
          'telefone': '',
          'totalPatrimonios': 0,
          'createdAt': '2026-10-21T09:00:00Z',
        },
      ],
    };

/// `PATCH /api/admin/users/{id}/role` — resposta de sucesso
Map<String, dynamic> payloadAlterarPapel(int id, String novoPapel) => {
      'message': 'Role do usuário atualizada com sucesso',
      'newRole': novoPapel,
      'userId': id,
    };

/// `GET /api/admin/stats`
Map<String, dynamic> payloadStatsAdmin() => {
      'totalUsers': 9,
      'totalAdmins': 1,
      'totalProfessores': 8,
      'standardUsers': 0,
      'activeRefreshTokens': 41,
      'pendingResetCodes': 0,
    };

// ---------------------------------------------------------------------------
// Payloads da Parte 6 — Administração Geral
// ---------------------------------------------------------------------------

/// `GET /api/admin/users`
Map<String, dynamic> payloadListaUsuarios() => {
      'total': 3,
      'users': [
        {
          'id': 1,
          'email': 'admin@admin.com',
          'nome': 'Coordenador Geral',
          'role': 'admin',
          'matricula': 'ADM-2024-01',
          'departamento': 'Coordenação',
          'telefone': '(11) 98765-1000',
          'totalPatrimonios': 0,
          'createdAt': '2026-10-20T11:26:42Z',
        },
        {
          'id': 2,
          'email': 'professor@escola.com',
          'nome': 'Prof. Carlos Drummond',
          'role': 'professor',
          'matricula': 'PROF-2024-01',
          'departamento': 'Língua Portuguesa e Literatura',
          'telefone': '(11) 98765-1001',
          'totalPatrimonios': 3,
          'createdAt': '2026-10-20T11:26:42Z',
        },
        {
          'id': 3,
          'email': 'usuario@escola.com',
          'nome': 'Usuário Comum',
          'role': 'user',
          'matricula': '',
          'departamento': '',
          'telefone': '',
          'totalPatrimonios': 0,
          'createdAt': '2026-10-21T09:00:00Z',
        },
      ],
    };

/// `PATCH /api/admin/users/{id}/role` — resposta de sucesso
Map<String, dynamic> payloadAlterarPapel(int id, String novoPapel) => {
      'message': 'Role do usuário atualizada com sucesso',
      'newRole': novoPapel,
      'userId': id,
    };

/// `GET /api/admin/stats`
Map<String, dynamic> payloadStatsAdmin() => {
      'totalUsers': 9,
      'totalAdmins': 1,
      'totalProfessores': 8,
      'standardUsers': 0,
      'activeRefreshTokens': 41,
      'pendingResetCodes': 0,
    };
