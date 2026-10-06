import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../models/patrimonio_model.dart';
import 'badge_status.dart';

/// Card de um bem na listagem (RF07a).
///
/// Mostra o essencial para o Coordenador decidir em qual bem tocar:
/// tombamento, nome, categoria, localização e situação. O toque
/// completo vai para `aoTocar`, que a View liga à abertura do detalhe.
///
/// [mostrarResponsavel] existe porque a lista do Coordenador e a do
/// Professor usam o mesmo card: no painel do docente o responsável é
/// sempre ele mesmo e poluiria o card.
class CardPatrimonio extends StatelessWidget {
  const CardPatrimonio({
    super.key,
    required this.patrimonio,
    this.aoTocar,
    this.mostrarResponsavel = true,
  });

  final PatrimonioModel patrimonio;
  final VoidCallback? aoTocar;
  final bool mostrarResponsavel;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      // `InkWell` dentro do Card dá o ripple do toque sem precisar
      // GestureDetector e sem perder a borda arredondada do tema.
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: tombamento + status.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      patrimonio.codigo.isEmpty
                          ? 'Sem tombamento'
                          : patrimonio.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: Tema.azulPrimario,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  BadgeStatus(status: patrimonio.status, compacto: true),
                ],
              ),
              const SizedBox(height: 8),

              // Linha 2: nome do bem (até 2 linhas em telas estreitas).
              Text(
                patrimonio.nome.isEmpty ? 'Bem sem nome' : patrimonio.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),

              // Linha 3: categoria · marca.
              Text(
                _subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),

              if (_localizacao.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _localizacao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (mostrarResponsavel && patrimonio.temProfessor) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        patrimonio.professorNomeFormatado,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// `Informática · Dell`, pulando o que estiver vazio.
  String get _subtitulo {
    final partes = <String>[
      if (patrimonio.categoria.isNotEmpty) patrimonio.categoria,
      if (patrimonio.marca.isNotEmpty) patrimonio.marca,
      if (patrimonio.modelo.isNotEmpty) patrimonio.modelo,
    ];
    return partes.isEmpty ? 'Sem categoria informada' : partes.join(' · ');
  }

  String get _localizacao => patrimonio.localizacao.trim();
}
