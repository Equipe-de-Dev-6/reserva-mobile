// Testes do **módulo de autenticação** (RF01–RF04) — o "Escopo Base"
// que vale 50 pontos na régua de avaliação.
//
// A cobertura mostrava este módulo como o mais fraco do projeto:
// `auth_requests.dart` e `auth_resposta.dart` estavam com **0%** e o
// `auth_service.dart` com 4%. Ou seja: o coração do app — de onde sai o
// token, para onde ele vai e como a sessão é montada — não tinha
// nenhuma rede de segurança.
//
// Este arquivo cobre, camada por camada:
//   * os **Models** (o JSON que entra e sai);
//   * o **Service** (a rota, o corpo e o que é público);
//   * o **Controller** (as regras da tela: login, cadastro, recuperação
//     de senha em 3 etapas e logout).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/controllers/auth_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/auth_requests.dart';
import 'package:reserva_mobile/models/auth_resposta.dart';
import 'package:reserva_mobile/models/usuario_model.dart';

import 'helpers/api_client_falso.dart';
import 'helpers/test_armazenamento.dart';

/// Resposta de login no formato exato do backend.
Map<String, dynamic> payloadDeLogin({
  String role = 'admin',
  String email = 'admin@escola.com',
}) => {
      'token': 'jwt-de-teste',
      'refreshToken': 'refresh-de-teste',
      'expiresIn': 900,
      'tokenType': 'Bearer',
      'user': {
        'id': 1,
        'email': email,
        'nome': 'Coordenador Geral',
        'role': role,
        'departamento': 'Coordenação',
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArmazenamentoFalso armazenamento;

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  // =========================================================================
  group('Models de requisição — o JSON que sai para a API', () {
    test('LoginRequestModel envia "password" (não "senha")', () {
      // O Swagger chama de `password`; mandar `senha` faria a API
      // recusar o login.
      final json = LoginRequestModel(email: '  a@b.com ', senha: 'abc123')
          .toJson();

      expect(json, {'email': 'a@b.com', 'password': 'abc123'});
    });

    test('CadastroAdminRequestModel não manda "role" (RN01)', () {
      // RN01: o auto-cadastro cria **exclusivamente** Coordenador. Se o
      // corpo mandasse `role`, o backend poderia aceitar "professor".
      final json = CadastroAdminRequestModel(
        nome: ' Coordenador ',
        email: ' c@e.com ',
        senha: 'abc123',
        departamento: ' Coord ',
        telefone: ' (11) 90000-0000 ',
        cpf: ' 111.222.333-44 ',
      ).toJson();

      expect(json.containsKey('role'), isFalse,
          reason: 'o app não pode escolher o papel do usuário');
      expect(json['nome'], 'Coordenador');
      expect(json['email'], 'c@e.com');
      expect(json['password'], 'abc123');
      expect(json['departamento'], 'Coord');
      expect(json['telefone'], '(11) 90000-0000');
      expect(json['cpf'], '111.222.333-44');
    });

    test('RefreshTokenRequestModel manda o refreshToken', () {
      expect(
        RefreshTokenRequestModel(refreshToken: 'abc').toJson(),
        {'refreshToken': 'abc'},
      );
    });

    test('SolicitarCodigoRequestModel manda o e-mail', () {
      expect(
        SolicitarCodigoRequestModel(email: ' a@b.com ').toJson(),
        {'email': 'a@b.com'},
      );
    });

    test('VerificarCodigoRequestModel manda "code" (não "codigo")', () {
      expect(
        VerificarCodigoRequestModel(email: 'a@b.com', codigo: '123456')
            .toJson(),
        {'email': 'a@b.com', 'code': '123456'},
      );
    });

    test('RedefinirSenhaRequestModel manda "newPassword"', () {
      expect(
        RedefinirSenhaRequestModel(
          email: 'a@b.com',
          codigo: '123456',
          novaSenha: 'nova123',
        ).toJson(),
        {'email': 'a@b.com', 'code': '123456', 'newPassword': 'nova123'},
      );
    });
  });

  // =========================================================================
  group('AuthRespostaModel — a leitura da resposta do login', () {
    test('lê o formato normal do backend', () {
      final resposta = AuthRespostaModel.fromJson(payloadDeLogin());

      expect(resposta.token, 'jwt-de-teste');
      expect(resposta.refreshToken, 'refresh-de-teste');
      expect(resposta.expiresIn, 900);
      expect(resposta.tokenType, 'Bearer');
      expect(resposta.usuario.role, 'admin');
      expect(resposta.usuario.email, 'admin@escola.com');
    });

    test('aceita "access_token" como alias de "token"', () {
      // Blindagem: o backend pode mudar o nome do campo sem quebrar o
      // app.
      final resposta = AuthRespostaModel.fromJson({
        'access_token': 'jwt-alias',
        'refresh_token': 'refresh-alias',
        'user': {'id': 1, 'email': 'a@b.com', 'nome': 'A', 'role': 'professor'},
      });

      expect(resposta.token, 'jwt-alias');
      expect(resposta.refreshToken, 'refresh-alias');
      expect(resposta.usuario.role, 'professor');
    });

    test('aceita "usuario" como alias de "user"', () {
      final resposta = AuthRespostaModel.fromJson({
        'token': 'jwt',
        'usuario': {'id': 1, 'email': 'a@b.com', 'nome': 'A', 'role': 'admin'},
      });

      expect(resposta.usuario.email, 'a@b.com');
      expect(resposta.usuario.isAdmin, isTrue);
    });

    test('resposta incompleta não quebra (valores vazios)', () {
      final resposta = AuthRespostaModel.fromJson(const {});

      expect(resposta.token, isEmpty);
      expect(resposta.refreshToken, isEmpty);
      expect(resposta.expiresIn, 0);
      expect(resposta.usuario.email, isEmpty);
    });
  });

  // =========================================================================
  group('AuthService — as rotas do módulo (RF01–RF04)', () {
    late ApiClientFalso api;
    late AuthService service;

    setUp(() {
      api = ApiClientFalso((_, _, _) async => payloadDeLogin());
      service = AuthService(api, SessaoService());
    });

    test('login() chama POST /auth/login', () async {
      await service.login('admin@escola.com', 'admin123');

      expect(api.chamadas, ['POST /auth/login']);
      expect(api.corpos.last, {
        'email': 'admin@escola.com',
        'password': 'admin123',
      });
    });

    test('login() devolve a resposta já convertida em Model', () async {
      final resposta = await service.login('admin@escola.com', 'admin123');

      expect(resposta.token, 'jwt-de-teste');
      expect(resposta.usuario.isAdmin, isTrue);
    });

    test('cadastrarCoordenador() chama POST /auth/register', () async {
      await service.cadastrarCoordenador(
        CadastroAdminRequestModel(
          nome: 'Coordenador',
          email: 'c@e.com',
          senha: 'abc123',
        ),
      );

      expect(api.chamadas, ['POST /auth/register']);
    });

    test('solicitarCodigo() chama POST /auth/forgot-password', () async {
      await service.solicitarCodigo('admin@escola.com');

      expect(api.chamadas, ['POST /auth/forgot-password']);
      expect(api.corpos.last, {'email': 'admin@escola.com'});
    });

    test('verificarCodigo() chama POST /auth/verify-code', () async {
      await service.verificarCodigo('admin@escola.com', '123456');

      expect(api.chamadas, ['POST /auth/verify-code']);
      expect(api.corpos.last, {'email': 'admin@escola.com', 'code': '123456'});
    });

    test('redefinirSenha() chama POST /auth/reset-password', () async {
      await service.redefinirSenha(
        email: 'admin@escola.com',
        codigo: '123456',
        novaSenha: 'nova123',
      );

      expect(api.chamadas, ['POST /auth/reset-password']);
      expect(api.corpos.last, {
        'email': 'admin@escola.com',
        'code': '123456',
        'newPassword': 'nova123',
      });
    });

    test('logout() chama POST /auth/logout com o refresh token', () async {
      final sessao = SessaoService();
      sessao.refreshToken.value = 'refresh-salvo';
      final comSessao = AuthService(api, sessao);

      await comSessao.logout();

      expect(api.chamadas, ['POST /auth/logout']);
      expect(api.corpos.last, {'refreshToken': 'refresh-salvo'});
    });

    test('logout() sem refresh token não chama a API', () async {
      await service.logout();

      expect(api.chamadas, isEmpty,
          reason: 'sem token para revogar, não há o que fazer');
    });
  });

  // =========================================================================
  group('AuthController — as regras da tela (RF01–RF04)', () {
    late ApiClientFalso api;
    late SessaoService sessao;
    late AuthController controller;

    /// Monta o Controller com a sessão já registrada (o app real faz o
    /// mesmo pelo `MainBinding`).
    void montar({Map<String, dynamic>? respostaLogin}) {
      api = ApiClientFalso(
        (_, caminho, _) async => respostaLogin ?? payloadDeLogin(),
      );
      sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      Get.put<ApiClient>(api, permanent: true);
      controller = Get.put<AuthController>(
        AuthController(AuthService(api, sessao)),
      );
    }

    /// Formulário de verdade, para o `FormState` que o Controller exige.
    Future<FormState> formState(WidgetTester tester) async {
      final chave = GlobalKey<FormState>();
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Form(key: chave, child: const SizedBox.shrink()),
          ),
        ),
      );
      return chave.currentState!;
    }

    testWidgets('login com sucesso grava a sessão e vai para o painel',
        (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.emailCtrl.text = 'admin@escola.com';
      controller.senhaCtrl.text = 'admin123';

      await controller.login(formulario);

      expect(controller.erro.value, isEmpty);
      expect(sessao.token.value, 'jwt-de-teste');
      expect(sessao.refreshToken.value, 'refresh-de-teste');
      expect(sessao.usuario.value!.isAdmin, isTrue);
      expect(sessao.autenticado, isTrue);
    });

    testWidgets('login com e-mail inválido nem chama a API',
        (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.emailCtrl.text = 'nao-e-email';
      controller.senhaCtrl.text = 'admin123';

      await controller.login(formulario);

      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, 'Informe um e-mail válido.');
    });

    testWidgets('login com senha curta nem chama a API', (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.emailCtrl.text = 'admin@escola.com';
      controller.senhaCtrl.text = '123';

      await controller.login(formulario);

      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, contains('6 caracteres'));
    });

    testWidgets('erro do backend aparece na tela', (tester) async {
      final apiQueFalha = ApiClientFalso((_, _, _) async {
        throw const AppException('E-mail ou senha incorretos.', statusCode: 401);
      });
      sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      Get.put<ApiClient>(apiQueFalha, permanent: true);
      controller =
          Get.put<AuthController>(AuthController(AuthService(apiQueFalha, sessao)));
      final formulario = await formState(tester);

      controller.emailCtrl.text = 'admin@escola.com';
      controller.senhaCtrl.text = 'admin123';

      await controller.login(formulario);

      expect(controller.erro.value, 'E-mail ou senha incorretos.');
      expect(sessao.autenticado, isFalse,
          reason: 'login falhou — não pode haver sessão');
    });

    testWidgets('cadastro de coordenador cria e volta ao login',
        (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.nomeCtrl.text = 'Coordenador Geral';
      controller.cadastroEmailCtrl.text = 'novo@escola.com';
      controller.cadastroSenhaCtrl.text = 'abc123';
      controller.confirmarSenhaCtrl.text = 'abc123';

      await controller.cadastrarCoordenador(formulario);

      expect(api.chamadas.first, 'POST /auth/register');
      expect(controller.erro.value, isEmpty);
    });

    testWidgets('cadastro com senhas diferentes é barrado', (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.nomeCtrl.text = 'Coordenador Geral';
      controller.cadastroEmailCtrl.text = 'novo@escola.com';
      controller.cadastroSenhaCtrl.text = 'abc123';
      controller.confirmarSenhaCtrl.text = 'abcdef';

      await controller.cadastrarCoordenador(formulario);

      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, 'As senhas não conferem.');
    });

    testWidgets('recuperação de senha: as 3 etapas em sequência',
        (tester) async {
      montar();
      final formulario = await formState(tester);

      // Etapa 1 — pedir o código.
      controller.recuperacaoEmailCtrl.text = 'admin@escola.com';
      await controller.solicitarCodigo(formulario);

      expect(api.chamadas.first, 'POST /auth/forgot-password');
      expect(controller.etapaRecuperacao.value, 1);
      expect(controller.aviso.value, isNotEmpty);

      // Etapa 2 — validar o código.
      controller.codigoCtrl.text = '123456';
      await controller.verificarCodigo(formulario);

      expect(api.chamadas[1], 'POST /auth/verify-code');
      expect(controller.etapaRecuperacao.value, 2);

      // Etapa 3 — definir a nova senha.
      controller.novaSenhaCtrl.text = 'nova123';
      controller.novaSenhaConfirmarCtrl.text = 'nova123';
      await controller.redefinirSenha(formulario);

      expect(api.chamadas[2], 'POST /auth/reset-password');
      // Depois de redefinir, o formulário volta ao começo.
      expect(controller.etapaRecuperacao.value, 0);
      expect(controller.codigoCtrl.text, isEmpty);
    });

    testWidgets('etapa 2 com código curto é barrado', (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.codigoCtrl.text = '123';
      await controller.verificarCodigo(formulario);

      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, 'O código tem 6 dígitos.');
    });

    testWidgets('voltar uma etapa mantém o e-mail digitado', (tester) async {
      montar();
      final formulario = await formState(tester);

      controller.recuperacaoEmailCtrl.text = 'admin@escola.com';
      await controller.solicitarCodigo(formulario);
      expect(controller.etapaRecuperacao.value, 1);

      controller.etapaAnterior();

      expect(controller.etapaRecuperacao.value, 0);
      expect(controller.recuperacaoEmailCtrl.text, 'admin@escola.com');
    });

    testWidgets('logout limpa a sessão mesmo se a API falhar',
        (tester) async {
      final apiQueFalha = ApiClientFalso((_, _, _) async {
        throw const AppException('servidor fora do ar');
      });
      sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      Get.put<ApiClient>(apiQueFalha, permanent: true);
      controller =
          Get.put<AuthController>(AuthController(AuthService(apiQueFalha, sessao)));

      // Sessão ativa antes do logout.
      await sessao.salvar(
        token: 'jwt',
        refreshToken: 'refresh',
        usuario: UsuarioModel(
          id: 1,
          nome: 'Coordenador',
          email: 'admin@escola.com',
          role: 'admin',
        ),
      );
      expect(sessao.autenticado, isTrue);

      await controller.logout();

      // O logout local é obrigatório, mesmo com a API fora do ar.
      expect(sessao.autenticado, isFalse);
      expect(sessao.token.value, isEmpty);
      expect(sessao.refreshToken.value, isEmpty);
      expect(sessao.usuario.value, isNull);
    });
  });

  // =========================================================================
  group('Validações do Controller (expostas para as Views)', () {
    late AuthController controller;

    setUp(() {
      controller = Get.put<AuthController>(
        AuthController(AuthService(ApiClientFalso((_, _, _) async => {}), SessaoService())),
      );
    });

    test('e-mail', () {
      expect(controller.validarEmailLogin(null), 'Informe um e-mail.');
      expect(controller.validarEmailLogin('abc'), 'Informe um e-mail válido.');
      expect(controller.validarEmailLogin('a@b.com'), isNull);
    });

    test('senha com mínimo de 6 caracteres', () {
      expect(controller.validarSenhaLogin(''), 'Informe a senha.');
      expect(controller.validarSenhaLogin('123'),
          'A senha deve ter ao menos 6 caracteres.');
      expect(controller.validarSenhaLogin('123456'), isNull);
    });

    test('nome obrigatório', () {
      expect(controller.validarNome('  '), 'Informe o nome.');
      expect(controller.validarNome('Ana'), isNull);
    });

    test('confirmação de senha', () {
      controller.cadastroSenhaCtrl.text = 'abc123';
      expect(controller.validarConfirmacao('abc123'), isNull);
      expect(controller.validarConfirmacao('xyz'), 'As senhas não conferem.');
    });

    test('CPF: 11 dígitos, qualquer combinação', () {
      expect(controller.validarCpf('   '), isNull, reason: 'é opcional');
      expect(controller.validarCpf('123'), 'CPF deve ter 11 dígitos.');
      expect(controller.validarCpf('111.222.333-44'), isNull);
      expect(controller.validarCpf('000.000.000-00'), isNull);
    });

    test('telefone: de 8 a 15 dígitos', () {
      expect(controller.validarTelefone(''), isNull, reason: 'é opcional');
      expect(controller.validarTelefone('1234567'),
          'Telefone deve ter de 8 a 15 dígitos.');
      expect(controller.validarTelefone('11987654321'), isNull);
      expect(controller.validarTelefone('+5511987654321'), isNull);
    });

    test('código de validação com 6 dígitos', () {
      expect(controller.validarCodigo(''), 'Informe o código.');
      expect(controller.validarCodigo('123'), 'O código tem 6 dígitos.');
      expect(controller.validarCodigo('123456'), isNull);
    });

    test('nova senha com o mínimo exigido', () {
      expect(controller.validarNovaSenha('123'), contains('6 caracteres'));
      expect(controller.validarNovaSenha('123456'), isNull);
    });

    test('confirmação da nova senha', () {
      controller.novaSenhaCtrl.text = 'abc123';
      expect(controller.validarConfirmacaoNovaSenha('abc123'), isNull);
      expect(controller.validarConfirmacaoNovaSenha('xyz'),
          'As senhas não conferem.');
    });
  });
}
