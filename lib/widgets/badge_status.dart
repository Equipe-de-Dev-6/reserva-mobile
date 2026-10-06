import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../models/status_patrimonio.dart';

/// Etiqueta colorida com a situação do bem.
///
/// Substitui as comparações de string que antes ficavam espalhadas nas
/// Views (`if (status == 'em_uso') ...`). Cada estado tem uma cor e um
/// ícone próprios, e o texto vem do próprio enum — assim a tradução do
/// rótulo acontece em um lugar só ([StatusPatrimonio.rotulo]).
///
/// ```dart
/// BadgeStatus(status: patrimonio.status)
/// ```
class BadgeStatus extends StatelessWidget {
  const BadgeStatus({super.key, required this.status, this.compacto = false});

  final StatusPatrimonio status;

  /// Versão reduzida (altura menor, fonte menor) para uso dentro do card
  /// da listagem, onde o badge disputa espaço com o tombamento.
  final bool compacto;

  /// Paleta por estado. Fica aqui, e não no Model, porque cor é
  /// assunto de apresentação.
  static Color corDe(StatusPatrimonio status) => switch (status) {
        StatusPatrimonio.disponivel => Tema.sucesso,
        StatusPatrimonio.emUso => Tema.azulPrimario,
        StatusPatrimonio.emManutencao => Tema.alerta,
        StatusPatrimonio.baixado => Tema.perigo,
        StatusPatrimonio.indefinido => const Color(0xFF6B7280),
      };

  static IconData iconeDe(StatusPatrimonio status) => switch (status) {
        StatusPatrimonio.disponivel => Icons.check_circle_outline,
        StatusPatrimonio.emUso => Icons.person_outline,
        StatusPatrimonio.emManutencao => Icons.build_outlined,
        StatusPatrimonio.baixado => Icons.inventory_2_outlined,
        StatusPatrimonio.indefinido => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final cor = corDe(status);
    final tamanho = compacto ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconeDe(status), size: tamanho + 2, color: cor),
          const SizedBox(width: 5),
          // `Flexible` + ellipsis: em iPhone SE o rótulo mais longo
          // ("Em manutenção") não pode estourar a linha do card.
          Flexible(
            child: Text(
              status.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cor,
                fontSize: tamanho,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
