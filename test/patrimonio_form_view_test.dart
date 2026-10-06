import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/patrimonio_form_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_criacao_model.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_form_view.dart';

/// Service de mentira que registra o corpo enviado.
class ServicoDeEscritaFake extends PatrimonioService {
  ServicoDeEscritaFake() : super(ApiClient(SessaoService()));

  Map<String, dynamic>? corpoEnviado;
  String? caminhoRecebido;
  int idAtualizado = 0;
  AppException? erro;

  @override
  Future<PatrimonioCriacaoModel> criar(PatrimonioModel patrimonio) async {
    caminhoRecebido = '/patrimonios';
    corpoEnviado = patrimonio.toJson();
    if (erro != null) throw erro!;
    return PatrimonioCriacaoModel(
      mensagem: 'Patrimônio cadastrado com sucesso',
      id: 7,
      codigo: patrimonio.codigo,
      status: StatusPatrimonio.disponivel,
    );
  }

  @override
  Future<void> atualizar(int id, PatrimonioModel patrimonio) async {
    caminhoRecebido = '/patrimonios/$id';
    corpoEnviado = patrimonio.toJsonAtualizacao();
    idAtualizado = id;
    if (erro != null) throw erro!;
  }
}

/// Bem já existente, para o modo de edição.
PatrimonioModel bemDeTeste() => const PatrimonioModel(
      id: 1,
      codigo: 'PAT-2024-001',
      nome: 'Notebook Dell Latitude 3420',
      descricao: 'Intel Core i5, 16GB RAM',
      categoria: 'Informática',
      marca: 'Dell',
      modelo: 'Latitude 3420',
      numeroSerie: 'DL-992831',
      estadoConservacao: 'Excelente',
      localizacao: 'Gabinete dos Professores - Mesa 04',
      status: StatusPatrimonio.emUso,
      professorId: 2,
      professorNome: 'Prof. Carlos Drummond',
      observacoes: 'Entregue com bolsa',
    );

/// Registra as dependências e devolve o Controller do formulário.
///
/// [bem] é informado **antes** do registro, porque o `Get.put` dispara o
/// `onInit` — e é lá que o Controller decide cadastro × edição e
/// preenche os campos. Montar o Controller à mão (em vez de
/// `Get.lazyPut`) é o que permite controlá-lo sem passar por
/// `Get.arguments`, que não tem setter.
PatrimonioFormController registrar(
  ServicoDeEscritaFake service, {
  PatrimonioModel? bem,
}) {
  Get.delete<PatrimonioService>(force: true);
  Get.delete<SessaoService>(force: true);
  Get.delete<PatrimonioFormController>(force: true);

  Get.put<SessaoService>(SessaoService()).usuario.value = UsuarioModel(
    nome: 'Coordenador',
    email: 'admin@escola.com',
    role: 'admin',
  );
  Get.put<PatrimonioService>(service);

  return Get.put<PatrimonioFormController>(
    PatrimonioFormController(service)..patrimonio = bem,
  );
}

/// Monta o formulário e espera o primeiro build.
Future<void> pumpForm(
  WidgetTester tester,
  ServicoDeEscritaFake service, {
  PatrimonioModel? emEdicao,
  Size tamanho = const Size(390, 844),
}) async {
  registrar(service, bem: emEdicao);

  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GetMaterialApp(theme: Tema.claro, home: const PatrimonioFormView()),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Navegação dentro do formulário
//
// O formulário é uma `ListView` longa, e o Flutter só constrói o que está
// perto da viewport. Sem rolar antes de interagir, um campo do fim da
// ficha nem existe na árvore: o `enterText` estoura com "No element" e
// um `expect` de texto falha sem motivo aparente. Todos os helpers
// abaixo rolam primeiro — é também o caminho que o usuário percorre.
// ---------------------------------------------------------------------------

Finder campo(String rotulo) => find.widgetWithText(TextFormField, rotulo);

/// Rola o formulário até um elemento ficar visível.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(
    alvo,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Digita em um campo, rolando até ele antes.
Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  final alvo = campo(rotulo);
  await rolarAte(tester, alvo);
  await tester.enterText(alvo, texto);
  await tester.pumpAndSettle();
}

/// Rola até o texto existir e confirma que ele está na tela.
Future<bool> textoVisivel(WidgetTester tester, String texto) async {
  final alvo = find.text(texto);
  await rolarAte(tester, alvo);
  return alvo.evaluate().isNotEmpty;
}

/// Rola até o botão de envio e clica.
Future<void> tocarEnvio(WidgetTester tester, String rotuloBotao) async {
  final botao = find.text(rotuloBotao);
  await rolarAte(tester, botao);
  await tester.tap(botao);
  await tester.pumpAndSettle();
}

/// Lê o texto atual de um campo, rolando até ele antes.
Future<String?> valorDoCampo(WidgetTester tester, String rotulo) async {
  final alvo = campo(rotulo);
  await rolarAte(tester, alvo);
  return tester.widget<TextFormField>(alvo).controller?.text;
}

/// `true` se o campo está habilitado.
Future<bool> campoHabilitado(WidgetTester tester, String rotulo) async {
  final alvo = campo(rotulo);
  await rolarAte(tester, alvo);
  return tester.widget<TextFormField>(alvo).enabled;
}

