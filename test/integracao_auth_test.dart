// Teste de integração do módulo de Autenticação (Parte 2) contra a API real.
//
// Execução:
//   1) suba o backend:  .\api.exe
//   2) rode:            flutter test test\integracao_auth_test.dart
//
// Os testes são ignorados automaticamente se a API não estiver no ar,
// para o `flutter test` padrão não quebrar em uma máquina sem backend.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reserva_mobile/core/config/api_config.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/auth_requests.dart';
import 'package:reserva_mobile/models/professor_request.dart';

/// Verifica se a API está respondendo antes de rodar os testes.
Future<bool> _apiNoAr() async {
  try {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..options.connectTimeout = const Duration(seconds: 2);
    final resposta = await dio.get<dynamic>('/health');
    return resposta.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool online;
  late AuthService auth;
  late SessaoService sessao;
  late ApiClient api;

  setUpAll(() async {
    online = await _apiNoAr();
    if (!online) {
      // ignore: avoid_print
      print('API offline em ${ApiConfig.baseUrl} — testes de integração '
          'ignorados.');
    }
  });

  setUp(() async {
    sessao = SessaoService();
    // Usa o stack real (ApiClient + interceptors) para que o teste
    // cubra também a injeção do cabeçalho Authorization.
    api = ApiClient(sessao);
    api.onInit();
    auth = AuthService(api, sessao);
  });

  group('Integração — RF01 Login', () {
    test('credenciais válidas devolvem token e perfil de admin', () async {
      if (!online) { markTestSkipped('API offline'); return; }
      final resposta = await auth.login('admin@admin.com', 'admin123');
      expect(resposta.token, isNotEmpty);
      expect(resposta.refreshToken, isNotEmpty);
      expect(resposta.usuario.role, 'admin');
      expect(resposta.usuario.email, 'admin@admin.com');
    });

    test('senha errada devolve 401 com mensagem amigável', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      try {
        await auth.login('admin@admin.com', 'senha-errada');
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 401);
        expect(e.mensagem, isNotEmpty);
      }
    });

    test('a sessão é persistida com o token e o perfil', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      final resposta = await auth.login('admin@admin.com', 'admin123');
      await sessao.salvar(
        token: resposta.token,
        refreshToken: resposta.refreshToken,
        usuario: resposta.usuario,
      );
      expect(sessao.autenticado, isTrue);
      expect(sessao.usuario.value!.isAdmin, isTrue);
    });
  });

  group('Integração — RF02 Cadastro de Coordenador (RN01)', () {
    test('e-mail já cadastrado é rejeitado pelo backend', () async {
      if (!online) { markTestSkipped('API offline'); return; }
      try {
        await auth.cadastrarCoordenador(CadastroAdminRequestModel(
          nome: 'Coordenador Teste',
          email: 'admin@admin.com',
          senha: 'senha123',
        ));
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, anyOf(400, 409));
      }
    });
  });

  group('Integração — RF03 Recuperação de senha', () {
    test('solicitar código não revela se o e-mail existe', () async {
      if (!online) { markTestSkipped('API offline'); return; }
      final r = await auth.solicitarCodigo('naoexiste@escola.com');
      expect(r.mensagem, isNotEmpty);
    });

    test('código inválido é rejeitado com 400', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      try {
        await auth.verificarCodigo('admin@admin.com', '000000');
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 400);
      }
    });
  });

  group('Integração — RN03 professor é estritamente leitura', () {
    late String emailProfessor;

    setUp(() async {
      // 1) O admin cria o docente (RN02: cadastro centralizado).
      final sessaoAdmin = SessaoService();
      final apiAdmin = ApiClient(sessaoAdmin);
      apiAdmin.onInit();
      final loginAdmin = await AuthService(apiAdmin, sessaoAdmin)
          .login('admin@admin.com', 'admin123');
      await sessaoAdmin.salvar(
        token: loginAdmin.token,
        refreshToken: loginAdmin.refreshToken,
        usuario: loginAdmin.usuario,
      );

      emailProfessor =
          'prof.teste.${DateTime.now().millisecondsSinceEpoch}@escola.com';
      await apiAdmin.post(
        '/admin/professores',
        body: ProfessorRequestModel(
          nome: 'Prof. Teste RN03',
          email: emailProfessor,
          senha: 'prof123',
          matricula: 'PROF-TESTE',
        ).toJson(),
      );

      // 2) Loga com a sessão do docente.
      final resposta = await auth.login(emailProfessor, 'prof123');
      await sessao.salvar(
        token: resposta.token,
        refreshToken: resposta.refreshToken,
        usuario: resposta.usuario,
      );
    });

    test('login do docente devolve role professor', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      final r = await auth.login(emailProfessor, 'prof123');
      expect(r.usuario.role, 'professor');
      expect(r.usuario.isProfessor, isTrue);
      expect(r.usuario.isAdmin, isFalse);
    });

    test('escrita de patrimônio é bloqueada com 403', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      // O app do docente nunca oferece esta ação (RN03). Aqui provamos
      // que quem barra é o backend, com 403 e mensagem amigável.
      try {
        await api.post('/patrimonios', body: const {
          'tombamento': 'TOM-TESTE-403',
          'descricao': 'Item de teste',
          'categoria': 'Eletronicos',
          'marca': 'ACME',
        });
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 403);
        expect(e.mensagem, isNotEmpty);
      }
    });

    test('GET /patrimonios/meus responde 200 para o docente', () async {

      if (!online) { markTestSkipped('API offline'); return; }
      final lista = await api.get('/patrimonios/meus');
      expect(lista.containsKey('items'), isTrue);
    });
  });
}