import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mostra o `MediaQuery` que a tela recebeu.
class _TamanhoDaTela extends StatelessWidget {
  const _TamanhoDaTela();

  /// Chave própria: a barra de ferramentas do DevicePreview também
  /// cria `Text`, então o precisa ser localizado por chave.
  static const Key sonda = Key('sonda-tamanho');

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '${mq.size.width.toStringAsFixed(0)}x'
        '${mq.size.height.toStringAsFixed(0)}',
        key: sonda,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Testes do DevicePreview usado em `dev/main_dev.dart`.
///
/// Objetivo: garantir que o preview realmente troca o `MediaQuery` do
/// app pelo tamanho do aparelho escolhido. Sem isso, o "emular o
/// celular" seria apenas uma moldura visual sem efeito nenhum sobre o
/// layout, e os testes de overflow não serviriam para nada.
void main() {
  Future<void> montar(WidgetTester tester, DeviceInfo aparelho) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      DevicePreview(
        builder: (context) => const _TamanhoDaTela(),
        defaultDevice: aparelho,
        // O storage padrão usa `shared_preferences`, um canal de
        // plataforma que nunca responde dentro do tempo *fake* de
        // `testWidgets`. Sem ele o preview ficaria preso em "carregando".
        storage: DevicePreviewStorage.none(),
      ),
    );

    // O DevicePreview inicializa o store de forma assíncrona antes de
    // aplicar a moldura, então alguns frames são necessários.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  String tamanhoRenderizado(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(_TamanhoDaTela.sonda)).data ?? '';

  testWidgets('iPhone 13 resulta em 390x844', (tester) async {
    await montar(tester, Devices.ios.iPhone13);
    expect(tamanhoRenderizado(tester), '390x844');
  });

  testWidgets('iPhone SE resulta em 375x667', (tester) async {
    await montar(tester, Devices.ios.iPhoneSE);
    expect(tamanhoRenderizado(tester), '375x667');
  });

  testWidgets('iPhone 16 Pro Max resulta em 440x956', (tester) async {
    await montar(tester, Devices.ios.iPhone16ProMax);
    expect(tamanhoRenderizado(tester), '440x956');
  });
}
