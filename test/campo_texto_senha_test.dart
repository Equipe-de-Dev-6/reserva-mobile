// Testes de regressão do botão **mostrar/ocultar senha**.
//
// O botão não funcionava em **nenhum** dos 9 campos de senha do app,
// por dois bugs somados:
//
// 1. **Toggle duplo** — as telas passavam o `RxBool` do Controller
//    (`obscureText:`) **e** um callback que alternava o mesmo `RxBool`
//    (`aoAlternarVisibilidade:`). O botão invertia a visibilidade duas
//    vezes, e a senha voltava a ficar oculta.
//
// 2. **Sem reconstrução** — o `TextFormField` lia o `RxBool` fora de um
//    `Obx`. O `toggle()` mudava o valor, mas a tela não se redesenhava:
//    o ícone não mudava e o campo continuava mascarado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/perfil_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/controllers/auth_controller.dart';
import 'package:reserva_mobile/controllers/perfil_controller.dart';
import 'package:reserva_mobile/views/auth/login_view.dart';
import 'package:reserva_mobile/views/perfil/perfil_view.dart';
import 'package:reserva_mobile/widgets/campo_texto.dart';

import 'helpers/api_client_falso.dart';

/// O `TextFormField` não expõe `obscureText`: ele repassa o valor para o
/// `EditableText` interno, e é lá que a máscara realmente é aplicada.
///
/// [indice] escolhe qual campo (0 = o primeiro da tela).
bool _obscuro(WidgetTester tester, [int indice = 0]) {
  final campos = tester.widgetList<EditableText>(find.byType(EditableText));
  return campos.elementAt(indice).obscureText;
}

void main() {
  tearDown(Get.reset);

  group('CampoTexto — mostrar/ocultar senha', () {
    testWidgets('com RxBool externo, o botão revela a senha', (tester) async {
      final senhaOculta = true.obs;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CampoTexto(
              rotulo: 'Senha',
              senha: true,
              obscureText: senhaOculta,
            ),
          ),
        ),
      );

      // Começa oculta.
      expect(senhaOculta.value, isTrue);
      expect(
        _obscuro(tester),
        isTrue,
      );
      expect(find.byTooltip('Mostrar senha'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      // O valor mudou **uma** vez e a tela se redesenhou.
      expect(senhaOculta.value, isFalse);
      expect(
        _obscuro(tester),
        isFalse,
        reason: 'a senha precisa ficar visível depois do toque',
      );
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);

      // E volta a ocultar.
      await tester.tap(find.byTooltip('Ocultar senha'));
      await tester.pump();

      expect(senhaOculta.value, isTrue);
      expect(
        _obscuro(tester),
        isTrue,
      );
    });

    testWidgets('o botão alterna uma única vez (sem toggle duplo)',
        (tester) async {
      final senhaOculta = true.obs;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CampoTexto(
              rotulo: 'Senha',
              senha: true,
              obscureText: senhaOculta,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      // Um clique = uma inversão. Com o bug do toggle duplo, o valor
      // voltaria para `true` e a senha nunca apareceria.
      expect(senhaOculta.value, isFalse);
    });

    testWidgets('dois campos com o mesmo RxBool alternam juntos',
        (tester) async {
      final senhaOculta = true.obs;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CampoTexto(
                  rotulo: 'Senha',
                  senha: true,
                  obscureText: senhaOculta,
                ),
                CampoTexto(
                  rotulo: 'Confirmar senha',
                  senha: true,
                  obscureText: senhaOculta,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Mostrar senha').first);
      await tester.pump();

      expect(senhaOculta.value, isFalse);
      // Os dois campos refletem o mesmo estado.
      final campos = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .toList();
      expect(campos.every((c) => !c.obscureText), isTrue);
    });

    testWidgets('no modo interno (sem RxBool), o botão também funciona',
        (tester) async {
      var avisos = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampoTexto(
              rotulo: 'Senha',
              senha: true,
              aoAlternarVisibilidade: () => avisos++,
            ),
          ),
        ),
      );

      expect(
        _obscuro(tester),
        isTrue,
      );

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      expect(
        _obscuro(tester),
        isFalse,
      );
      expect(avisos, 1, reason: 'o callback é chamado uma vez por toque');
    });

    testWidgets('campo sem senha não ganha botão de olho', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CampoTexto(rotulo: 'E-mail')),
        ),
      );

      expect(find.byTooltip('Mostrar senha'), findsNothing);
      expect(find.byTooltip('Ocultar senha'), findsNothing);
    });
  });

  // =========================================================================
  group('Tela real — o botão funciona dentro do app', () {
    testWidgets('Login: tocar no olho revela a senha', (tester) async {
      // Monta a **tela real**, com o Controller real — não só o widget
      // isolado. É aqui que o botão falhava.
      final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      Get.put<ApiClient>(ApiClientFalso((_, _, _) async => <String, dynamic>{}),
          permanent: true);
      Get.put<AuthService>(
        AuthService(Get.find<ApiClient>(), sessao),
        permanent: true,
      );
      final controller =
          Get.put<AuthController>(AuthController(Get.find<AuthService>()));

      await tester.pumpWidget(
        GetMaterialApp(
          home: const LoginView(),
        ),
      );
      await tester.pump();

      // Na tela de Login o campo de senha é o **segundo**.
      expect(_obscuro(tester, 1), isTrue);

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      expect(controller.senhaOculta.value, isFalse);
      expect(_obscuro(tester, 1), isFalse,
          reason: 'a senha precisa ficar visível na tela real');
    });

    testWidgets('Perfil: tocar no olho revela as duas senhas',
        (tester) async {
      // Janela alta: o bloco de senha fica abaixo da dobra e, em um
      // `ListView`, não seria nem construído.
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      Get.put<ApiClient>(
        ApiClientFalso((_, _, _) async => payloadPerfil()),
        permanent: true,
      );
      Get.put<PerfilService>(
        PerfilService(Get.find<ApiClient>(), sessao),
        permanent: true,
      );
      final controller = Get.put<PerfilController>(
        PerfilController(Get.find<PerfilService>(), sessao),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: const PerfilView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Abre o formulário de senha pelo Controller (o bloco fica abaixo da
      // dobra) e confere o botão de olho.
      controller.abrirSenha();
      await tester.pump(const Duration(milliseconds: 400));

      // Há dois campos de senha ("Nova senha" e "Confirmar nova senha") e
      // eles compartilham o mesmo `RxBool`.
      expect(find.byTooltip('Mostrar senha'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Mostrar senha').first);
      await tester.pump();

      expect(controller.senhaOculta.value, isFalse);
    });
  });
}
