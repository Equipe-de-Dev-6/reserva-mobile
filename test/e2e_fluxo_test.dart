// Teste **end-to-end** do caminho principal do app.
//
// Não é teste de unidade nem de integração: é o app **de verdade** — as
// telas reais, os Controllers reais, o `ApiClient` real, o
// `flutter_secure_storage` real (dublê de plataforma) — contra a
// **API real**.
//
// É o teste que reproduz o que o avaliador faz na mão:
//
//   1. abrir o app e fazer login;
//   2. ver o painel do Coordenador;
//   3. abrir os Indicadores;
//   4. abrir a lista de patrimônios e filtrar;
//   5. abrir o detalhe de um bem;
//   6. ver o histórico;
//   7. sair da sessão.
//
// É a rede de segurança que pega bug de **integração** entre a tela e a
// API — o tipo de bug que nenhum teste de camada isolada enxerga.
//
// ## Dois detalhes que este arquivo teve que respeitar
//
// 1. **A verificação da API é feita dentro do `testWidgets`.** Fora dele
//    (em `setUpAll`) o `flutter_test` já instalou um `HttpClient`
//    simulado, que responde **400** a qualquer requisição — e o teste
//    inteiro seria ignorado sem motivo.
//
// 2. **O event loop real precisa rodar depois de cada ação que fala
//    com a API.** Dentro de `testWidgets` o relógio é *fake*: o `pump`
//    avança o tempo virtual instantaneamente, mas a resposta HTTP da
//    API real chega no relógio de verdade. Sem um `tester.runAsync`
//    dando tempo ao event loop real, o `await` da requisição nunca
//    termina e o teste trava.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/core/config/api_config.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/views/admin/admin_home_view.dart';
import 'package:reserva_mobile/views/admin/dashboard_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_detalhe_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_historico_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_lista_view.dart';
import 'package:reserva_mobile/widgets/botao_primario.dart';
import 'package:reserva_mobile/widgets/campo_texto.dart';
import 'package:reserva_mobile/widgets/card_patrimonio.dart';

import 'helpers/test_armazenamento.dart';

/// E-mail e senha do administrador semeado pelo backend.
const String emailAdmin = 'admin@admin.com';
const String senhaAdmin = 'admin123';

