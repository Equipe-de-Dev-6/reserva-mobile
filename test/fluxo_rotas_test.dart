import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/widgets/botao_primario.dart';
import 'package:reserva_mobile/widgets/campo_texto.dart';

import 'helpers/test_armazenamento.dart';

/// Monta o app com as mesmas configurações do `main.dart`.
///
/// Quando [usuarioLogado] é informado, a sessão é gravada no
/// [ArmazenamentoFalso] **antes** do app subir. O [SplashController]
/// então a restaura pelo mesmo caminho do app real, o que exercita a
/// persistência de ponta a ponta.
Future<void> _montarApp(
  WidgetTester tester, {
  UsuarioModel? usuarioLogado,
}) async {
  if (usuarioLogado != null) {
    await gravarSessaoSalva(usuarioLogado);
  }

  await tester.pumpWidget(
    GetMaterialApp(
      title: 'Patrimônio Escolar',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro,
      // Usa o MainBinding de verdade: é ele que o app usa, e testá-lo
      // aqui protege contra regressões no grafo de dependências.
      initialBinding: MainBinding(),
      initialRoute: Rotas.splash,
      getPages: AppRotas.paginas,
    ),
  );
}

/// Avança o tempo suficiente para a Splash decidir o destino e a
/// transição de rota terminar.
///
/// Usa `pump` com durações explícitas em vez de `pumpAndSettle`
/// porque a Splash tem um `CircularProgressIndicator`, que anima
/// para sempre e nunca deixa a árvore "assentar".
Future<void> _avancarAteLogin(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  late ArmazenamentoFalso armazenamento;

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  group('Fluxo de rotas (RF01)', () {
    testWidgets('sem sessão, a Splash leva para a tela de Login', (tester) async {
      await _montarApp(tester);

      // Primeiro frame: a Splash ainda está visível.
      expect(find.text('Sistema Integrado de Gestão'), findsOneWidget);

      await _avancarAteLogin(tester);

      expect(find.text('Patrimônio Escolar'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Cadastrar Coordenador'), findsOneWidget);
    });

    testWidgets('a tela de Login exibe dois campos e um botão', (tester) async {
      await _montarApp(tester);
      await _avancarAteLogin(tester);

      expect(find.byType(CampoTexto), findsNWidgets(2));
      expect(find.byType(BotaoPrimario), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
    });

    testWidgets('validação local bloqueia e-mail inválido sem chamar a API',
        (tester) async {
      await _montarApp(tester);
      await _avancarAteLogin(tester);

      await tester.enterText(find.byType(CampoTexto).first, 'email-invalido');
      await tester.enterText(find.byType(CampoTexto).last, '123');
      await tester.tap(find.byType(BotaoPrimario));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // A mensagem vem do Controller, sem tocar na rede.
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      // E o usuário continua na tela de login.
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('validação exige senha com 6 caracteres', (tester) async {
      await _montarApp(tester);
      await _avancarAteLogin(tester);

      await tester.enterText(
          find.byType(CampoTexto).first, 'admin@escola.com');
      await tester.enterText(find.byType(CampoTexto).last, '123');
      await tester.tap(find.byType(BotaoPrimario));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('A senha deve ter ao menos 6 caracteres.'),
          findsOneWidget);
    });
  });

  group('Roteamento condicional por role (RBAC)', () {
    testWidgets('admin logado vai direto ao painel administrativo',
        (tester) async {
      await _montarApp(
        tester,
        usuarioLogado: UsuarioModel(
          id: 1,
          nome: 'Coordenador Geral',
          email: 'admin@escola.com',
          role: 'admin',
        ),
      );
      await _avancarAteLogin(tester);

      expect(find.text('Painel do Coordenador'), findsOneWidget);
      expect(find.text('Módulo 2 em construção'), findsOneWidget);
      expect(find.text('Coordenador Geral'), findsOneWidget);
      expect(find.text('Coordenador (admin)'), findsOneWidget);
    });

    testWidgets('professor logado vai direto ao painel do docente',
        (tester) async {
      await _montarApp(
        tester,
        usuarioLogado: UsuarioModel(
          id: 2,
          nome: 'Prof. Carlos Drummond',
          email: 'professor@escola.com',
          role: 'professor',
        ),
      );
      await _avancarAteLogin(tester);

      expect(find.text('Meus Patrimônios'), findsOneWidget);
      expect(find.text('Módulo 3 em construção'), findsOneWidget);
      expect(find.text('Prof. Carlos Drummond'), findsOneWidget);
      expect(find.text('Professor (docente)'), findsOneWidget);
    });
  });

  group('Guards de rota', () {
    testWidgets('usuário logado é bloqueado na tela de Login', (tester) async {
      await _montarApp(
        tester,
        usuarioLogado: UsuarioModel(
          nome: 'Coordenador Geral',
          email: 'admin@escola.com',
          role: 'admin',
        ),
      );
      await _avancarAteLogin(tester);

      // Tenta voltar para a tela de Login: a guarda deve redirecionar
      // de volta ao painel administrativo.
      Get.toNamed(Rotas.login);
      await _avancarAteLogin(tester);

      expect(find.text('Painel do Coordenador'), findsOneWidget);
    });

    testWidgets('usuário sem sessão é bloqueado nos painéis', (tester) async {
      await _montarApp(tester);
      await _avancarAteLogin(tester);

      Get.toNamed(Rotas.homeAdmin);
      await _avancarAteLogin(tester);

      expect(find.text('Painel do Coordenador'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });
}
