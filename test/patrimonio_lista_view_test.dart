import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/patrimonio_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_lista_view.dart';
import 'package:reserva_mobile/widgets/card_patrimonio.dart';

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

/// Service que reproduz os filtros do backend sobre o acervo falso.
///
/// Reproduzir a filtragem — em vez de devolver uma lista fixa — é o que
/// permite testar o chip de status de verdade: o teste só passa se o
/// toque chegar ao Service com o filtro certo.
class ServicoDeAcervoFake extends PatrimonioService {
  ServicoDeAcervoFake() : super(ApiClient(SessaoService()));

  /// Quando não é null, a próxima chamada lança este erro.
  AppException? erro;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    if (erro != null) throw erro!;

    var itens = acervoFake();

    final termo = busca?.trim().toLowerCase() ?? '';
    if (termo.isNotEmpty) {
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

UsuarioModel admin() => UsuarioModel(
      nome: 'Coordenador Geral',
      email: 'admin@admin.com',
      role: 'admin',
    );

UsuarioModel professor() => UsuarioModel(
      nome: 'Prof. Carlos Drummond',
      email: 'professor@escola.com',
      role: 'professor',
    );

/// Registra sessão, service e controller na ordem do `PatrimonioBinding`.
///
/// Os registros anteriores são apagados porque `Get.put` de um tipo já
/// registrado devolve a instância antiga — sem apagar, o teste leria o
/// usuário do caso anterior em vez do novo.
void registrar({
  required UsuarioModel usuario,
  required ServicoDeAcervoFake service,
}) {
  Get.delete<SessaoService>(force: true);
  Get.delete<PatrimonioService>(force: true);
  Get.delete<PatrimonioController>(force: true);

  Get.put<SessaoService>(SessaoService()).usuario.value = usuario;
  Get.put<PatrimonioService>(service);

  // Mesma forma do Binding: a `GetView` faz `Get.find` no primeiro
  // build, então o Controller precisa estar disponível ali.
  Get.lazyPut<PatrimonioController>(
    () => PatrimonioController(Get.find<PatrimonioService>()),
  );
}

/// Monta a tela de listagem e espera a carga terminar.
Future<void> pumpTela(
  WidgetTester tester,
  ServicoDeAcervoFake service, {
  required UsuarioModel usuario,
  Size tamanho = const Size(390, 844),
}) async {
  registrar(usuario: usuario, service: service);

  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GetMaterialApp(theme: Tema.claro, home: const PatrimonioListaView()),
  );
  await tester.pumpAndSettle();
}

/// Espera a busca disparar depois do intervalo de silêncio.
///
/// `pumpAndSettle` sozinho **não** serve: ele só avança enquanto há
/// frames agendados, e um `Timer` de 350 ms não agenda nenhum. Sem esta
/// espera explícita, o teste leria a lista **antes** do filtro ser
/// aplicado e passaria por engano.
Future<void> aguardarBusca(WidgetTester tester) async {
  await tester.pump(PatrimonioController.debounceBusca);
  await tester.pumpAndSettle();
}

/// Localiza um chip pelo rótulo.
///
/// Existe porque `ChoiceChip` tem subtipos (o Flutter cria um
/// `RawChip` por baixo) e `findsOneWidget` no texto puro acabaria
/// contando também o badge do card com o mesmo rótulo.
Finder chip(String rotulo) => find.widgetWithText(ChoiceChip, rotulo);

/// Procura um texto **dentro de um card** da lista.
///
/// Necessário porque o mesmo texto pode aparecer em dois lugares: no
/// card e no campo de busca (com o que o usuário digitou). Sem esta
/// restrição, "PAT-2024-003" seria encontrado duas vezes.
Finder cards(String texto) =>
    find.descendant(of: find.byType(CardPatrimonio), matching: find.text(texto));

void main() {
  late ServicoDeAcervoFake service;

  setUp(() => service = ServicoDeAcervoFake());
  tearDown(Get.reset);

  group('PatrimonioListaView — RF07a', () {
    testWidgets('mostra um card por bem do acervo', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(find.text('PAT-2024-001'), findsOneWidget);
      expect(find.text('Notebook Dell Latitude 3420'), findsOneWidget);
      expect(find.text('PAT-2024-003'), findsOneWidget);
    });

    testWidgets('a barra de filtros oferece o chip "Todos" e os status',
        (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(chip('Todos'), findsOneWidget);

      // Os chips ficam numa lista horizontal rolável: só os que cabem na
      // largura são construídos. Por isso a lista é rolada para conferir
      // cada status — inclusive os que ficariam fora da tela no iPhone SE.
      final listaFiltros = find.byType(Scrollable).first;
      for (final status in StatusPatrimonio.filtraveis) {
        await tester.dragUntilVisible(
          chip(status.rotulo),
          listaFiltros,
          const Offset(-80, 0),
        );
        await tester.pumpAndSettle();

        expect(chip(status.rotulo), findsOneWidget,
            reason: 'o filtro "${status.rotulo}" deve aparecer');
      }
    });

    testWidgets('o campo de busca está na tela', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      expect(find.widgetWithIcon(TextField, Icons.search), findsOneWidget);
    });

    testWidgets('tocar num chip de status filtra os cards', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      await tester.tap(find.widgetWithText(ChoiceChip, 'Disponível'));
      await tester.pumpAndSettle();

      expect(find.text('PAT-2024-002'), findsOneWidget);
      expect(find.text('PAT-2024-001'), findsNothing);
      expect(find.text('PAT-2024-003'), findsNothing);
    });

