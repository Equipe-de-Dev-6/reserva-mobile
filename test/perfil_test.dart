import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/perfil_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/perfil_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/perfil_request.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/perfil/perfil_view.dart';

import 'helpers/api_client_falso.dart';
import 'helpers/test_armazenamento.dart';

// ---------------------------------------------------------------------------
// Ajudantes
// ---------------------------------------------------------------------------

/// Monta um [PerfilService] sobre um `ApiClient` dublê.
PerfilService servicoDeTeste(ApiClient api, SessaoService sessao) =>
    PerfilService(api, sessao);

/// Cria um `FormState` de verdade (o Controller recebe o `FormState` da
/// View — decisão documentada no `AuthController`).
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

/// Testes do RF09 (Perfil) e do RN06 (autonomia sobre os próprios
/// dados), sem depender do backend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArmazenamentoFalso armazenamento;

  setUp(() {
    // O `PerfilController` grava o perfil no armazenamento seguro ao
    // sincronizar a sessão; dentro de `testWidgets` o canal de
    // plataforma precisa do dublê.
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  // =========================================================================
  group('AtualizarPerfilRequestModel — corpo do PUT /profile', () {
    test('descarta os campos não informados', () {
      final request = AtualizarPerfilRequestModel(telefone: '(11) 98888-7777');

      // O backend aplica só o que chega e responde 400 se nada chegar.
      expect(request.toJson(), {'telefone': '(11) 98888-7777'});
      expect(request.vazio, isFalse);
    });

    test('um corpo sem nenhum campo é reconhecido como vazio', () {
      expect(AtualizarPerfilRequestModel().vazio, isTrue);
      expect(AtualizarPerfilRequestModel().toJson(), isEmpty);
    });

    test('envia todos os campos aceitos quando informados', () {
      final request = AtualizarPerfilRequestModel(
        nome: '  Prof. Novo Nome  ',
        telefone: ' (11) 98888-7777 ',
        departamento: ' Física ',
        endereco: ' Rua A, 10 ',
        cidadeUf: ' São Paulo / SP ',
        contatoEmergencia: ' Helena (11) 90000-0000 ',
      );

      expect(request.toJson(), {
        'nome': 'Prof. Novo Nome', // espaços das pontas removidos
        'telefone': '(11) 98888-7777',
        'departamento': 'Física',
        'endereco': 'Rua A, 10',
        'cidadeUf': 'São Paulo / SP',
        'contatoEmergencia': 'Helena (11) 90000-0000',
      });
    });

    test('campo explicitamente vazio é enviado (limpar o dado)', () {
      final request =
          AtualizarPerfilRequestModel(telefone: '', contatoEmergencia: null);
      expect(request.toJson(), {'telefone': ''});
      expect(request.vazio, isFalse);
    });

    test('a troca de senha usa a chave newPassword', () {
      expect(AlterarSenhaRequestModel(novaSenha: 'novaSenha1').toJson(),
          {'newPassword': 'novaSenha1'});
    });
  });

  // =========================================================================
  group('PerfilService — GET e PUT /profile', () {
    test('meuPerfil() lê o UserResponse', () async {
      final api = ApiClientFalso((_, _, _) async => payloadPerfil());
      final usuario = await servicoDeTeste(api, SessaoService()).meuPerfil();

      expect(api.chamadas, ['GET /profile']);
      expect(usuario.nome, 'Prof. Carlos Drummond');
      expect(usuario.role, 'professor');
      expect(usuario.totalPatrimonios, 3);
    });

    test('atualizarDados() usa PUT e desembrulha o envelope {message, user}',
        () async {
      final api = ApiClientFalso((_, _, _) async => payloadPerfilAtualizado());
      final usuario = await servicoDeTeste(api, SessaoService()).atualizarDados(
        AtualizarPerfilRequestModel(telefone: '(11) 98888-7777'),
      );

      expect(api.chamadas, ['PUT /profile']);
      expect(api.corpos.first, {'telefone': '(11) 98888-7777'});
      expect(usuario.telefone, '(11) 98888-7777');
    });

    test('atualizarDados() também aceita o corpo direto, sem envelope',
        () async {
      // Blindagem: se o backend mudar o formato, a tela continua
      // funcionando em vez de quebrar com usuário vazio.
      final api = ApiClientFalso((_, _, _) async => payloadPerfil());
      final usuario = await servicoDeTeste(api, SessaoService()).atualizarDados(
        AtualizarPerfilRequestModel(telefone: '(11) 98888-7777'),
      );

      expect(usuario.nome, 'Prof. Carlos Drummond');
    });

    test('alterarSenha() viaja no mesmo endpoint (RN06)', () async {
      final api = ApiClientFalso((_, _, _) async => payloadPerfil());
      await servicoDeTeste(api, SessaoService())
          .alterarSenha(AlterarSenhaRequestModel(novaSenha: 'novaSenha1'));

      expect(api.chamadas, ['PUT /profile']);
      expect(api.corpos.first, {'newPassword': 'novaSenha1'});
    });

    test('erro 400 do backend chega como AppException', () async {
      final api = ApiClientComErro(
        const AppException(
          'A nova senha deve ter no mínimo 6 caracteres',
          statusCode: 400,
        ),
      );
      await expectLater(
        servicoDeTeste(api, SessaoService())
            .alterarSenha(AlterarSenhaRequestModel(novaSenha: '123')),
        throwsA(
            isA<AppException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  // =========================================================================
  group('PerfilController — GET /profile', () {
    late SessaoService sessao;
    late ApiClientFalso api;
    late PerfilController controller;

    PerfilController criar() {
      sessao = SessaoService();
      api = ApiClientFalso((_, _, _) async => payloadPerfil());
      return PerfilController(servicoDeTeste(api, sessao), sessao);
    }

    test('carrega o perfil e preenche os campos do formulário', () async {
      controller = criar();
      await controller.carregar();

      expect(controller.perfil.value!.email, 'professor@escola.com');
      expect(controller.nomeCtrl.text, 'Prof. Carlos Drummond');
      expect(controller.telefoneCtrl.text, '(11) 98765-1001');
      expect(
          controller.departamentoCtrl.text, 'Língua Portuguesa e Literatura');
      expect(controller.carregando.value, isFalse);
      expect(controller.erro.value, isEmpty);
    });

    test('falha no GET mostra a mensagem e mantém a tela em erro', () async {
      controller = PerfilController(
        PerfilService(
          ApiClientComErro(
            const AppException(
              'Não foi possível conectar ao servidor. Confira sua internet '
              'e o endereço da API.',
            ),
          ),
          SessaoService(),
        ),
        SessaoService(),
      );
      await controller.carregar();

      expect(controller.perfil.value, isNull);
      expect(controller.erro.value, contains('Não foi possível conectar'));
      expect(controller.carregando.value, isFalse);
    });

    test('onInit carrega automaticamente ao abrir a tela', () async {
      controller = criar();
      controller.onInit();
      await pumpEventQueue();

      expect(api.chamadas, ['GET /profile']);
      expect(controller.perfil.value, isNotNull);
    });
  });

  // =========================================================================
  group('PerfilController — PUT /profile dos dados (RF09 / RN06)', () {
    late SessaoService sessao;
    late ApiClientFalso api;
    late PerfilController controller;
    /// O `GET /profile` devolve o `UserResponse` solto e o `PUT` devolve
    /// o envelope `{"message", "user"}` — o dublê reproduz os dois.
    PerfilController criar({Map<String, dynamic>? respostaPut}) {
      sessao = SessaoService();
      api = ApiClientFalso((metodo, _, _) async => metodo == 'PUT'
          ? respostaPut ?? payloadPerfilAtualizado()
          : payloadPerfil());
      return PerfilController(servicoDeTeste(api, sessao), sessao);
    }

    test('a tela começa no modo leitura e abre a edição sob comando',
        () async {
      controller = criar();
      await controller.carregar();

      expect(controller.editando.value, isFalse);
      controller.abrirEdicao();
      expect(controller.editando.value, isTrue);
      controller.fecharEdicao();
      expect(controller.editando.value, isFalse);
    });

    testWidgets('salvar sem mexer em nada não chama a API (evita o 400)',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirEdicao();

      await controller.salvarDados(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile']);
      expect(controller.aviso.value, 'Nenhum dado foi alterado.');
      expect(controller.editando.value, isTrue); // continua editando
    });

    testWidgets('envia apenas o campo alterado e volta ao modo leitura',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirEdicao();

      controller.telefoneCtrl.text = '(11) 97777-6666';
      await controller.salvarDados(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile', 'PUT /profile']);
      // Um único campo no corpo: nome e departamento continuam no
      // servidor sem serem reenviados.
      expect(api.corpos.last, {'telefone': '(11) 97777-6666'});
      expect(controller.editando.value, isFalse);
      expect(controller.aviso.value, 'Dados atualizados com sucesso.');
      // O valor exibido é o que o **servidor** devolveu, não o que foi
      // digitado: a tela reflete a fonte de verdade.
      expect(controller.perfil.value!.telefone, '(11) 98888-7777');
    });

    testWidgets('descartar edição devolve os campos ao valor do servidor',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirEdicao();

      controller.telefoneCtrl.text = '(11) 00000-0000';
      controller.fecharEdicao();

      expect(controller.telefoneCtrl.text, '(11) 98765-1001');
      expect(api.chamadas, ['GET /profile']); // nada foi enviado
    });

    testWidgets('telefone inválido é barrado na validação local',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirEdicao();

      controller.telefoneCtrl.text = '123';
      await controller.salvarDados(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile']);
      expect(controller.erro.value, 'Telefone inválido.');
    });

    testWidgets('erro do backend fica visível sem fechar a edição',
        (tester) async {
      sessao = SessaoService();
      final comErro = PerfilController(
        PerfilService(
          ApiClientComErro(
            const AppException('Recurso não encontrado.', statusCode: 404),
          ),
          sessao,
        ),
        sessao,
      );
      await comErro.carregar();
      comErro.abrirEdicao();
      comErro.telefoneCtrl.text = '(11) 97777-6666';

      await comErro.salvarDados(await formStateDeTeste(tester));

      expect(comErro.erro.value, 'Recurso não encontrado.');
      expect(comErro.editando.value, isTrue);
      expect(comErro.salvando.value, isFalse);
    });

    testWidgets(
        'sincroniza a sessão, para o cabeçalho do app refletir o nome novo',
        (tester) async {
      sessao = SessaoService();
      // O GET devolve o perfil completo (contador = 3); o PUT devolve o
      // mesmo usuário com o contador zerado, que é o comportamento real
      // do backend. É por isso que o Controller precisa preservar o
      // contador que o GET conhecia.
      api = ApiClientFalso((metodo, _, _) async => metodo == 'PUT'
          ? {
              'message': 'ok',
              'user': {
                ...payloadPerfil(),
                'nome': 'Prof. Carlos Drummond de Andrade',
                'telefone': '(11) 97777-6666',
                // O PUT /profile devolve o contador zerado.
                'totalPatrimonios': 0,
              },
            }
          : payloadPerfil());
      controller = PerfilController(servicoDeTeste(api, sessao), sessao);
      await controller.carregar();
      controller.abrirEdicao();
      controller.telefoneCtrl.text = '(11) 97777-6666';

      await controller.salvarDados(await formStateDeTeste(tester));

      expect(sessao.usuario.value!.nome, 'Prof. Carlos Drummond de Andrade');
      expect(sessao.usuario.value!.telefone, '(11) 97777-6666');
      // O contador que o GET conhecia foi preservado: mostrar 0 aqui
      // seria exibir dado falso na tela.
      expect(sessao.usuario.value!.totalPatrimonios, 3);
      expect(controller.perfil.value!.totalPatrimonios, 3);
    });
  });

  // =========================================================================
  group('PerfilController — PUT /profile da senha (RF09)', () {
    late SessaoService sessao;
    late ApiClientFalso api;
    late PerfilController controller;

    PerfilController criar() {
      sessao = SessaoService();
      api = ApiClientFalso((_, _, _) async => payloadPerfil());
      return PerfilController(servicoDeTeste(api, sessao), sessao);
    }

    testWidgets('a confirmação da senha é conferida antes de chamar a API',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirSenha();

      controller.novaSenhaCtrl.text = 'novaSenha1';
      controller.confirmarSenhaCtrl.text = 'outraSenha';
      await controller.alterarSenha(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile']);
      expect(controller.erro.value, 'As senhas não conferem.');
    });

    testWidgets('senha curta é barrada na validação local', (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirSenha();

      controller.novaSenhaCtrl.text = '123';
      controller.confirmarSenhaCtrl.text = '123';
      await controller.alterarSenha(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile']);
      expect(controller.erro.value, 'A senha deve ter ao menos 6 caracteres.');
    });

    testWidgets('senha válida vai sozinha no corpo e limpa o formulário',
        (tester) async {
      controller = criar();
      await controller.carregar();
      controller.abrirSenha();

      controller.novaSenhaCtrl.text = 'novaSenha1';
      controller.confirmarSenhaCtrl.text = 'novaSenha1';
      await controller.alterarSenha(await formStateDeTeste(tester));

      expect(api.chamadas, ['GET /profile', 'PUT /profile']);
      // Só a senha: os dados de contato não são reenviados junto.
      expect(api.corpos.last, {'newPassword': 'novaSenha1'});
      expect(controller.novaSenhaCtrl.text, isEmpty);
      expect(controller.confirmarSenhaCtrl.text, isEmpty);
      expect(controller.aviso.value, 'Senha alterada com sucesso.');
      expect(controller.editandoSenha.value, isTrue);
    });

    test('fechar o formulário de senha descarta o que foi digitado',
        () async {
      controller = criar();
      await controller.carregar();
      controller.abrirSenha();
      controller.novaSenhaCtrl.text = 'novaSenha1';

      controller.fecharSenha();

      expect(controller.editandoSenha.value, isFalse);
      expect(controller.novaSenhaCtrl.text, isEmpty);
      expect(api.chamadas, ['GET /profile']);
    });

    test('onClose libera os controllers de texto', () async {
      controller = criar();
      await controller.carregar();
      controller.onClose();
      // Se algum controller fosse esquecido no onClose, o leak tracker
      // do `flutter test` acusaria o vazamento ao fim do teste.
      expect(controller.nomeCtrl.text, '');
    });
  });

  // =========================================================================
  group('PerfilView (RF09)', () {
    /// Registra as dependências e monta só a tela de Perfil, com um
    /// `ApiClient` dublê. É o mesmo caminho do app: rota → binding →
    /// Controller → Service.
    Future<PerfilController> montarTela(
      WidgetTester tester, {
      required ApiClient api,
    }) async {
      Get.put<ApiClient>(api, permanent: true);
      Get.put<SessaoService>(SessaoService(), permanent: true);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: Tema.claro,
          initialRoute: Rotas.perfil,
          getPages: [
            GetPage(
              name: Rotas.perfil,
              page: () => const PerfilView(),
              binding: PerfilBinding(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return Get.find<PerfilController>();
    }

    testWidgets('mostra os dados cadastrais em modo leitura', (tester) async {
      await montarTela(
        tester,
        api: ApiClientFalso((_, _, _) async => payloadPerfil()),
      );

      expect(find.text('Prof. Carlos Drummond'), findsWidgets);
      // O e-mail aparece no cabeçalho e na ficha de dados.
      expect(find.text('professor@escola.com'), findsWidgets);
      expect(find.text('PROF-2024-01'), findsOneWidget);
      expect(find.text('(11) 98765-1001'), findsOneWidget);
      // Campos em branco viram "Não informado", nunca espaço vazio.
      expect(find.text('Não informado'), findsWidgets);
      // Nenhum campo de formulário aberto no início.
      expect(find.byType(TextFormField), findsNothing);
      // O `TituloSecao` desenha o texto em caixa alta, e o bloco de
      // senha fica abaixo da dobra — é preciso rolar para construí-lo.
      await tester.scrollUntilVisible(find.text('ALTERAR SENHA'), 200);
      expect(find.text('ALTERAR SENHA'), findsWidgets);
    });

    testWidgets('"Editar" abre o formulário já preenchido', (tester) async {
      await montarTela(
        tester,
        api: ApiClientFalso((_, _, _) async => payloadPerfil()),
      );

      // `TextButton.icon` devolve um `_TextButtonWithIcon`, que não casa
      // com `find.byType(TextButton)`. Buscar pelo texto funciona nos
      // dois casos.
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      final campoNome = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome'),
      );
      expect(campoNome.controller?.text, 'Prof. Carlos Drummond');
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(find.text('Descartar alterações'), findsOneWidget);
    });

    testWidgets('salvar o telefone reflete o valor novo na tela',
        (tester) async {
      final api = ApiClientFalso((_, _, body) async {
        if (body is Map && body.containsKey('telefone')) {
          return {
            'message': 'ok',
            'user': {...payloadPerfil(), ...body},
          };
        }
        return payloadPerfil();
      });

      await montarTela(tester, api: api);

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone'),
        '(11) 97777-6666',
      );

      final salvar =
          find.widgetWithText(ElevatedButton, 'Salvar alterações');
      await tester.ensureVisible(salvar);
      await tester.pumpAndSettle();
      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(
        api.corpos.where((c) => c is Map && c.containsKey('telefone')),
        isNotEmpty,
        reason: 'o PUT /profile deve receber o telefone alterado',
      );
      expect(find.text('Dados atualizados com sucesso.'), findsOneWidget);
      expect(find.text('(11) 97777-6666'), findsWidgets);
    });

    testWidgets('falha de rede mostra mensagem com "Tentar novamente"',
        (tester) async {
      await montarTela(
        tester,
        api: ApiClientComErro(
          const AppException(
            'Não foi possível conectar ao servidor. Confira sua internet '
            'e o endereço da API.',
          ),
        ),
      );

      expect(
        find.textContaining('Não foi possível conectar ao servidor'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });

  // =========================================================================
  group('UsuarioModel.copyWith — sincronização do perfil', () {
    test('altera só os campos informados', () {
      final original = UsuarioModel.fromJson(payloadPerfil());
      final copia =
          original.copyWith(nome: 'Outro Nome', totalPatrimonios: 7);

      expect(copia.nome, 'Outro Nome');
      expect(copia.totalPatrimonios, 7);
      expect(copia.email, original.email);
      expect(copia.telefone, original.telefone);
      expect(copia.role, 'professor');
    });

    test('sem argumentos devolve um perfil equivalente', () {
      final original = UsuarioModel.fromJson(payloadPerfil());
      expect(original.copyWith().totalPatrimonios, original.totalPatrimonios);
      expect(original.copyWith().nome, original.nome);
    });
  });
}
