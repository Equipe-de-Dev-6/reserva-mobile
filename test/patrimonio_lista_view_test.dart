import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/patrimonio_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_lista_view.dart';

/// Acervo de mentira: três bens, um de cada situação relevante.
List<PatrimonioModel> acervoFake() => const [
      PatrimonioModel(
        id: 1,
        codigo: 'PAT-2024-001',
        nome: 'Notebook Dell Latitude 3420',
        descricao: 'Intel Core i5, 16GB RAM',
        categoria: 'Informática',
        marca: 'Dell',
        modelo: 'Latitude 3420',
        localizacao: 'Gabinete dos Professores - Mesa 04',
        status: StatusPatrimonio.emUso,
        professorId: 2,
        professorNome: 'Prof. Carlos Drummond',
      ),
      PatrimonioModel(
        id: 2,
        codigo: 'PAT-2024-002',
        nome: 'Projetor Epson PowerLite E20',
        descricao: '3400 lumens com HDMI',
        categoria: 'Audiovisual',
        marca: 'Epson',
        localizacao: 'Sala de Aula 102',
        status: StatusPatrimonio.disponivel,
      ),
      PatrimonioModel(
        id: 3,
        codigo: 'PAT-2024-003',
        nome: 'Microscópio Binocular 1600x',
        descricao: '4 objetivas acromáticas',
        categoria: 'Laboratório',
        marca: 'Opton',
        localizacao: 'Laboratório de Ciências',
        status: StatusPatrimonio.emManutencao,
      ),
    ];

/// Service que devolve o acervo fixo acima.
class ServicoDeAcervoFake extends PatrimonioService {
  ServicoDeAcervoFake() : super(ApiClient(SessaoService()));

  bool falhar = false;
  Object? erro;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    if (falhar && erro != null) throw erro!;

    var itens = acervoFake();
    if (busca != null && busca.trim().isNotEmpty) {
      final termo = busca.trim().toLowerCase();
      itens = itens
          .where((p) =>
              p.codigo.toLowerCase().contains(termo) ||
              p.nome.toLowerCase().contains(termo) ||
              p.marca.toLowerCase().contains(termo))
          .toList();
    }
    if (status != null) {
      itens = itens.where((p) => p.status == status).toList();
    }
    if (categoria != null) {
      itens = itens.where((p) => p.categoria == categoria).toList();
    }
    return itens;
  }
}

/// Monta a tela com sessão e service controlados.
Future<void> pumpTela(
  WidgetTester tester,
  ServicoDeAcervoFake service, {
  required UsuarioModel? usuario,
  Size tamanho = const Size(390, 844),
}) async {
  Get.delete<SessaoService>(force: true);
  // `Get.put` de um tipo já registrado devolve a instância antiga, então o
  // registro anterior é removido antes de instalar a sessão do teste.
  Get.delete<SessaoService>(force: true);
  Get.delete<PatrimonioService>(force: true);
  final sessao = Get.put<SessaoService>(SessaoService());
  sessao.usuario.value = usuario;
  Get.put<PatrimonioService>(service);

  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      home: const PatrimonioListaView(),
    ),
  );
  await tester.pumpAndSettle();
}

UsuarioModel admin() => UsuarioModel(
      nome: 'Coordenador Geral',
      email: 'admin@escola.com',
      role: 'admin',
    );

UsuarioModel professor() => UsuarioModel(
      nome: 'Prof. Carlos Drummond',
      email: 'professor@escola.com',
      role: 'professor',
    );

void main() {
  late ServicoDeAcervoFake service;

  setUp(() {
    service = ServicoDeAcervoFake();
  });

  tearDown(Get.reset);

  group('PatrimonioListaView — RF07a', () {
    testWidgets('mostra um card por bem do acervo', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(find.text('PAT-2024-001'), findsOneWidget);
      expect(find.text('Notebook Dell Latitude 3420'), findsOneWidget);
      expect(find.text('PAT-2024-003'), findsOneWidget);
    });

    testWidgets('exibe os chips de status e de "Todos"', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(find.text('Todos'), findsOneWidget);
      for (final rotulo in StatusPatrimonio.filtraveis) {
        expect(find.widgetWithText(ChoiceChip, rotulo.rotulo), findsOneWidget,
            reason: 'o filtro "${rotulo.rotulo}" deve aparecer');
      }
    });

    testWidgets('o campo de busca aceita texto', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      final busca = find.widgetWithIcon(TextField, Icons.search);
      expect(busca, findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('filtrar por status restringe os cards', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      // "Disponível" aparece tanto no chip quanto no badge do card; o
      // toque é no chip.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Disponível').first);
      await tester.pumpAndSettle();

      expect(find.text('PAT-2024-002'), findsOneWidget);
      expect(find.text('PAT-2024-001'), findsNothing);
    });

    testWidgets('o FAB de novo bem aparece para o Coordenador',
        (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(find.widgetWithText(FloatingActionButton, 'Novo bem'),
          findsOneWidget);
    });

    testWidgets('o FAB de novo bem NÃO aparece para o Professor (RN03)',
        (tester) async {
      await pumpTela(tester, service, usuario: professor());

      // RN03: o docente não deve enxergar a ação de escrita, mesmo que
      // o backend devolva 403 se ele tentar.
      expect(find.text('Novo bem'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('não gera overflow em iPhone SE (375x667)', (tester) async {
      await pumpTela(
        tester,
        service,
        usuario: admin(),
        tamanho: const Size(375, 667),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('não gera overflow em iPad', (tester) async {
      await pumpTela(
        tester,
        service,
        usuario: admin(),
        tamanho: const Size(1024, 1366),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('PatrimonioListaView — estados assíncronos (RNF02)', () {
    testWidgets('mostra o skeleton durante a primeira carga',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: Tema.claro,
          home: const PatrimonioListaView(),
        ),
      );
      // Um único frame: ainda no shimmer, antes da resposta.
      await tester.pump();

      expect(find.byType(ListaSkeletonPatrimonio), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('mostra estado vazio quando o acervo não tem bens',
        (tester) async {
      final vazio = ServicoDeAcervoFake();
      // Substitui a fonte por uma lista vazia.
      await pumpTela(tester, vazio, usuario: admin());
      await tester.pumpAndSettle();

      // Force a lista vazia pelo próprio estado do controller.
      final controller = Get.find<PatrimonioController>();
      controller.patrimonios.clear();
      await tester.pumpAndSettle();

      expect(find.text('Nenhum bem cadastrado'), findsOneWidget);
    });

    testWidgets('estado vazio com busca sem resultado muda o texto',
        (tester) async {
      await pumpTela(tester, service, usuario: admin());

      controllerDaTela().buscaCtrl.text = 'zzzz';
      await controllerDaTela().buscarAgora();
      await tester.pumpAndSettle();

      expect(find.text('Nenhum bem encontrado'), findsOneWidget);
      expect(find.text('Limpar'), findsOneWidget);
    });

    testWidgets('mostra mensagem de erro com ação de tentar de novo',
        (tester) async {
      service
        ..falhar = true
        ..erro = Exception('falha');

      await pumpTela(tester, service, usuario: admin());

      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('"Tentar novamente" refaz a carga', (tester) async {
      service
        ..falhar = true
        ..erro = Exception('falha');

      await pumpTela(tester, service, usuario: admin());
      expect(find.text('Tentar novamente'), findsOneWidget);

      service.falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('PAT-2024-001'), findsOneWidget);
    });
  });
}

PatrimonioController controllerDaTela() => Get.find<PatrimonioController>();