    testWidgets('tocar de novo no mesmo chip desmarca o filtro',
        (tester) async {
      await pumpTela(tester, service, usuario: admin());

      await tester.tap(find.widgetWithText(ChoiceChip, 'Disponível'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Disponível'));
      await tester.pumpAndSettle();

      expect(find.text('PAT-2024-001'), findsOneWidget);
      expect(find.text('PAT-2024-002'), findsOneWidget);
    });

    testWidgets('digitar na busca filtra por tombamento', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      await tester.enterText(
        find.widgetWithIcon(TextField, Icons.search),
        'PAT-2024-003',
      );
      await aguardarBusca(tester);

      // O texto digitado também existe no campo de busca, então a
      // verificação é feita nos cards.
      expect(cards('PAT-2024-003'), findsOneWidget);
      expect(cards('PAT-2024-001'), findsNothing);
    });

    testWidgets('"Limpar" volta a mostrar o acervo inteiro', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      await tester.enterText(
        find.widgetWithIcon(TextField, Icons.search),
        'zzz',
      );
      await aguardarBusca(tester);
      expect(find.text('Nenhum bem encontrado'), findsOneWidget);

      // Toca pelo texto: `TextButton.icon` cria um `_TextButtonWithIcon`,
      // que não casa com `find.byType(TextButton)` (o matcher exige o
      // tipo exato).
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(cards('PAT-2024-001'), findsOneWidget);
      expect(cards('PAT-2024-003'), findsOneWidget);
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
      // o backend responda 403 se ele tentar.
      expect(find.text('Novo bem'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('não gera overflow em iPhone SE (375x667)', (tester) async {
      await pumpTela(tester, service,
          usuario: admin(), tamanho: const Size(375, 667));

      expect(tester.takeException(), isNull);
    });

    testWidgets('não gera overflow em iPad', (tester) async {
      await pumpTela(tester, service,
          usuario: admin(), tamanho: const Size(1024, 1366));

      expect(tester.takeException(), isNull);
    });
  });

  group('PatrimonioListaView — estados assíncronos (RNF02)', () {
    testWidgets('mostra o skeleton durante a primeira carga',
        (tester) async {
      registrar(usuario: admin(), service: service);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(theme: Tema.claro, home: const PatrimonioListaView()),
      );
      // Sem `pumpAndSettle` de propósito: ele entrega o event loop e a
      // resposta (mesmo que instantânea) chega antes do `expect`. O
      // skeleton existe na janela entre abrir a tela e a resposta, e um
      // frame já é suficiente para observá-lo.
      expect(find.byType(ListaSkeletonPatrimonio), findsOneWidget);
    });

    testWidgets('acervo vazio mostra "Nenhum bem cadastrado"', (tester) async {
      await pumpTela(tester, service, usuario: admin());

      // Esvazia pelo estado do controller, como se a API devolvesse
      // `items: []`.
      Get.find<PatrimonioController>().patrimonios.clear();
      await tester.pumpAndSettle();

      expect(find.text('Nenhum bem cadastrado'), findsOneWidget);
      expect(
        find.textContaining('Cadastre o primeiro bem'),
        findsOneWidget,
        reason: 'o estado vazio precisa sugerir o cadastro',
      );
    });

    testWidgets('busca sem resultado muda a mensagem do estado vazio',
        (tester) async {
      await pumpTela(tester, service, usuario: admin());

      await tester.enterText(
        find.widgetWithIcon(TextField, Icons.search),
        'zzz',
      );
      await aguardarBusca(tester);

      expect(find.text('Nenhum bem encontrado'), findsOneWidget);
      expect(find.text('Nenhum bem cadastrado'), findsNothing);
    });

    testWidgets('falha na carga mostra a mensagem e a ação de recuperação',
        (tester) async {
      service.erro = const AppException('Servidor fora do ar', statusCode: 500);

      await pumpTela(tester, service, usuario: admin());

      expect(find.text('Servidor fora do ar'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('"Tentar novamente" refaz a carga', (tester) async {
      service.erro = const AppException('Servidor fora do ar', statusCode: 500);

      await pumpTela(tester, service, usuario: admin());
      expect(find.text('Tentar novamente'), findsOneWidget);

      service.erro = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('PAT-2024-001'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
    });
  });
}
