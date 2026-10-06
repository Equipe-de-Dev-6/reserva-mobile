import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:reserva_mobile/main.dart';

/// Ponto de entrada de **desenvolvimento**.
///
/// Envolve o app no [DevicePreview], que permite ver as telas em
/// dezenas de tamanhos de aparelho sem trocar de emulador a cada teste.
/// É daqui que a equipe confere o comportamento responsivo e o
/// requisito RNF01 (UX pensada para dispositivos móveis).
///
/// ```bash
/// flutter run -t dev/main_dev.dart
/// ```
///
/// A barra lateral do DevicePreview permite trocar de aparelho, girar a
/// tela, alternar o dark mode, ajustar o tamanho do texto e habilitar o
/// teclado virtual.
///
/// Este arquivo fica **fora de `lib/`** de propósito: o `device_preview`
/// é uma `dev_dependency` e não deve entrar no build de produção.
/// O app que vai para a loja continua sendo `lib/main.dart`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      // `builder` monta o app dentro do contexto do aparelho escolhido,
      // de modo que `MediaQuery` e `Theme` reflitam o dispositivo em vez
      // da janela do desktop.
      builder: (context) => const PatrimonioEscolarApp(),

      // iPhone 13 como aparelho inicial: é a base de referência do
      // time de design. Troque livremente pela barra lateral.
      defaultDevice: Devices.ios.iPhone13,
    ),
  );
}