void main() {
  late ServicoDeEscritaFake service;

  setUp(() => service = ServicoDeEscritaFake());
  tearDown(Get.reset);

  group('PatrimonioFormView — cadastro (RF07a)', () {
    testWidgets('abre em modo de cadastro', (tester) async {
      await pumpForm(tester, service);

      expect(find.text('Novo patrimônio'), findsOneWidget);
      expect(campo('Código de tombamento'), findsOneWidget);

      // O botão fica no fim da ficha: precisa existir, mesmo fora da tela.
      await rolarAte(tester, find.text('Cadastrar bem'));
      expect(find.text('Cadastrar bem'), findsOneWidget);
    });

    testWidgets('o tombamento é gravado em maiúsculas', (tester) async {
      await pumpForm(tester, service);

      await digitar(tester, 'Código de tombamento', 'pat-2024-009');

      expect(await valorDoCampo(tester, 'Código de tombamento'),
          'PAT-2024-009');
    });

    testWidgets('sem tombamento e sem nome, o envio é bloqueado',
        (tester) async {
      await pumpForm(tester, service);

      await tocarEnvio(tester, 'Cadastrar bem');

      expect(service.corpoEnviado, isNull);
      expect(await textoVisivel(tester, 'Informe o código de tombamento.'),
          isTrue);
      expect(await textoVisivel(tester, 'Informe o nome do bem.'), isTrue);
    });

    testWidgets('cadastra com o corpo enviado ao backend', (tester) async {
      await pumpForm(tester, service);

      await digitar(tester, 'Código de tombamento', 'PAT-2024-009');
      await digitar(tester, 'Nome do bem', 'Projetor Laser');
      await digitar(tester, 'Marca', 'BenQ');

      await tocarEnvio(tester, 'Cadastrar bem');

      expect(service.caminhoRecebido, '/patrimonios');
      expect(service.corpoEnviado!['codigo'], 'PAT-2024-009');
      expect(service.corpoEnviado!['nome'], 'Projetor Laser');
      expect(service.corpoEnviado!['marca'], 'BenQ');
      // Um bem novo nasce disponível e sem professor: quem vincula é o
      // fluxo de atribuição (RF07b).
      expect(service.corpoEnviado!.containsKey('status'), isFalse);
      expect(service.corpoEnviado!.containsKey('professorId'), isFalse);
    });

    testWidgets('erro do backend aparece no formulário', (tester) async {
      service.erro =
          const AppException('Este registro já existe.', statusCode: 409);

      await pumpForm(tester, service);

      await digitar(tester, 'Código de tombamento', 'PAT-2024-001');
      await digitar(tester, 'Nome do bem', 'Repetido');
      await tocarEnvio(tester, 'Cadastrar bem');

      expect(await textoVisivel(tester, 'Este registro já existe.'), isTrue);
    });

    testWidgets('não gera overflow em iPhone SE (375x667)', (tester) async {
      await pumpForm(tester, service, tamanho: const Size(375, 667));

      expect(tester.takeException(), isNull);
    });

    testWidgets('não gera overflow em iPad', (tester) async {
      await pumpForm(tester, service, tamanho: const Size(1024, 1366));

      expect(tester.takeException(), isNull);
    });
  });

  group('PatrimonioFormView — edição (RF07a)', () {
    testWidgets('abre preenchido com os dados do bem', (tester) async {
      await pumpForm(tester, service, emEdicao: bemDeTeste());

      expect(find.text('Editar patrimônio'), findsOneWidget);

      expect(await valorDoCampo(tester, 'Código de tombamento'),
          'PAT-2024-001');
      expect(await valorDoCampo(tester, 'Nome do bem'),
          'Notebook Dell Latitude 3420');
      expect(await valorDoCampo(tester, 'Marca'), 'Dell');
      expect(await valorDoCampo(tester, 'Número de série'), 'DL-992831');
      expect(await valorDoCampo(tester, 'Onde está'),
          'Gabinete dos Professores - Mesa 04');

      await rolarAte(tester, find.text('Salvar alterações'));
      expect(find.text('Salvar alterações'), findsOneWidget);
    });

    testWidgets('o tombamento fica bloqueado na edição', (tester) async {
      await pumpForm(tester, service, emEdicao: bemDeTeste());

      // Tombamento muda por processo patrimonial, não por formulário.
      expect(await campoHabilitado(tester, 'Código de tombamento'), isFalse);
      expect(await textoVisivel(tester, 'O tombamento não pode ser alterado após o cadastro.'),
          isTrue);
    });

    testWidgets('salvar envia PUT sem o tombamento e sem desvincular o docente',
        (tester) async {
      await pumpForm(tester, service, emEdicao: bemDeTeste());

      await digitar(tester, 'Onde está', 'Sala 202');
      await tocarEnvio(tester, 'Salvar alterações');

      expect(service.caminhoRecebido, '/patrimonios/1');
      expect(service.idAtualizado, 1);
      expect(service.corpoEnviado!['localizacao'], 'Sala 202');
      expect(service.corpoEnviado!.containsKey('codigo'), isFalse);
      expect(service.corpoEnviado!.containsKey('professorId'), isFalse);

      // O vínculo é do RF07b: editar a ficha não pode soltar o bem.
      final controller = Get.find<PatrimonioFormController>();
      expect(controller.patrimonio!.professorId, 2);
    });

    testWidgets('o status do bem não é alterado pelo formulário',
        (tester) async {
      await pumpForm(tester, service, emEdicao: bemDeTeste());

      await digitar(tester, 'Marca', 'Dell Inc.');
      await tocarEnvio(tester, 'Salvar alterações');

      // Mudar status por aqui burlaria o ciclo de vida do bem (RF07b),
      // que grava histórico a cada mudança.
      expect(service.corpoEnviado!['status'], 'em_uso');
    });

    testWidgets('número de série com espaço é recusado', (tester) async {
      await pumpForm(tester, service, emEdicao: bemDeTeste());

      await digitar(tester, 'Número de série', 'DL 992831');
      await tocarEnvio(tester, 'Salvar alterações');

      expect(
        await textoVisivel(tester, 'O número de série não pode conter espaços.'),
        isTrue,
      );
      expect(service.corpoEnviado, isNull);
    });
  });
}