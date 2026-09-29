import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/tema.dart';

/// Diálogo de confirmação de logout (RF04).
///
/// Evita que o usuário encerre a sessão sem querer. A View chama
/// `confirmarLogout(context, aoConfirmar)` e o Controller executa
/// a ação — o diálogo em si não sabe nada de autenticação.
void confirmarLogout(BuildContext context, Future<void> Function() aoConfirmar) {
  Get.dialog<void>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Encerrar sessão?'),
      content: const Text(
        'Você precisará entrar novamente com e-mail e senha.',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Tema.perigo),
          onPressed: () {
            Get.back<void>();
            aoConfirmar();
          },
          child: const Text('Sair'),
        ),
      ],
    ),
  );
}
