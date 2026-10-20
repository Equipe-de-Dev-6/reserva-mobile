import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/historico_model.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/widgets/badge_status.dart';
import 'package:reserva_mobile/widgets/card_patrimonio.dart';

/// JSON real devolvido por `GET /api/patrimonios/1`.
///
/// Copiado da resposta do backend de propósito: se a API mudar um nome de
/// campo, este teste avisa no mesmo dia em vez de a tela quebrar em
/// produção.
Map<String, dynamic> jsonPatrimonio() => {
      'id': 1,
      'codigo': 'PAT-2024-001',
      'nome': 'Notebook Dell Latitude 3420',
      'descricao': 'Intel Core i5 11ª Ger, 16GB RAM, SSD 512GB',
      'categoria': 'Informática',
      'marca': 'Dell',
      'modelo': 'Latitude 3420',
      'numeroSerie': 'DL-992831',
      'estadoConservacao': 'Excelente',
      'localizacao': 'Gabinete dos Professores - Mesa 04',
      'status': 'em_uso',
      'adminId': 1,
      'professorId': 2,
      'responsavelId': 2,
      'professorNome': 'Prof. Carlos Drummond',
      'professorEmail': 'professor@escola.com',
      'dataAtribuicao': '2026-09-14T20:00:00Z',
      'observacoes': '',
      'createdAt': '2026-09-14T19:00:00Z',
      'updatedAt': '2026-09-14T20:00:00Z',
    };

/// `ApiClient` falso que registra as chamadas e devolve respostas
/// programadas.
///
/// Permite testar o Service inteiro — inclusive a montagem da query e o
/// corpo das requisições — sem subir o backend.
class ApiClientFalso extends ApiClient {
  ApiClientFalso() : super(SessaoService());

  final List<({String caminho, Map<String, dynamic>? query})> chamadasGet = [];
  final List<({String caminho, Object? body})> chamadasPost = [];
  final List<({String caminho, Object? body})> chamadasPut = [];
  final List<String> chamadasDelete = [];

  Map<String, dynamic> respostaGet = const {};
  Map<String, dynamic> respostaPost = const {};
  Map<String, dynamic> respostaPut = const {};
  Map<String, dynamic> respostaDelete = const {};

  /// Quando não é null, o próximo `get` lança isto (simula 403/500).
  Object? erroGet;

  @override
  Future<Map<String, dynamic>> get(
    String caminho, {
    Map<String, dynamic>? query,
  }) async {
    chamadasGet.add((caminho: caminho, query: query));
    if (erroGet != null) throw erroGet!;
    return respostaGet;
  }

  @override
  Future<Map<String, dynamic>> post(String caminho,
      {Object? body, bool autenticado = true}) async {
    chamadasPost.add((caminho: caminho, body: body));
    return respostaPost;
  }

  @override
  Future<Map<String, dynamic>> put(String caminho, {Object? body}) async {
    chamadasPut.add((caminho: caminho, body: body));
    return respostaPut;
  }

  @override
  Future<Map<String, dynamic>> delete(String caminho) async {
    chamadasDelete.add(caminho);
    return respostaDelete;
  }
}

