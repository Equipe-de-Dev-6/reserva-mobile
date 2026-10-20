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

import 'package:reserva_mobile/widgets/campo_texto.dart';

/// O TextFormField nao expoe obscureText: ele repassa o valor para o
/// EditableText interno, e e la que a mascara realmente e aplicada.
bool _obscuro(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText).first).obscureText;

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
}
