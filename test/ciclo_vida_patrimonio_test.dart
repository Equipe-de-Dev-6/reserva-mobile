// Testes dos módulos implementados na fase final: dashboard de
// indicadores (RF05), ciclo de vida do bem (RF07b) e "Meus Patrimonies"
// do docente (RF08).
//
// Nenhum teste depende do backend: o `ApiClientFalso` devolve payloads
// no mesmo formato do Swagger, e o que se verifica é a camada que o
// app controla — a montagem da rota, do corpo e o tratamento do
// resultado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/controllers/dashboard_controller.dart';
import 'package:reserva_mobile/controllers/meus_patrimonios_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_ciclo_vida_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_historico_controller.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/professor_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/patrimonio_stats_model.dart';
import 'package:reserva_mobile/models/professor_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';

import 'helpers/api_client_falso.dart';

/// Payload real de `GET /admin/patrimonios/stats`.
Map<String, dynamic> payloadStats() => {
      'totalPatrimonios': 8,
      'patrimoniosEmUso': 5,
      'patrimoniosDisponiveis': 2,
      'patrimoniosEmManutencao': 1,
      'totalProfessores': 4,
      'totalProfessoresComPatrimonios': 3,
      'porCategoria': {
        'Informática': 3,
        'Audiovisual': 2,
        'Laboratório': 1,
        'Eletrônicos': 2,
      },
    };

/// Um bem vinculado a um docente, como o backend devolve.
Map<String, dynamic> payloadBemEmUso({int id = 7}) => {
      'id': id,
      'codigo': 'PAT-2024-007',
      'nome': 'Notebook Dell Latitude 3420',
      'descricao': 'i5, 16GB, SSD 512GB',
      'categoria': 'Informática',
      'marca': 'Dell',
      'modelo': 'Latitude 3420',
      'numeroSerie': 'DL-992831',
      'estadoConservacao': 'Excelente',
      'localizacao': 'Gabinete dos Professores - Mesa 04',
      'status': 'em_uso',
      'professorId': 2,
      'professorNome': 'Prof. Carlos Drummond',
      'professorEmail': 'professor@escola.com',
      'dataAtribuicao': '2026-09-14T20:00:00Z',
      'observacoes': '',
      'createdAt': '2026-09-14T19:00:00Z',
      'updatedAt': '2026-09-14T20:00:00Z',
    };

/// Resposta de `GET /admin/patrimonios/{id}/historico`.
Map<String, dynamic> payloadHistorico() => {
      'patrimonioId': 7,
      'total': 2,
      'historico': [
        {
          'id': 2,
          'patrimonioId': 7,
          'professorId': 2,
          'professorNome': 'Prof. Carlos Drummond',
          'adminId': 1,
          'adminNome': 'Coordenador Geral (Admin)',
          'acao': 'atribuicao',
          'motivo': 'Termo de responsabilidade assinado',
          'dataRegistro': '2026-09-14T20:00:00Z',
        },
        {
          'id': 1,
          'patrimonioId': 7,
          'professorId': null,
          'professorNome': null,
          'adminId': 1,
          'adminNome': 'Coordenador Geral (Admin)',
          'acao': 'criacao',
          'motivo': 'Cadastro inicial do bem',
          'dataRegistro': '2026-09-10T14:00:00Z',
        },
      ],
    };

