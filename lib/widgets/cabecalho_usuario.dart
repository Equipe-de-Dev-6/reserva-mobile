import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/tema.dart';
import '../core/servicos/sessao_service.dart';

/// Faixa de identificaÃ§Ã£o exibida no topo dos dois painÃ©is.
///
/// Como o [SessaoService] Ã© um serviÃ§o permanent, o `Obx` garante que
/// a faixa reflita o usuÃ¡rio logado sem a tela precisar buscar em
/// separado.
class CabecalhoUsuario extends StatelessWidget {
  const CabecalhoUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = Get.find<SessaoService>();

    return Obx(() {
      final usuario = sessao.usuario.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Tema.azulPrimario, Tema.azulEscuro],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                usuario?.iniciais ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario?.nome ?? 'UsuÃ¡rio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _rotuloPerfil(usuario?.role),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Traduz o papel tÃ©cnico para o rÃ³tulo exibido ao usuÃ¡rio.
  static String _rotuloPerfil(String? role) => switch (role) {
        'admin' => 'Coordenador (admin)',
        'professor' => 'Professor (docente)',
        _ => 'Perfil nÃ£o reconhecido',
      };
}
