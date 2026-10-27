import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/middleware.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/admin_usuarios_controller.dart';
import 'package:reserva_mobile/core/servicos/admin_service.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/admin_stats_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_admin_model.dart';
import 'package:reserva_mobile/views/admin/usuarios/usuarios_lista_view.dart';

import 'helpers/api_client_falso.dart';
import 'helpers/test_armazenamento.dart';

/// Testes da Parte 6 — Administração Geral (usuários do sistema).
///
/// Cobertura mínima exigida pelos critérios de aceitação:
///  * o Model lê o JSON real (role, totalPatrimonios, iniciais)
///  * o Service chama `GET /admin/users`
///  * o Service envia `{"role": "..."}` no `PATCH`
///  * o Controller filtra a busca
///  * erro 400 do backend vira mensagem (AppException tratada)
///  * a rota exige `AdminMiddleware` (RBAC)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;

  late ArmazenamentoFalso armazenamento;

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.parameters = {};
    Get.reset();
  });

  // =========================================================================
  // UsuarioAdminModel — leitura do JSON
  // =========================================================================
  group('UsuarioAdminModel', () {
    test('lê todos os campos do JSON real da API', () {
      final json = {
        'id': 2,
        'nome': 'Prof. Carlos Drummond',
        'email': 'professor@escola.com',
        'role': 'professor',
        'matricula': 'PROF-2024-01',
        'departamento': 'Língua Portuguesa e Literatura',
        'telefone': '(11) 98765-1001',
        'totalPatrimonios': 3,
        'createdAt': '2026-10-20T11:26:42Z',
      };
      final u = UsuarioAdminModel.fromJson(json);

      expect(u.id, 2);
      expect(u.nome, 'Prof. Carlos Drummond');
      expect(u.email, 'professor@escola.com');
      expect(u.role, 'professor');
      expect(u.matricula, 'PROF-2024-01');
      expect(u.departamento, 'Língua Portuguesa e Literatura');
      expect(u.telefone, '(11) 98765-1001');
      expect(u.totalPatrimonios, 3);
      expect(u.isAdmin, isFalse);
      expect(u.isProfessor, isTrue);
      expect(u.rotuloPapel, 'Professor');
      expect(u.iniciais, 'PD');
    });

    test('rotuloPapel traduz cada papel', () {
      expect(
        UsuarioAdminModel.fromJson({'role': 'admin'}).rotuloPapel,
        'Coordenador',
      );
      expect(
        UsuarioAdminModel.fromJson({'role': 'professor'}).rotuloPapel,
        'Professor',
      );
      expect(
        UsuarioAdminModel.fromJson({'role': 'user'}).rotuloPapel,
        'Usuário',
      );
    });

    test('campos ausentes usam valores padrão seguros', () {
      final u = UsuarioAdminModel.fromJson({'id': 9, 'email': 'a@b.com'});
      expect(u.nome, 'Sem nome');
      expect(u.role, 'user');
      expect(u.totalPatrimonios, 0);
      expect(u.iniciais, '?');
    });

    test('iniciais pega primeiro e último termo do nome', () {
      expect(
        UsuarioAdminModel.fromJson({'nome': 'Maria Silva Souza'}).iniciais,
        'MS',
      );
      expect(
        UsuarioAdminModel.fromJson({'nome': 'Ana'}).iniciais,
        'A',
      );
    });
  });

  // =========================================================================
  // AdminStatsModel — leitura do JSON
  // =========================================================================
  group('AdminStatsModel', () {
    test('lê todas as métricas do sistema', () {
      final json = {
        'totalUsers': 9,
        'totalAdmins': 1,
        'totalProfessores': 8,
        'standardUsers': 0,
        'activeRefreshTokens': 41,
        'pendingResetCodes': 0,
      };
      final s = AdminStatsModel.fromJson(json);

      expect(s.totalUsers, 9);
      expect(s.totalAdmins, 1);
      expect(s.totalProfessores, 8);
      expect(s.standardUsers, 0);
      expect(s.activeRefreshTokens, 41);
      expect(s.pendingResetCodes, 0);
      expect(s.sistemaVazio, isFalse);
    });

    test('valores ausentes viram zero', () {
      final s = AdminStatsModel.fromJson({});
      expect(s.totalUsers, 0);
      expect(s.sistemaVazio, isTrue);
    });
  });

  // =========================================================================
  // AdminService — chamadas à API
  // =========================================================================
  group('AdminService', () {
    test('listarUsuarios() chama GET /admin/users e desempacota o envelope',
        () async {
      final api = ApiClientFalso((_, _, _) async => payloadListaUsuarios());
      final service = AdminService(api);

      final usuarios = await service.listarUsuarios();

      expect(api.chamadas, ['GET /admin/users']);
      expect(usuarios.length, 3);
      expect(usuarios.first.id, 1);
      expect(usuarios.first.role, 'admin');
      expect(usuarios[1].role, 'professor');
      expect(usuarios[2].role, 'user');
    });

    test('listarUsuarios() devolve lista vazia quando não há users', () async {
      final api = ApiClientFalso((_, _, _) async => {'total': 0});
      final service = AdminService(api);

      expect(await service.listarUsuarios(), isEmpty);
    });

    test('alterarPapel() chama PATCH /admin/users/{id}/role com o corpo',
        () async {
      var corpoEnviado;
      final api = ApiClientFalso((metodo, caminho, body) async {
        corpoEnviado = body;
        return payloadAlterarPapel(2, 'admin');
      });
      final service = AdminService(api);

      await service.alterarPapel(2, 'admin');

      expect(api.chamadas, ['PATCH /admin/users/2/role']);
      expect(corpoEnviado, {'role': 'admin'});
    });

    test('estatisticas() chama GET /admin/stats', () async {
      final api =
          ApiClientFalso((_, _, _) async => payloadStatsAdmin());
      final service = AdminService(api);

      final stats = await service.estatisticas();

      expect(api.chamadas, ['GET /admin/stats']);
      expect(stats.totalUsers, 9);
      expect(stats.activeRefreshTokens, 41);
    });

    test('erro 403 de alterarPapel vira AppException', () async {
      final api = ApiClientComErro(
        const AppException('Acesso negado.', statusCode: 403),
      );
      final service = AdminService(api);

      await expectLater(
        service.alterarPapel(99, 'admin'),
        throwsA(isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  // =========================================================================
  // AdminUsuariosController — busca e alteração de papel
  // =========================================================================
  group('AdminUsuariosController', () {
    test('carrega a lista e calcula indicadores', () async {
      final api = ApiClientFalso((_, _, _) async => payloadListaUsuarios());
      final controller =
          AdminUsuariosController(AdminService(api));
      await controller.carregar();

      expect(controller.usuarios.length, 3);
      expect(controller.totalUsuarios, 3);
      expect(controller.totalAdmins, 1);
      expect(controller.totalProfessores, 1);
      expect(controller.carregando.value, isFalse);
      expect(controller.erro.value, isEmpty);
    });

    test('a busca filtra por nome, e-mail, matrícula, departamento e telefone',
        () async {
      final api = ApiClientFalso((_, _, _) async => payloadListaUsuarios());
      final controller =
          AdminUsuariosController(AdminService(api));
      await controller.carregar();

      controller.filtrar('carlos');
      expect(controller.resultados.length, 1);
      expect(controller.resultados.first.nome, 'Prof. Carlos Drummond');

      controller.filtrar('PROF-2024-01');
      expect(controller.resultados.length, 1);

      controller.filtrar('Coordenação');
      expect(controller.resultados.length, 1);

      controller.filtrar('98765-1000');
      expect(controller.resultados.length, 1);

      controller.filtrar('');
      expect(controller.resultados.length, 3);
    });

    test('buscaSemResultado distingue "sem usuário" de "sem resultado"',
        () async {
      final controller =
          AdminUsuariosController(AdminService(
            ApiClientFalso((_, _, _) async => payloadListaUsuarios()),
          ));
      await controller.carregar();
      controller.filtrar('zzz');
      expect(controller.buscaSemResultado, isTrue);

      final vazia = AdminUsuariosController(
        AdminService(ApiClientFalso((_, _, _) async => {'total': 0})),
      );
      await vazia.carregar();
      expect(vazia.buscaSemResultado, isFalse);
    });

    test('alterarPapel retorna true quando dá certo', () async {
      final api = ApiClientFalso(
          (_, _, _) async => payloadAlterarPapel(2, 'admin'));
      final controller =
          AdminUsuariosController(AdminService(api));

      final ok = await controller.alterarPapel(2, 'admin');

      expect(ok, isTrue);
      expect(api.chamadas, ['PATCH /admin/users/2/role']);
      expect(controller.erro.value, isEmpty);
    });

    test('alterarPapel retorna false e guarda a mensagem em caso de erro',
        () async {
      final api = ApiClientComErro(
        const AppException('Role inválida.', statusCode: 400),
      );
      final controller =
          AdminUsuariosController(AdminService(api));

      final ok = await controller.alterarPapel(2, 'invalido');

      expect(ok, isFalse);
      expect(controller.erro.value, 'Role inválida.');
    });

    test('erro de carregamento fica em erro e lista vazia', () async {
      final controller = AdminUsuariosController(
        AdminService(
          ApiClientComErro(
            const AppException('Servidor indisponível.', statusCode: 500),
          ),
        ),
      );
      await controller.carregar();

      expect(controller.erro.value, 'Servidor indisponível.');
      expect(controller.usuarios, isEmpty);
      expect(controller.carregando.value, isFalse);
    });
  });

  // =========================================================================
  // View — caminho completo (busca exibe resultado)
  // =========================================================================
  group('UsuariosListaView', () {
    testWidgets('exibe a lista de usuários com avatar, nome, papel e botão de edição',
        (tester) async {
      final api = ApiClientFalso((_, _, _) async => payloadListaUsuarios());

      Get.put<ApiClient>(api, permanent: true);
      Get.put<AdminService>(AdminService(api), permanent: true);
      Get.put<AdminUsuariosController>(
        AdminUsuariosController(Get.find<AdminService>()),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: Tema.claro,
          home: const UsuariosListaView(),
        ),
      );
      await tester.pump();

      expect(find.text('Coordenador Geral'), findsOneWidget);
      expect(find.text('Prof. Carlos Drummond'), findsOneWidget);
      expect(find.text('Usuário Comum'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));
    });

    testWidgets('busca filtra a lista na tela', (tester) async {
      final api = ApiClientFalso((_, _, _) async => payloadListaUsuarios());

      Get.put<ApiClient>(api, permanent: true);
      Get.put<AdminService>(AdminService(api), permanent: true);
      Get.put<AdminUsuariosController>(
        AdminUsuariosController(Get.find<AdminService>()),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: Tema.claro,
          home: const UsuariosListaView(),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Buscar usuário'),
        'carlos',
      );
      await tester.pump();

      expect(find.text('Prof. Carlos Drummond'), findsOneWidget);
      expect(find.text('Coordenador Geral'), findsNothing);
      expect(find.text('Usuário Comum'), findsNothing);
    });
  });

  // =========================================================================
  // RBAC — a rota exige sessão e papel de admin
  // =========================================================================
  group('RBAC da rota de usuários', () {
    test('AdminMiddleware libera o admin', () {
      final sessao = Get.put(SessaoService());
      loginEmMemoria(sessao, adminDeTeste());
      expect(AdminMiddleware().redirect(Rotas.usuarios), isNull);
    });

    test('AdminMiddleware devolve o docente ao próprio painel', () {
      final sessao = Get.put(SessaoService());
      loginEmMemoria(sessao, professorDeTeste());
      expect(
        AdminMiddleware().redirect(Rotas.usuarios)?.name,
        Rotas.homeProfessor,
      );
    });

    test('AdminMiddleware manda quem não tem sessão para o login', () {
      Get.put(SessaoService());
      expect(AdminMiddleware().redirect(Rotas.usuarios)?.name, Rotas.login);
    });

    test('a rota de usuários declara AutenticadoMiddleware e AdminMiddleware',
        () {
      final paginaPor = {for (final p in AppRotas.paginas) p.name: p};
      final pagina = paginaPor[Rotas.usuarios]!;
      expect(pagina, isNotNull, reason: 'a rota ${Rotas.usuarios} precisa existir');
      expect(
        pagina.middlewares!.any((m) => m is AutenticadoMiddleware),
        isTrue,
        reason: '${Rotas.usuarios} exige sessão',
      );
      expect(
        pagina.middlewares!.any((m) => m is AdminMiddleware),
        isTrue,
        reason: '${Rotas.usuarios} exige role admin',
      );
    });
  });
}

/// Usuário do Coordenador (reutiliza a mesma ajuda do varredura_telas).
UsuarioModel adminDeTeste() => UsuarioModel(
      id: 1,
      nome: 'Coordenador Geral',
      email: 'admin@admin.com',
      role: 'admin',
    );

/// Usuário docente.
UsuarioModel professorDeTeste() => UsuarioModel(
      id: 2,
      nome: 'Prof. Carlos Drummond',
      email: 'professor@escola.com',
      role: 'professor',
    );

/// Simula login em memória (sem disco), reutilizando a assinatura do
/// `test_armazenamento.dart` mas com nomes locais para evitar import
/// circular de helpers.
void loginEmMemoria(SessaoService sessao, UsuarioModel usuario) {
  sessao.token.value = 'token-de-teste';
  sessao.refreshToken.value = 'refresh-de-teste';
  sessao.usuario.value = usuario;
}