void main() {
  group('StatusPatrimonio — RN de leitura do status', () {
    test('converte os quatro status da API', () {
      expect(StatusPatrimonio.fromValor('disponivel'),
          StatusPatrimonio.disponivel);
      expect(StatusPatrimonio.fromValor('em_uso'), StatusPatrimonio.emUso);
      expect(StatusPatrimonio.fromValor('em_manutencao'),
          StatusPatrimonio.emManutencao);
      expect(StatusPatrimonio.fromValor('baixado'), StatusPatrimonio.baixado);
    });

    test('status desconhecido vira indefinido em vez de estourar', () {
      // Um estado novo no banco não pode derrubar a listagem inteira.
      expect(
          StatusPatrimonio.fromValor('em_avaliacao'), StatusPatrimonio.indefinido);
      expect(StatusPatrimonio.fromValor(null), StatusPatrimonio.indefinido);
      expect(StatusPatrimonio.fromValor(''), StatusPatrimonio.indefinido);
    });

    test('indefinido não aparece entre os filtros offers', () {
      // "Indefinido" é fallback de leitura, não uma opção de filtro.
      expect(StatusPatrimonio.filtraveis.length, 4);
      expect(
        StatusPatrimonio.filtraveis.contains(StatusPatrimonio.indefinido),
        isFalse,
      );
    });

    test('só disponível e em manutenção aceitam recebimento (RF07b)', () {
      expect(StatusPatrimonio.disponivel.aceitaAtribuicao, isTrue);
      expect(StatusPatrimonio.emManutencao.aceitaAtribuicao, isTrue);
      expect(StatusPatrimonio.emUso.aceitaAtribuicao, isFalse);
      expect(StatusPatrimonio.baixado.aceitaAtribuicao, isFalse);
    });
  });

  group('PatrimonioModel — leitura do JSON real', () {
    test('mapeia todos os campos devolvidos pela API', () {
      final p = PatrimonioModel.fromJson(jsonPatrimonio());

      expect(p.id, 1);
      expect(p.codigo, 'PAT-2024-001');
      expect(p.tombamento, 'PAT-2024-001');
      expect(p.nome, 'Notebook Dell Latitude 3420');
      expect(p.marca, 'Dell');
      expect(p.modelo, 'Latitude 3420');
      expect(p.numeroSerie, 'DL-992831');
      expect(p.estadoConservacao, 'Excelente');
      expect(p.localizacao, 'Gabinete dos Professores - Mesa 04');
      expect(p.status, StatusPatrimonio.emUso);
      expect(p.professorId, 2);
      expect(p.professorNome, 'Prof. Carlos Drummond');
      expect(p.dataAtribuicao, isNotNull);
    });

    test('bem disponível não tem professor e formata o subtítulo', () {
      final json = jsonPatrimonio()
        ..['status'] = 'disponivel'
        ..['professorId'] = null
        ..remove('professorNome')
        ..remove('professorEmail')
        ..remove('dataAtribuicao');

      final p = PatrimonioModel.fromJson(json);

      expect(p.temProfessor, isFalse);
      expect(p.emUsoComResponsavel, isFalse);
      expect(p.professorNomeFormatado, 'Sem responsável');
      expect(p.resumoResponsavel, 'Disponível');
    });

    test('em uso sem professor é sinalizado como inconsistente', () {
      // RN: em uso sempre tem responsável. Um dado assim não pode
      // fingir que existe alguém vinculado.
      final json = jsonPatrimonio()..['professorId'] = null;
      final p = PatrimonioModel.fromJson(json);

      expect(p.status, StatusPatrimonio.emUso);
      expect(p.temProfessor, isFalse);
      expect(p.emUsoComResponsavel, isFalse);
    });

    test('campos ausentes viram vazio, nunca "null" na tela', () {
      final p = PatrimonioModel.fromJson({'id': 9});

      expect(p.codigo, '');
      expect(p.nome, '');
      expect(p.numeroSerie, isNull);
      expect(p.numeroSerieFormatado, 'Não informado');
      expect(p.status, StatusPatrimonio.indefinido);
      expect(p.localizacao, '');
      expect(p.createdAt, isNull);
    });

    test('id numérico como string é convertido (tolerância de serialização)',
        () {
      final p = PatrimonioModel.fromJson({'id': '7', 'codigo': 'PAT-7'});
      expect(p.id, 7);
    });

    test('nomes em branco viram null nos campos opcionais', () {
      // O banco devolve "" para optional não preenchido.
      final p = PatrimonioModel.fromJson({'id': 1, 'numeroSerie': '   '});
      expect(p.numeroSerie, isNull);
      expect(p.numeroSerieFormatado, 'Não informado');
    });
  });

  group('PatrimonioModel — corpo das requisições', () {
    test('cadastro envia codigo e nome, e não leva professorId', () {
      // Se `professorId` fosse null no corpo, salvar um bem já atribuído
      // desatribuiria o docente. Vínculo é o fluxo de atribuição (RF07b).
      final p = PatrimonioModel.fromJson(jsonPatrimonio());
      final corpo = p.toJson();

      expect(corpo['codigo'], 'PAT-2024-001');
      expect(corpo['nome'], 'Notebook Dell Latitude 3420');
      expect(corpo.containsKey('professorId'), isFalse);
      expect(corpo.containsKey('id'), isFalse);
      expect(corpo.containsKey('status'), isFalse);
    });

    test('atualização envia o status, mas não o tombamento', () {
      // `UpdatePatrimonioRequest` da API não aceita `codigo`:
      // identificador de tombamento muda por processo patrimonial.
      final p = PatrimonioModel.fromJson(jsonPatrimonio());
      final corpo = p.toJsonAtualizacao();

      expect(corpo['status'], 'em_uso');
      expect(corpo.containsKey('codigo'), isFalse);
      expect(corpo['localizacao'], 'Gabinete dos Professores - Mesa 04');
    });

    test('valores são trimados antes de irem para a API', () {
      final p = PatrimonioModel(
        id: 0,
        codigo: '  PAT-2024-999  ',
        nome: '  Projetor  ',
        descricao: '  3300 lumens ',
        status: StatusPatrimonio.disponivel,
      );

      final corpo = p.toJson();
      expect(corpo['codigo'], 'PAT-2024-999');
      expect(corpo['nome'], 'Projetor');
      expect(corpo['descricao'], '3300 lumens');
    });

    test('numeroSerie vazio vira string vazia, não null', () {
      final p = PatrimonioModel(id: 0, codigo: 'X', nome: 'Y');
      expect(p.toJson()['numeroSerie'], '');
    });
  });

  group('PatrimonioService — RF07a listagem com busca e filtros', () {
    late ApiClientFalso api;
    late PatrimonioService service;

    setUp(() {
      api = ApiClientFalso();
      service = PatrimonioService(api);
      api.respostaGet = {
        'items': [jsonPatrimonio()],
        'role': 'admin',
        'total': 1,
      };
    });

    test('sem filtros não manda parâmetro nenhum na query', () async {
      // `busca=` vazio faria o backend filtrar pela string vazia em vez
      // de listar o acervo todo.
      await service.listar();

      expect(api.chamadasGet.first.caminho, '/patrimonios');
      expect(api.chamadasGet.first.query, isEmpty);
    });

    test('busca por tombamento vai como parâmetro "busca"', () async {
      await service.listar(busca: 'PAT-2024-001');

      expect(api.chamadasGet.first.query!['busca'], 'PAT-2024-001');
    });

    test('busca com espaço em volta é limpa antes de enviar', () async {
      await service.listar(busca: '   dell   ');

      expect(api.chamadasGet.first.query!['busca'], 'dell');
    });

    test('busca só com espaços é tratada como ausente', () async {
      await service.listar(busca: '     ');

      expect(api.chamadasGet.first.query!.containsKey('busca'), isFalse);
    });

    test('filtro de status usa o valor da API, não o rótulo', () async {
      await service.listar(status: StatusPatrimonio.emManutencao);

      // "Em manutenção" na query não filtraria nada: o backend quer
      // `em_manutencao`.
      expect(api.chamadasGet.first.query!['status'], 'em_manutencao');
    });

    test('filtro de categoria e de professor vão juntos', () async {
      await service.listar(categoria: 'Laboratório', professorId: 3);

      expect(api.chamadasGet.first.query!['categoria'], 'Laboratório');
      expect(api.chamadasGet.first.query!['professor_id'], 3);
    });

    test('os quatro filtros podem ser enviados na mesma consulta', () async {
      await service.listar(
        busca: 'notebook',
        status: StatusPatrimonio.emUso,
        categoria: 'Informática',
        professorId: 2,
      );

      final query = api.chamadasGet.first.query!;
      expect(query['busca'], 'notebook');
      expect(query['status'], 'em_uso');
      expect(query['categoria'], 'Informática');
      expect(query['professor_id'], 2);
    });

    test('"indefinido" não vira filtro de status', () async {
      // Senão o app mandaria `status=` e o backend listaria o acervo todo
      // fingindo que estava filtrando.
      await service.listar(status: StatusPatrimonio.indefinido);

      expect(api.chamadasGet.first.query!.containsKey('status'), isFalse);
    });

    test('converte a lista de itens em modelos', () async {
      final lista = await service.listar();

      expect(lista, hasLength(1));
      expect(lista.first.codigo, 'PAT-2024-001');
      expect(lista.first.status, StatusPatrimonio.emUso);
    });

    test('resposta sem "items" devolve lista vazia, sem exceção', () async {
      // Uma API mudando o formato não pode virar tela vermelha.
      api.respostaGet = {'total': 0};

      expect(await service.listar(), isEmpty);
    });

    test('"items" nulo também devolve lista vazia', () async {
      api.respostaGet = {'items': null};

      expect(await service.listar(), isEmpty);
    });
  });

  group('PatrimonioService — detalhe, cadastro, edição e exclusão', () {
    late ApiClientFalso api;
    late PatrimonioService service;

    setUp(() {
      api = ApiClientFalso();
      service = PatrimonioService(api);
    });

    test('detalhe chama o endpoint com o id do bem', () async {
      api.respostaGet = jsonPatrimonio();

      final p = await service.detalhe(1);

      expect(api.chamadasGet.first.caminho, '/patrimonios/1');
      expect(p.nome, 'Notebook Dell Latitude 3420');
    });

    test('cadastro envia o corpo e devolve o id gerado', () async {
      api.respostaPost = {
        'message': 'Patrimônio cadastrado com sucesso',
        'patrimonioId': 8,
        'codigo': 'PAT-2024-008',
        'status': 'disponivel',
      };

      final resultado = await service.criar(
        PatrimonioModel.fromJson(jsonPatrimonio()),
      );

      expect(api.chamadasPost.first.caminho, '/patrimonios');
      expect(resultado.id, 8);
      expect(resultado.idValido, isTrue);
      expect(resultado.status, StatusPatrimonio.disponivel);
    });

    test('cadastro sem id na resposta é sinalizado como não navegável', () async {
      api.respostaPost = {'message': 'ok'};

      final resultado = await service.criar(
        PatrimonioModel.fromJson(jsonPatrimonio()),
      );

      // Evita navegar para `/patrimonios/detalhe/0`.
      expect(resultado.idValido, isFalse);
    });

    test('atualização faz PUT sem mandar o tombamento', () async {
      api.respostaPut = {'message': 'ok', 'patrimonioId': 1};

      await service
          .atualizar(1, PatrimonioModel.fromJson(jsonPatrimonio()));

      expect(api.chamadasPut.first.caminho, '/patrimonios/1');
      expect((api.chamadasPut.first.body as Map)['status'], 'em_uso');
      expect(
        (api.chamadasPut.first.body as Map).containsKey('codigo'),
        isFalse,
      );
    });

    test('exclusão faz DELETE no id do bem', () async {
      api.respostaDelete = {'message': 'ok', 'patrimonioId': 1};

      await service.excluir(1);

      expect(api.chamadasDelete, ['/patrimonios/1']);
    });
  });

  group('HistoricoModel — linha do tempo do bem (RF07b)', () {
    test('lê um registro real do backend', () {
      final item = HistoricoModel.fromJson({
        'id': 1,
        'patrimonioId': 1,
        'professorId': 2,
        'professorNome': 'Prof. Carlos Drummond',
        'adminId': 1,
        'adminNome': 'Coordenador Geral (Admin)',
        'acao': 'atribuicao',
        'motivo': 'Atribuição inicial de patrimônio ao docente responsável',
        'dataRegistro': '2026-09-14T20:00:00Z',
      });

      expect(item.acao, AcaoHistorico.atribuicao);
      expect(item.rotuloAcao, 'Atribuição a docente');
      expect(item.ehAtribuicao, isTrue);
      expect(item.ehDesatribuicao, isFalse);
      expect(item.responsavel, 'Coordenador Geral (Admin)');
      expect(item.dataRegistro, isNotNull);
    });

    test('devolução é reconhecida como desatribuição', () {
      final item = HistoricoModel.fromJson({'acao': 'desatribuicao'});
      expect(item.ehDesatribuicao, isTrue);
    });

    test('ação desconhecida cai em "Movimento registrado"', () {
      final item = HistoricoModel.fromJson({'acao': 'inventario'});
      expect(item.acao, AcaoHistorico.outro);
    });

    test('envolve o total e detecta histórico vazio', () {
      final vazio =
          HistoricoPatrimonioModel.fromJson({'patrimonioId': 1, 'total': 0});
      expect(vazio.vazio, isTrue);

      final cheio = HistoricoPatrimonioModel.fromJson({
        'patrimonioId': 1,
        'total': 1,
        'historico': [
          {'id': 1, 'patrimonioId': 1, 'acao': 'atribuicao'},
        ],
      });
      expect(cheio.vazio, isFalse);
      expect(cheio.itens, hasLength(1));
      expect(cheio.total, 1);
    });

    test('"historico" ausente devolve lista vazia', () {
      final h = HistoricoPatrimonioModel.fromJson({'patrimonioId': 3});
      expect(h.itens, isEmpty);
      expect(h.total, 0);
    });
  });

  group('BadgeStatus — rótulo e cor por status', () {
    testWidgets('mostra o rótulo do status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeStatus(status: StatusPatrimonio.emManutencao),
          ),
        ),
      );

      expect(find.text('Em manutenção'), findsOneWidget);
    });

    testWidgets('cada status tem cor própria', (tester) async {
      // Cores iguais fariam o usuário ler "Em uso" como "Disponível".
      expect(BadgeStatus.corDe(StatusPatrimonio.disponivel),
          isNot(BadgeStatus.corDe(StatusPatrimonio.emUso)));
      expect(BadgeStatus.corDe(StatusPatrimonio.emManutencao),
          isNot(BadgeStatus.corDe(StatusPatrimonio.baixado)));
    });

    testWidgets('"Indefinido" não quebra o layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BadgeStatus(status: StatusPatrimonio.indefinido)),
        ),
      );

      expect(find.text('Indefinido'), findsOneWidget);
    });

    testWidgets('não gera overflow em iPhone SE (375px)', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BadgeStatus(status: StatusPatrimonio.emManutencao),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('CardPatrimonio', () {
    testWidgets('mostra tombamento, nome e responsável', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson(jsonPatrimonio()),
            ),
          ),
        ),
      );

      expect(find.text('PAT-2024-001'), findsOneWidget);
      expect(find.text('Notebook Dell Latitude 3420'), findsOneWidget);
      expect(find.text('Informática · Dell · Latitude 3420'), findsOneWidget);
      expect(find.text('Prof. Carlos Drummond'), findsOneWidget);
      expect(find.text('Em uso'), findsOneWidget);
    });

    testWidgets('dispara o toque ao ser tocado', (tester) async {
      var tocou = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson(jsonPatrimonio()),
              aoTocar: () => tocou = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tocou, isTrue);
    });

    testWidgets('bem disponível mostra "Sem responsável"', (tester) async {
      final json = jsonPatrimonio()
        ..['status'] = 'disponivel'
        ..['professorId'] = null
        ..remove('professorNome');

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson(json),
              // Na lista do docente o responsável é ele mesmo: poluir o
              // card com o próprio nome não ajuda.
              mostrarResponsavel: false,
            ),
          ),
        ),
      );

      expect(find.text('Sem responsável'), findsNothing);
      expect(find.text('Disponível'), findsOneWidget);
    });

    testWidgets('sem categoria mostra o texto de fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel(id: 1, codigo: 'PAT-1', nome: 'Bem'),
            ),
          ),
        ),
      );

      expect(find.text('Sem categoria informada'), findsOneWidget);
      expect(find.text('Indefinido'), findsOneWidget);
    });

    testWidgets('não gera overflow em iPhone SE com textos longos',
        (tester) async {
      // Regressão clássica de lista: nome e tombamento compridos estouravam
      // a linha no aparelho pequeno.
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson(jsonPatrimonio()),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('não gera overflow em iPad', (tester) async {
      tester.view.physicalSize = const Size(2048, 2732);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson(jsonPatrimonio()),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
