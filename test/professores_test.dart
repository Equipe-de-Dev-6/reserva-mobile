import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/middleware.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/professor_cadastro_controller.dart';
import 'package:reserva_mobile/controllers/professor_detalhe_controller.dart';
import 'package:reserva_mobile/controllers/professor_lista_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/professor_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/professor_model.dart';
import 'package:reserva_mobile/models/professor_request.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/views/admin/professores/professor_cadastro_view.dart';
import 'package:reserva_mobile/widgets/badge_status.dart';
import 'package:reserva_mobile/widgets/card_patrimonio.dart';
import 'package:reserva_mobile/widgets/cartao_professor.dart';

import 'helpers/api_client_falso.dart';
import 'helpers/test_armazenamento.dart';

// ---------------------------------------------------------------------------
// Ajudantes
// ---------------------------------------------------------------------------

List<ProfessorModel> professoresDeTeste() =>
    (payloadListaProfessores()['professores'] as List)
        .map((m) => ProfessorModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

List<PatrimonioModel> bensDeTeste() =>
    (payloadDetalheProfessor()['patrimonios'] as List)
        .map((m) => PatrimonioModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

/// Cria um `FormState` de verdade, montando um `Form` vazio.
///
/// Usa `GetMaterialApp` porque o Controller navega (`Get.back`) e mostra
/// `Get.snackbar` ao final de um cadastro bem-sucedido; sem o `Get.key`
/// essas chamadas lançariam "contextless navigation".
Future<FormState> formStateDeTeste(WidgetTester tester) async {
  final chave = GlobalKey<FormState>();
  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      home: Scaffold(
        body: Form(key: chave, child: const SizedBox.shrink()),
      ),
    ),
  );
  return chave.currentState!;
}

