import 'package:flutter/widgets.dart';

/// Regra do projeto para os `TextEditingController` que vivem nos
/// Controllers do GetX.
///
/// **Por que o Controller não descarta (`dispose`) esses controllers?**
///
/// O GetX descarta o Controller no instante em que a rota é removida —
/// mas a **View** que usa aqueles campos ainda pode estar saindo da
/// árvore (a transição de rota leva 280 ms). Ao ser desmontado, o
/// `TextFormField` chama `removeListener` no controller: se ele já
/// estiver descartado, o Flutter estoura com
///
/// > A TextEditingController was used after being disposed.
///
/// e a tela fica coberta pelo erro vermelho.
///
/// Descartar no `onClose()` **é** o que causava o crash. A solução
/// adotada é limpar os campos (para não deixar dado sensível — senha —
/// na memória) e **não** descartá-los: eles são liberados junto com o
/// próprio Controller, pelo coletor de lixo.
///
/// ## A regra de ouro
///
/// `TextEditingController` pertence à **widget** que o usa. Como, aqui,
/// ele mora no Controller (que é compartilhado por mais de uma tela),
/// o Controller só pode **limpar**, nunca descartar, sob pena de
/// derrubar a tela que ainda o referencia.
void limparCampos(List<TextEditingController> controllers) {
  for (final controller in controllers) {
    // `clear()` não descarta: esvazia o texto e notifica os listeners.
    controller.clear();
  }
}