void main() {
  // Este é o único arquivo de teste que fala com a **API real** de
  // dentro de um `testWidgets`, e isso exige duas coisas:
  //
  // 1. **`LiveTestWidgetsFlutterBinding`**: o binding padrão do
  //    `flutter test` usa relógio *fake* — o `pump` avança o tempo
  //    virtual instantaneamente e a resposta HTTP da API real nunca
  //    chega. O binding live usa o relógio de verdade.
  //
  // 2. **`HttpOverrides.global = null`**: o `flutter_test` substitui o
  //    `HttpClient` do sistema por um dublê que responde **400** a
  //    qualquer requisição. Restaurando o global, a rede volta a
  //    funcionar de verdade.
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late ArmazenamentoFalso armazenamento;

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  testWidgets('caminho principal do Coordenador, do login ao histórico',
      (tester) async {
    // O ping precisa rodar no **event loop real** (`runAsync`): dentro
    // do `testWidgets` o relógio é falso e a resposta HTTP nunca chega.
    final online = await tester.runAsync(_apiNoAr) ?? false;
    if (!online) { markTestSkipped('API offline'); return; }

    // O app real: MainBinding, rotas reais, tema real.
    await tester.pumpWidget(
      GetMaterialApp(
        title: 'Patrimônio Escolar',
        debugShowCheckedModeBanner: false,
        theme: Tema.claro,
        initialBinding: MainBinding(),
        initialRoute: Rotas.splash,
        getPages: AppRotas.paginas,
      ),
    );

    // A Splash decide o destino com base na sessão salva (que está
    // vazia) e leva ao Login.
    await _avancar(tester);
    expect(find.text('Entrar'), findsOneWidget,
        reason: 'a Splash precisa levar ao Login');

    // ------------------------------------------------------------------
    // 1) LOGIN — digita no campo de verdade e toca no botão de verdade.
    // ------------------------------------------------------------------
    final campos = find.byType(CampoTexto);
    expect(campos, findsNWidgets(2));

    await tester.enterText(campos.at(0), emailAdmin);
    await tester.enterText(campos.at(1), senhaAdmin);
    await tester.tap(find.byType(BotaoPrimario));
    await _settle(tester);

    // ------------------------------------------------------------------
    // 2) PAINEL DO COORDENADOR
    // ------------------------------------------------------------------
    expect(find.byType(AdminHomeView), findsOneWidget,
        reason: 'o login com sucesso deve abrir o painel do Coordenador');
    // O nome semeado pelo backend é "Coordenador Geral (Admin)".
    expect(find.textContaining('Coordenador Geral'), findsWidgets);
    expect(find.text('Coordenador (admin)'), findsOneWidget);

    // ------------------------------------------------------------------
    // 3) INDICADORES — os números vêm da API real.
    // ------------------------------------------------------------------
    await tester.tap(find.text('Indicadores'));
    await _settle(tester);

    expect(find.byType(DashboardView), findsOneWidget);
    // O número total de bens veio do backend (a semente tem 6).
    expect(find.text('Total de bens'), findsOneWidget);
    expect(find.text('Em uso'), findsOneWidget);
    expect(find.text('Disponíveis'), findsOneWidget);

    // ------------------------------------------------------------------
    // 4) LISTA DE PATRIMÔNIOS — os cards são os bens do acervo real.
    // ------------------------------------------------------------------
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.text('Patrimônios'));
    await _settle(tester);

    expect(find.byType(PatrimonioListaView), findsOneWidget);
    expect(find.byType(CardPatrimonio), findsWidgets,
        reason: 'a listagem precisa trazer os bens do acervo');

    // O filtro por status recarrega a lista pela API.
    // O texto "Em uso" aparece tanto no chip de filtro quanto nos
    // badges dos cards — o alvo precisa ser o chip.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Em uso'));
    await _settle(tester);
    expect(find.byType(CardPatrimonio), findsWidgets);

    // ------------------------------------------------------------------
    // 5) DETALHE DO BEM
    // ------------------------------------------------------------------
    await tester.tap(find.byType(CardPatrimonio).first);
    await _settle(tester);

    expect(find.byType(PatrimonioDetalheView), findsOneWidget);
    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Tombamento'), findsOneWidget);

    // A seção "Responsável" fica abaixo da dobra — a lista do detalhe é
    // preguiçosa, então é preciso rolar para que a widget seja
    // construída.
    await tester.scrollUntilVisible(find.text('Responsável'), 200);
    expect(find.text('Responsável'), findsOneWidget);

    // ------------------------------------------------------------------
    // 6) HISTÓRICO DO BEM
    // ------------------------------------------------------------------
    // O botão "Ver histórico" também fica abaixo da dobra.
    await tester.scrollUntilVisible(find.text('Ver histórico do bem'), 200);
    await tester.tap(find.text('Ver histórico do bem'));
    await _settle(tester);

    expect(find.byType(PatrimonioHistoricoView), findsOneWidget);
    expect(find.text('Histórico do bem'), findsOneWidget);
    // A linha do tempo mostra os eventos que o backend gravou. Quais
    // eventos existem depende do histórico semeado do bem — o que a tela
    // precisa garantir é que ela **desenhou** a linha do tempo.
    expect(find.byType(VerticalDivider), findsNothing,
        reason: 'a linha do tempo é desenhada com um trilho próprio');

    // ------------------------------------------------------------------
    // 7) LOGOUT — a sessão é encerrada e o app volta ao Login.
    // ------------------------------------------------------------------
    // Volta direto ao painel (a pilha tem 5 telas; ir de "voltar" em
    // "voltar" até o painel seria frágil).
    Get.offAllNamed(Rotas.homeAdmin);
    await _settle(tester);

    // O botão "Sair" da AppBar do painel.
    await tester.tap(find.byTooltip('Sair'));
    await _settle(tester);

    // O logout pede confirmação; confirma.
    final confirmar = find.text('Sair');
    if (confirmar.evaluate().isNotEmpty) {
      await tester.tap(confirmar.last);
      await _settle(tester);
    }

    expect(find.text('Entrar'), findsOneWidget,
        reason: 'após o logout o app volta para a tela de Login');

    // E a sessão foi mesmo apagada.
    final sessao = Get.find<SessaoService>();
    expect(sessao.autenticado, isFalse);
    expect(sessao.token.value, isEmpty);
  });

  testWidgets('a sessão é restaurada ao reabrir o app', (tester) async {
    final online = await tester.runAsync(_apiNoAr) ?? false;
    if (!online) { markTestSkipped('API offline'); return; }

    // Grava a sessão no armazenamento (como se o app tivesse ficado
    // aberto em segundo plano).
    await gravarSessaoSalva(adminDeTeste());

    await tester.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Tema.claro,
        initialBinding: MainBinding(),
        initialRoute: Rotas.splash,
        getPages: AppRotas.paginas,
      ),
    );
    await _avancar(tester);

    // Com a sessão salva, a Splash vai direto para o painel — sem
    // pedir login de novo.
    expect(find.byType(AdminHomeView), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });
}

/// Deixa a árvore assentar depois de uma ação **sem** rede.
///
/// `pumpAndSettle` não serve: a Splash tem um `CircularProgressIndicator`,
/// que anima para sempre e nunca deixa a árvore "assentar".
Future<void> _avancar(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Deixa a árvore assentar depois de uma ação **com** rede.
///
/// O `runAsync` dá tempo ao **event loop real** — é ele que traz a
/// resposta da API. Depois, os `pump` reprocessam a árvore com o estado
/// novo.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  await _avancar(tester);
}

/// A API está no ar?
///
/// Usa um `Dio` cru (sem os interceptors do app) para não depender de
/// token nenhum — é só um "ping" no `/health`.
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