/// Cria um `FormState` de verdade cujo `validate()` reprova, simulando o
/// `Form` barrando o envio por causa da validação local dos `CampoTexto`.
Future<FormState> formStateReprovado(WidgetTester tester) async {
  final chave = GlobalKey<FormState>();
  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      home: Scaffold(
        body: Form(
          key: chave,
          child: FormField<String>(
            validator: (_) => 'valor inválido',
            builder: (state) => const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  return chave.currentState!;
}

/// Monta só a tela de cadastro, com um [ApiClient] dublê injetado pelo
/// `ProfessorBinding`. Serve para provar o caminho completo — campo →
/// validação → Controller → Service — sem subir a API.
Future<ApiClientFalso> montarTelaCadastro(WidgetTester tester) async {
  final api = ApiClientFalso((_, _, _) async => {
        'message': 'Professor cadastrado com sucesso',
        'professor': {
          'id': 9,
          'nome': 'Prof. Novo',
          'email': 'novo@escola.com',
          'role': 'professor',
          'totalPatrimonios': 0,
        },
      });

  Get.put<ApiClient>(api, permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      initialRoute: Rotas.professorNovo,
      getPages: [
        GetPage(
          name: Rotas.professorNovo,
          page: () => const ProfessorCadastroView(),
          binding: ProfessorBinding(),
        ),
      ],
    ),
  );
  await tester.pump();
  return api;
}

/// O `Get.snackbar` de sucesso abre uma animação de 4 segundos. Como a
/// fila de snackbar do GetX é global, sem drená-la ela "vaza" para o
/// teste seguinte e o scheduler acusa animação órfã no fim do teste.
Future<void> drenarSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
}

/// Testes da camada de dados e dos Controllers do RF06 (gestão de
/// professores), sem depender do backend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Os Controllers navegam ao final do fluxo (voltar para a listagem,
  // snackbar). Em teste não existe `GetMaterialApp` no caminho de todos
  // os casos, então o modo de teste do GetX evita a exceção de
  // "contextless navigation".
  Get.testMode = true;

  tearDown(() {
    Get.parameters = {};
    Get.reset();
  });

  // =========================================================================
  group('ProfessorModel — contador de bens (RF06)', () {
    test('lê o totalPatrimonios calculado pelo backend', () {
      final professor = professoresDeTeste().first;
      expect(professor.id, 2);
      expect(professor.totalPatrimonios, 3);
      expect(professor.possuiBens, isTrue);
    });

    test('o rótulo do indicador concorda no singular e no plural', () {
      expect(professoresDeTeste().first.rotuloBens,
          '3 bens sob responsabilidade');
      expect(
        ProfessorModel.fromJson({
          'id': 9,
          'nome': 'X',
          'email': 'x@y.com',
          'totalPatrimonios': 1,
        }).rotuloBens,
        '1 bem sob responsabilidade',
      );
    });

    test('sem bens o indicador é "0 bens" e possuiBens é falso', () {
      final semBens = ProfessorModel.fromJson({
        'id': 4,
        'nome': 'Prof. Novo',
        'email': 'novo@escola.com',
      });
      expect(semBens.totalPatrimonios, 0);
      expect(semBens.possuiBens, isFalse);
      expect(semBens.rotuloBens, '0 bens sob responsabilidade');
    });

    test('iniciais, telefone e resumo institucional', () {
      final professor = professoresDeTeste().first;
      expect(professor.iniciais, 'PD');
      expect(professor.telefoneFormatado, '(11) 98765-1001');
      expect(professor.resumoInstitucional,
          'PROF-2024-01 · Língua Portuguesa e Literatura');
    });

    test('fromJson tolera id como string e campos ausentes', () {
      final p = ProfessorModel.fromJson({'id': '11', 'email': 'a@b.com'});
      expect(p.id, 11);
      expect(p.nome, 'Docente sem nome');
      expect(p.role, 'professor'); // padrão seguro
      expect(p.telefoneFormatado, 'Não informado');
      expect(p.resumoInstitucional, 'Sem matrícula informada');
    });
  });

  // =========================================================================
  group('ProfessorModel — busca local (o endpoint não aceita filtro)', () {
    test('termo vazio devolve todos', () {
      expect(professoresDeTeste().every((p) => p.correspondeAoTermo('')), isTrue);
      expect(
          professoresDeTeste().every((p) => p.correspondeAoTermo('   ')), isTrue);
    });

    test('encontra por nome, e-mail, matrícula e departamento', () {
      final lista = professoresDeTeste();
      expect(lista.where((p) => p.correspondeAoTermo('maria')).length, 1);
      expect(lista.where((p) => p.correspondeAoTermo('carlos')).length, 1);
      expect(lista.where((p) => p.correspondeAoTermo('PROF-2024-02')).length, 1);
      expect(lista.where((p) => p.correspondeAoTermo('biologia')).length, 1);
    });

    test('não distingue maiúsculas de minúsculas', () {
      expect(
          professoresDeTeste().where((p) => p.correspondeAoTermo('MARIA')).length,
          1);
    });

    test('termo sem correspondência não devolve ninguém', () {
      expect(professoresDeTeste()
              .where((p) => p.correspondeAoTermo('zzz'))
              .isEmpty,
          isTrue);
    });
  });

  // =========================================================================
  group('PatrimonioModel — bens vinculados (RF06.3)', () {
    test('lê os campos que a API realmente devolve', () {
      final bem = bensDeTeste().first;
      expect(bem.codigo, 'PAT-2024-003');
      expect(bem.nome, 'Tablet Samsung Galaxy Tab A8');
      expect(bem.localizacao, 'Gabinete dos Professores');
      expect(bem.professorId, 2);
      expect(bem.professorNome, 'Prof. Carlos Drummond');
      expect(bem.estadoConservacao, 'Excelente');
    });

    test('aceita professorId e responsavelId como o mesmo vínculo', () {
      expect(
        PatrimonioModel.fromJson({'id': 1, 'responsavelId': 7}).professorId,
        7,
      );
    });

    test('status viram regras booleanas (RN05)', () {
      expect(bensDeTeste().first.emUso, isTrue);
      expect(bensDeTeste().first.disponivel, isFalse);
      expect(
        PatrimonioModel.fromJson({'id': 1, 'status': 'disponivel'}).disponivel,
        isTrue,
      );
      expect(
        PatrimonioModel.fromJson({
          'id': 1,
          'status': 'em_manutencao',
        }).emManutencao,
        isTrue,
      );
    });

    test('a data de atribuição sai formatada em dd/MM/yyyy', () {
      final bem = bensDeTeste().first;
      final data = bem.dataAtribuicao!;
      final esperado =
          '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      expect(bem.dataAtribuicaoFormatada, esperado);
    });

    test('bem sem atribuição não quebra a formatação', () {
      final p = PatrimonioModel.fromJson({'id': 1, 'codigo': 'PAT-1'});
      expect(p.dataAtribuicaoFormatada, '');
      expect(p.status, StatusPatrimonio.indefinido);
      expect(p.resumoEquipamento, '');
    });

    test('resumoEquipamento junta marca e modelo', () {
      expect(bensDeTeste().first.resumoEquipamento,
          'Samsung · Galaxy Tab A8 SM-X200');
    });
  });

  // =========================================================================
  group('ProfessorService (RF06)', () {
    test('listar() desempacota o envelope {total, professores}', () async {
      final api = ApiClientFalso(
          (_, _, _) async => payloadListaProfessores());
      final lista = await ProfessorService(api).listar();

      expect(api.chamadas, ['GET /admin/professores']);
      expect(lista.length, 2);
      expect(lista.first.totalPatrimonios, 3);
      expect(lista.last.totalPatrimonios, 1);
    });

    test('listar() devolve lista vazia quando o corpo não traz professores',
        () async {
      final api = ApiClientFalso((_, _, _) async => {'total': 0});
      expect(await ProfessorService(api).listar(), isEmpty);
    });

    test('cadastrar() envia o corpo e lê o professor do envelope', () async {
      final api = ApiClientFalso((metodo, caminho, body) async {
        expect(metodo, 'POST');
        expect(caminho, '/admin/professores');
        // RN02: o Coordinator define a senha provisória e o corpo não
        // manda `role` — o backend fixa "professor".
        final corpo = body! as Map;
        expect(corpo['password'], 'prof123');
        expect(corpo.containsKey('role'), isFalse);
        return {
          'message': 'Professor cadastrado com sucesso',
          'professor': {'id': 9, 'nome': 'Prof. Novo', 'email': 'novo@e.com'},
        };
      });

      final professor = await ProfessorService(api).cadastrar(
        ProfessorRequestModel(
          nome: 'Prof. Novo',
          email: 'novo@escola.com',
          senha: 'prof123',
        ),
      );

      expect(professor.id, 9);
      expect(professor.nome, 'Prof. Novo');
    });

    test('detalhe() monta a rota com o id e devolve docente + bens',
        () async {
      final api =
          ApiClientFalso((_, _, _) async => payloadDetalheProfessor());
      final detalhe = await ProfessorService(api).detalhe(2);

      expect(api.chamadas, ['GET /admin/professores/2']);
      expect(detalhe.professor.nome, 'Prof. Carlos Drummond');
      expect(detalhe.patrimonios.length, 2);
      expect(detalhe.totalPatrimonios, 2);
      expect(detalhe.semBens, isFalse);
    });

    test('detalhe() propaga o 403 como AppException (RN03)', () async {
      final api = ApiClientComErro(
        const AppException(
          'Acesso negado: privilégios de administrador necessários',
          statusCode: 403,
        ),
      );
      await expectLater(
        ProfessorService(api).detalhe(2),
        throwsA(isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.mensagem, 'mensagem', contains('Acesso negado'))),
      );
    });
  });

  // =========================================================================
  group('ProfessorListaController (RF06.1)', () {
    test('carrega a lista e calcula os indicadores do cabeçalho', () async {
      final api =
          ApiClientFalso((_, _, _) async => payloadListaProfessores());
      final controller = ProfessorListaController(ProfessorService(api));
      await controller.carregar();

      expect(controller.professores.length, 2);
      expect(controller.totalDocentes, 2);
      expect(controller.totalBens, 4); // 3 + 1
      expect(controller.carregando.value, isFalse);
      expect(controller.erro.value, isEmpty);
    });

    test('a busca filtra sem alterar a lista em memória', () async {
      final api =
          ApiClientFalso((_, _, _) async => payloadListaProfessores());
      final controller = ProfessorListaController(ProfessorService(api));
      await controller.carregar();

      controller.filtrar('maria');

      expect(controller.resultados.length, 1);
      expect(controller.resultados.first.nome, 'Profa. Maria Silva');
      // A lista completa continua intacta: limpar a busca a recupera.
      expect(controller.professores.length, 2);

      controller.filtrar('');
      expect(controller.resultados.length, 2);
    });

    test('buscaSemResultado distingue "sem docente" de "sem resultado"',
        () async {
      final controller = ProfessorListaController(
        ProfessorService(
            ApiClientFalso((_, _, _) async => payloadListaProfessores())),
      );
      await controller.carregar();
      controller.filtrar('zzz');
      expect(controller.buscaSemResultado, isTrue);

      final vazia = ProfessorListaController(
        ProfessorService(ApiClientFalso((_, _, _) async => {'total': 0})),
      );
      await vazia.carregar();
      expect(vazia.buscaSemResultado, isFalse);
    });

    test('erro do backend vira mensagem e lista vazia', () async {
      final controller = ProfessorListaController(
        ProfessorService(
          ApiClientComErro(
            const AppException('Recurso não encontrado.', statusCode: 404),
          ),
        ),
      );
      await controller.carregar();

      expect(controller.erro.value, 'Recurso não encontrado.');
      expect(controller.professores, isEmpty);
      expect(controller.carregando.value, isFalse);
    });

    test('recarregar() mantém o termo de busca', () async {
      final api =
          ApiClientFalso((_, _, _) async => payloadListaProfessores());
      final controller = ProfessorListaController(ProfessorService(api));
      await controller.carregar();
      controller.filtrar('maria');

      await controller.recarregar();

      expect(api.chamadas.length, 2);
      expect(controller.resultados.length, 1);
    });
  });

  // =========================================================================
  group('ProfessorCadastroController (RF06.2 / RN02)', () {
    late ProfessorCadastroController controller;
    late ApiClientFalso api;

    setUp(() {
      api = ApiClientFalso((_, _, _) async => {
            'message': 'ok',
            'professor': {
              'id': 7,
              'nome': 'Prof. Novo',
              'email': 'novo@e.com',
            },
          });
      controller = ProfessorCadastroController(ProfessorService(api));
    });

    test('valida nome, e-mail, senha e confirmação', () {
      expect(controller.validarNome('  '), 'Informe o nome.');
      expect(controller.validarEmail('nao-e-email'), 'Informe um e-mail válido.');
      expect(controller.validarSenha('123'),
          'A senha deve ter ao menos 6 caracteres.');

      controller.senhaCtrl.text = 'prof123';
      expect(controller.validarConfirmacao('outra'), 'As senhas não conferem.');
      expect(controller.validarConfirmacao('prof123'), isNull);
    });

    test('CPF e telefone são opcionais, mas validados quando informados', () {
      expect(controller.validarCpf('   '), isNull);
      expect(controller.validarCpf('123'), 'CPF deve ter 11 dígitos.');
      expect(controller.validarCpf('111.222.333-44'), 'CPF inválido.');
      expect(controller.validarCpf('529.982.247-25'), isNull);
      expect(controller.validarTelefone(''), isNull);
      expect(controller.validarTelefone('123456'), 'Telefone inválido.');
    });

    testWidgets('campos válidos disparam POST e montam o corpo', (tester) async {
      final formulario = await formStateDeTeste(tester);
      controller.nomeCtrl.text = 'Prof. Novo';
      controller.emailCtrl.text = 'novo@escola.com';
      controller.senhaCtrl.text = 'prof123';
      controller.matriculaCtrl.text = 'PROF-2024-09';
      controller.departamentoCtrl.text = 'Física';

      await controller.cadastrar(formulario);

      expect(api.chamadas, ['POST /admin/professores']);
      final corpo = api.corpos.first! as Map;
      expect(corpo['nome'], 'Prof. Novo');
      expect(corpo['email'], 'novo@escola.com');
      expect(corpo['password'], 'prof123');
      expect(corpo['matricula'], 'PROF-2024-09');
      expect(corpo['departamento'], 'Física');
      expect(controller.salvando.value, isFalse);
      expect(controller.erro.value, isEmpty);
      await drenarSnackbars(tester);
    });

    testWidgets('formulário reprovado não chega ao Service',
        (tester) async {
      final formulario = await formStateReprovado(tester);
      expect(formulario.validate(), isFalse);

      controller.nomeCtrl.text = 'Prof. Novo';
      controller.emailCtrl.text = 'novo@escola.com';
      controller.senhaCtrl.text = 'prof123';

      await controller.cadastrar(formulario);

      expect(api.chamadas, isEmpty);
      expect(controller.salvando.value, isFalse);
    });

    testWidgets('e-mail duplicado (409) mostra a mensagem do backend',
        (tester) async {
      final formulario = await formStateDeTeste(tester);
      final comErro = ProfessorCadastroController(
        ProfessorService(
          ApiClientComErro(
            const AppException(
              'Já existe um usuário/professor cadastrado com este e-mail',
              statusCode: 409,
            ),
          ),
        ),
      );
      comErro.nomeCtrl.text = 'Prof. Novo';
      comErro.emailCtrl.text = 'novo@escola.com';
      comErro.senhaCtrl.text = 'prof123';

      await comErro.cadastrar(formulario);

      expect(comErro.erro.value,
          'Já existe um usuário/professor cadastrado com este e-mail');
      expect(comErro.salvando.value, isFalse);
    });
  });

  // =========================================================================
  group('ProfessorCadastroView (RF06.2) — caminho completo', () {
    /// O formulário é mais alto que a viewport padrão do teste; rolar até
    /// o botão é o que um usuário faria no aparelho.
    Future<void> tocarEmCadastrar(WidgetTester tester) async {
      final botao = find.widgetWithText(ElevatedButton, 'Cadastrar professor');
      await tester.ensureVisible(botao);
      await tester.pump();
      await tester.tap(botao);
      await tester.pump();
    }

    testWidgets('validação local bloqueia e-mail inválido sem chamar a API',
        (tester) async {
      final api = await montarTelaCadastro(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo'), 'Prof. Novo');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail institucional'),
          'email-invalido');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha provisória'), 'prof123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar senha provisória'),
          'prof123');

      await tocarEmCadastrar(tester);

      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(api.chamadas, isEmpty);
    });

    testWidgets('envio válido chega ao Service', (tester) async {
      final api = await montarTelaCadastro(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo'), 'Prof. Novo');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail institucional'),
          'novo@escola.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha provisória'), 'prof123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar senha provisória'),
          'prof123');

      await tocarEmCadastrar(tester);
      await tester.pump();

      expect(api.chamadas, ['POST /admin/professores']);
      final corpo = api.corpos.first! as Map;
      expect(corpo['nome'], 'Prof. Novo');
      expect(corpo['password'], 'prof123');

      await drenarSnackbars(tester);
    });
  });

  // =========================================================================
  group('ProfessorDetalheController (RF06.3)', () {
    test('lê o id da rota e carrega docente + bens', () async {
      Get.testMode = true;
      Get.parameters = {'id': '2'};

      final api =
          ApiClientFalso((_, _, _) async => payloadDetalheProfessor());
      final controller = ProfessorDetalheController(ProfessorService(api));
      controller.onInit();
      await pumpEventQueue();

      expect(api.chamadas, ['GET /admin/professores/2']);
      expect(controller.professor!.nome, 'Prof. Carlos Drummond');
      expect(controller.patrimonios.length, 2);
      expect(controller.semBens, isFalse);
    });

    test('id ausente não chega a chamar a API', () async {
      Get.testMode = true;
      Get.parameters = {};

      final api =
          ApiClientFalso((_, _, _) async => payloadDetalheProfessor());
      final controller = ProfessorDetalheController(ProfessorService(api));
      controller.onInit();
      await pumpEventQueue();

      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, 'Professor não encontrado.');
    });

    test('professor sem bens cai no estado vazio', () async {
      Get.testMode = true;
      Get.parameters = {'id': '3'};

      final api = ApiClientFalso((_, _, _) async => {
            'professor': {
              'id': 3,
              'nome': 'Profa. Maria',
              'email': 'm@e.com',
            },
            'patrimonios': <Object>[],
          });
      final controller = ProfessorDetalheController(ProfessorService(api));
      controller.onInit();
      await pumpEventQueue();

      expect(controller.semBens, isTrue);
      expect(controller.patrimonios, isEmpty);
    });
  });

  // =========================================================================
  group('Widgets do RF06', () {
    testWidgets('CartaoProfessor mostra o contador de bens', (tester) async {
      var tocado = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CartaoProfessor(
              professor: professoresDeTeste().first,
              aoTocar: () => tocado = true,
            ),
          ),
        ),
      );

      expect(find.text('Prof. Carlos Drummond'), findsOneWidget);
      expect(find.text('3 bens sob responsabilidade'), findsOneWidget);
      expect(
          find.text('PROF-2024-01 · Língua Portuguesa e Literatura'),
          findsOneWidget);

      await tester.tap(find.byType(CartaoProfessor));
      expect(tocado, isTrue);
    });

    testWidgets('BadgeStatus traduz cada status', (tester) async {
      Future<void> pump(StatusPatrimonio status) => tester.pumpWidget(
            MaterialApp(
              theme: Tema.claro,
              home: Scaffold(body: BadgeStatus(status: status)),
            ),
          );

      await pump(StatusPatrimonio.emUso);
      expect(find.text('Em uso'), findsOneWidget);
      await pump(StatusPatrimonio.disponivel);
      expect(find.text('Disponível'), findsOneWidget);
      await pump(StatusPatrimonio.emManutencao);
      expect(find.text('Em manutenção'), findsOneWidget);
      await pump(StatusPatrimonio.indefinido);
      expect(find.text('Indefinido'), findsOneWidget);
    });

    testWidgets('CardPatrimonio exibe tombamento, local e data',
        (tester) async {
      final bem = bensDeTeste().first;

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(body: CardPatrimonio(patrimonio: bem)),
        ),
      );

      expect(find.text('Tablet Samsung Galaxy Tab A8'), findsOneWidget);
      expect(find.text('PAT-2024-003'), findsOneWidget);
      expect(find.text('Gabinete dos Professores'), findsOneWidget);
      expect(find.text('Em uso'), findsOneWidget);
      expect(find.text('Atribuído em ${bem.dataAtribuicaoFormatada}'),
          findsOneWidget);
    });

    testWidgets('CardPatrimonio sem ação é estritamente leitura (RN03)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: CardPatrimonio(
              patrimonio: PatrimonioModel.fromJson({'id': 1, 'codigo': 'PAT-1'}),
            ),
          ),
        ),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });

  // =========================================================================
  group('RBAC das telas de professores', () {
    test('AdminMiddleware libera o admin', () {
      final sessao = Get.put(SessaoService());
      loginEmMemoria(sessao, adminDeTeste());
      expect(AdminMiddleware().redirect(Rotas.professores), isNull);
    });

    test('AdminMiddleware devolve o docente ao próprio painel', () {
      final sessao = Get.put(SessaoService());
      loginEmMemoria(sessao, professorDeTeste());
      expect(
        AdminMiddleware().redirect(Rotas.professores)?.name,
        Rotas.homeProfessor,
      );
    });

    test('AdminMiddleware manda quem não tem sessão para o login', () {
      Get.put(SessaoService());
      expect(AdminMiddleware().redirect(Rotas.professores)?.name, Rotas.login);
    });

    test('as três rotas de professores exigem sessão e papel de admin', () {
      final paginaPor = {for (final p in AppRotas.paginas) p.name: p};

      for (final nome in [
        Rotas.professores,
        Rotas.professorNovo,
        Rotas.professorDetalhe,
      ]) {
        final pagina = paginaPor[nome]!;
        expect(pagina, isNotNull, reason: 'a rota $nome precisa existir');
        expect(
          pagina.middlewares!.any((m) => m is AutenticadoMiddleware),
          isTrue,
          reason: '$nome exige sessão',
        );
        expect(
          pagina.middlewares!.any((m) => m is AdminMiddleware),
          isTrue,
          reason: '$nome exige role admin',
        );
      }
    });

    test('a rota do detalhe declara o parâmetro :id', () {
      final pagina = AppRotas.paginas
          .firstWhere((p) => p.name == Rotas.professorDetalhe);
      expect(pagina.name, contains(':id'));
      expect(Rotas.detalheDeProfessor(7), '/admin/professores/detalhe/7');
    });

    test('a rota de perfil é liberada para os dois papéis', () {
      final pagina =
          AppRotas.paginas.firstWhere((p) => p.name == Rotas.perfil);
      expect(pagina.middlewares!.any((m) => m is AutenticadoMiddleware), isTrue);
      expect(pagina.middlewares!.any((m) => m is AdminMiddleware), isFalse);
    });
  });
}