/// Um `FormState` de verdade, com um formulário vazio.
Future<FormState> formStateDeTeste(WidgetTester tester) async {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  // =========================================================================
  group('PatrimonioStatsModel — indicadores (RF05)', () {
    test('lê todos os contadores do backend', () {
      final stats = PatrimonioStatsModel.fromJson(payloadStats());

      expect(stats.totalPatrimonios, 8);
      expect(stats.patrimoniosEmUso, 5);
      expect(stats.patrimoniosDisponiveis, 2);
      expect(stats.patrimoniosEmManutencao, 1);
      expect(stats.totalProfessores, 4);
      expect(stats.totalProfessoresComPatrimonios, 3);
    });

    test('as categorias vêm agrupadas por categoria', () {
      final stats = PatrimonioStatsModel.fromJson(payloadStats());

      expect(stats.porCategoria.length, 4);
      expect(stats.porCategoria['Informática'], 3);
    });

    test('as categorias são ordenadas da maior para a menor', () {
      final stats = PatrimonioStatsModel.fromJson(payloadStats());

      // Informática (3) primeiro; as três com 2 em ordem alfabética.
      expect(stats.categoriasOrdenadas.first.key, 'Informática');
      expect(
        stats.categoriasOrdenadas.map((e) => e.key).toList(),
        ['Informática', 'Audiovisual', 'Eletrônicos', 'Laboratório'],
      );
    });

    test('a barra de cada categoria é proporcional à maior', () {
      final stats = PatrimonioStatsModel.fromJson(payloadStats());

      expect(stats.percentualDe('Informática'), 1);
      expect(stats.percentualDe('Laboratório'), closeTo(1 / 3, 0.001));
      // Categoria inexistente não divide por zero.
      expect(stats.percentualDe('Inexistente'), 0);
    });

    test('acervo vazio é reconhecido', () {
      final stats = PatrimonioStatsModel.fromJson(const {});
      expect(stats.acervoVazio, isTrue);
      expect(stats.categoriasOrdenadas, isEmpty);
      expect(stats.percentualDe('Informática'), 0);
    });
  });

  // =========================================================================
  group('PatrimonioService — endpoints novos (RF05/RF07b/RF08)', () {
    late ApiClientFalso api;
    late PatrimonioService service;

    setUp(() {
      api = ApiClientFalso((metodo, caminho, _) async {
        if (caminho == '/admin/patrimonios/stats') return payloadStats();
        if (caminho == '/patrimonios/meus') {
          return {'total': 1, 'role': 'professor', 'items': [payloadBemEmUso()]};
        }
        if (caminho.endsWith('/historico')) return payloadHistorico();
        return <String, dynamic>{};
      });
      service = PatrimonioService(api);
    });

    test('estatisticas() chama GET /admin/patrimonios/stats', () async {
      final stats = await service.estatisticas();

      expect(api.chamadas, ['GET /admin/patrimonios/stats']);
      expect(stats.totalPatrimonios, 8);
    });

    test('meus() chama GET /patrimonios/meus e devolve os bens', () async {
      final bens = await service.meus();

      expect(api.chamadas, ['GET /patrimonios/meus']);
      expect(bens, hasLength(1));
      expect(bens.first.codigo, 'PAT-2024-007');
      expect(bens.first.professorNome, 'Prof. Carlos Drummond');
    });

    test('atribuir() envia o professorId no corpo (RN05)', () async {
      await service.atribuir(7, 2, observacoes: 'Termo assinado');

      expect(api.chamadas, ['POST /admin/patrimonios/7/atribuir']);
      expect(api.corpos.last, {
        'professorId': 2,
        'observacoes': 'Termo assinado',
      });
    });

    test('desatribuir() envia o motivo da devolução (RN05)', () async {
      await service.desatribuir(7, motivo: 'Fim do ano letivo');

      expect(api.chamadas, ['POST /admin/patrimonios/7/desatribuir']);
      expect(api.corpos.last, {'motivo': 'Fim do ano letivo'});
    });

    test('historico() chama o endpoint de movimentações', () async {
      final historico = await service.historico(7);

      expect(api.chamadas, ['GET /admin/patrimonios/7/historico']);
      expect(historico.total, 2);
      expect(historico.itens.first.acao, AcaoHistorico.atribuicao);
    });
  });

  // =========================================================================
  group('DashboardController (RF05)', () {
    test('carrega os indicadores na abertura', () async {
      final api = ApiClientFalso((_, _, _) async => payloadStats());
      final controller = DashboardController(PatrimonioService(api));

      await controller.carregar();

      expect(controller.indicadores.value!.totalPatrimonios, 8);
      expect(controller.erro.value, isEmpty);
      expect(controller.carregando.value, isFalse);
    });

    test('falha da API vira mensagem amigável (RNF02)', () async {
      final controller = DashboardController(
        PatrimonioService(
          ApiClientComErro(
            const AppException('Não foi possível conectar ao servidor.'),
          ),
        ),
      );

      await controller.carregar();

      expect(controller.indicadores.value, isNull);
      expect(controller.erro.value, contains('Não foi possível conectar'));
    });
  });

  // =========================================================================
  group('PatrimonioCicloVidaController (RF07b / RN05)', () {
    late ApiClientFalso api;
    late ApiClientFalso apiProfessores;

    setUp(() {
      api = ApiClientFalso((_, _, _) async => <String, dynamic>{});
      apiProfessores = ApiClientFalso(
        (_, _, _) async => payloadListaProfessores(),
      );
    });

    /// Cria o Controller já com o id e o modo do fluxo definidos.
    ///
    /// O Controller é montado à mão (e não via `Get.lazyPut`) porque o
    /// `Get.arguments` não tem setter: assim o teste escolhe o fluxo
    /// sem passar pelo roteador.
    Future<PatrimonioCicloVidaController> criar(
      WidgetTester tester, {
      required int id,
      required bool devolvendo,
    }) async {
      Get.testMode = true;
      final controller = PatrimonioCicloVidaController(
        PatrimonioService(api),
        ProfessorService(apiProfessores),
      )
        ..id = id
        ..devolvendo = devolvendo;
      controller.onInit();
      await tester.pump();
      return controller;
    }

    testWidgets('o modo atribuir carrega a lista de docentes',
        (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: false,
      );

      expect(controller.atribuindo, isTrue);
      expect(controller.devolvendo, isFalse);
      expect(controller.professores, hasLength(2));
      expect(apiProfessores.chamadas, ['GET /admin/professores']);
    });

    testWidgets('sem professor escolhido, nada é enviado', (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: false,
      );

      final ok = await controller.confirmar(await formStateDeTeste(tester));

      expect(ok, isFalse);
      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, contains('Escolha o professor'));
    });

    testWidgets('escolhido o professor, a entrega é enviada', (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: false,
      );

      controller.selecionarProfessor(2);
      controller.observacoesCtrl.text = 'Termo assinado';

      final ok = await controller.confirmar(await formStateDeTeste(tester));

      expect(ok, isTrue);
      expect(api.chamadas, ['POST /admin/patrimonios/7/atribuir']);
      expect(api.corpos.last, {
        'professorId': 2,
        'observacoes': 'Termo assinado',
      });
    });

    testWidgets('a devolução exige motivo (RN05)', (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: true,
      );

      expect(controller.devolvendo, isTrue);
      // A lista de docentes não é carregada no fluxo de devolução.
      expect(apiProfessores.chamadas, isEmpty);

      controller.motivoCtrl.text = 'x';
      final ok = await controller.confirmar(await formStateDeTeste(tester));

      expect(ok, isFalse);
      expect(api.chamadas, isEmpty);
      expect(controller.validarMotivo('x'), isNotNull);
      expect(controller.validarMotivo('Fim do ano letivo'), isNull);
    });

    testWidgets('a devolução com motivo é enviada', (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: true,
      );

      controller.motivoCtrl.text = 'Fim do ano letivo';
      final ok = await controller.confirmar(await formStateDeTeste(tester));

      expect(ok, isTrue);
      expect(api.chamadas, ['POST /admin/patrimonios/7/desatribuir']);
      expect(api.corpos.last, {'motivo': 'Fim do ano letivo'});
    });

    testWidgets('a busca de docente filtra a lista', (tester) async {
      final controller = await criar(
        tester,
        id: 7,
        devolvendo: false,
      );

      controller.aoDigitarBuscaProfessor('maria');

      expect(controller.professoresFiltrados, hasLength(1));
      expect(controller.professoresFiltrados.first.nome, 'Profa. Maria Silva');
    });

    testWidgets('erro do backend fica visível sem fechar a tela',
        (tester) async {
      final controller = PatrimonioCicloVidaController(
        PatrimonioService(
          ApiClientComErro(
            const AppException('Recurso não encontrado.', statusCode: 404),
          ),
        ),
        ProfessorService(apiProfessores),
      )
        ..id = 7
        ..devolvendo = false;
      controller.onInit();
      controller.selecionarProfessor(2);

      final ok = await controller.confirmar(await formStateDeTeste(tester));

      expect(ok, isFalse);
      expect(controller.erro.value, 'Recurso não encontrado.');
      expect(controller.salvando.value, isFalse);
    });
  });

  // =========================================================================
  group('PatrimonioHistoricoController (RF07b)', () {
    test('carrega a linha do tempo do bem', () async {
      Get.testMode = true;

      final api = ApiClientFalso((_, _, _) async => payloadHistorico());
      final controller = PatrimonioHistoricoController(
        PatrimonioService(api),
      )..id = 7;
      controller.onInit();
      await controller.carregar();

      expect(api.chamadas, contains('GET /admin/patrimonios/7/historico'));
      expect(controller.itens, hasLength(2));
      expect(controller.vazio, isFalse);
      expect(controller.itens.first.ehAtribuicao, isTrue);
      expect(controller.itens.last.acao, AcaoHistorico.criacao);
    });

    test('bem sem histórico mostra o estado vazio', () async {
      Get.testMode = true;

      final api = ApiClientFalso(
        (_, _, _) async => {'patrimonioId': 7, 'total': 0, 'historico': []},
      );
      final controller = PatrimonioHistoricoController(
        PatrimonioService(api),
      )..id = 7;
      controller.onInit();
      await controller.carregar();

      expect(controller.vazio, isTrue);
      expect(controller.itens, isEmpty);
    });
  });

  // =========================================================================
  group('MeusPatrimoniosController (RF08)', () {
    test('carrega os bens do docente autenticado', () async {
      final api = ApiClientFalso((_, _, _) async {
        return <String, dynamic>{
          'total': 1,
          'role': 'professor',
          'items': [payloadBemEmUso()],
        };
      });

      final controller = MeusPatrimoniosController(PatrimonioService(api));
      await controller.carregar();

      expect(api.chamadas, ['GET /patrimonios/meus']);
      expect(controller.patrimonios, hasLength(1));
      expect(controller.patrimonios.first.codigo, 'PAT-2024-007');
      expect(controller.patrimonios.first.dataAtribuicao, isNotNull);
      expect(controller.vazio, isFalse);
    });

    test('docente sem bens cai no estado vazio', () async {
      final api = ApiClientFalso(
        (_, _, _) async => <String, dynamic>{'total': 0, 'items': []},
      );

      final controller = MeusPatrimoniosController(PatrimonioService(api));
      await controller.carregar();

      expect(controller.patrimonios, isEmpty);
      expect(controller.vazio, isTrue);
      expect(controller.tituloEstadoVazio, 'Nenhum equipamento');
    });

    test('falha da API vira mensagem amigável (RNF02)', () async {
      final controller = MeusPatrimoniosController(
        PatrimonioService(
          ApiClientComErro(
            const AppException('Não foi possível conectar ao servidor.'),
          ),
        ),
      );

      await controller.carregar();

      expect(controller.erro.value, contains('Não foi possível conectar'));
      expect(controller.tituloEstadoVazio, 'Não foi possível carregar');
    });
  });

  // =========================================================================
  group('Rotas registradas (RF01 — navegação nomeada)', () {
    test('as telas novas estão no mapa de navegação', () {
      final nomes = AppRotas.paginas.map((p) => p.name).toSet();

      expect(nomes, contains(Rotas.dashboard));
      expect(nomes, contains(Rotas.meusPatrimonios));
      expect(nomes, contains('/admin/patrimonios'));
      expect(nomes, contains('/admin/patrimonios/atribuir'));
      expect(nomes, contains('/admin/patrimonios/devolver'));
      expect(nomes, contains('/admin/patrimonios/historico'));
      expect(nomes, contains(Rotas.professores));
      expect(nomes, contains(Rotas.perfil));
    });

    test('o dashboard exige papel de admin (RN03)', () {
      final pagina = AppRotas.paginas.firstWhere(
        (p) => p.name == Rotas.dashboard,
      );
      final classes =
          (pagina.middlewares ?? const []).map((m) => m.runtimeType.toString());

      expect(classes, contains('AdminMiddleware'));
    });
  });
}
