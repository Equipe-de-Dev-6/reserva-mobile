import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../models/professor_model.dart';

/// Card de um docente na listagem (RF06).
///
/// O destaque do card Ã© o **contador de bens** â€” o requisito Ã© mostrar,
/// junto de cada docente, quantos equipamentos estÃ£o sob responsabilidade
/// dele (RN04). O dado vem pronto do backend em `totalPatrimonios`.
class CartaoProfessor extends StatelessWidget {
  const CartaoProfessor({
    super.key,
    required this.professor,
    required this.aoTocar,
  });

  final ProfessorModel professor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final corContador = professor.possuiBens ? Tema.azulPrimario : Tema.sucesso;

    return Card(
      // Feedback tÃ¡til imediato ao tocar (RNF01).
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(professor: professor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professor.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          professor.resumoInstitucional,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ContadorBens(
                    rotulo: professor.rotuloBens,
                    total: professor.totalPatrimonios,
                    cor: corContador,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.professor});

  final ProfessorModel professor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Tema.azulPrimario.withValues(alpha: 0.12),
      child: Text(
        professor.iniciais,
        style: const TextStyle(
          color: Tema.azulPrimario,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// O indicador "N bens sob responsabilidade" exigido pelo RF06.
class _ContadorBens extends StatelessWidget {
  const _ContadorBens({
    required this.rotulo,
    required this.total,
    required this.cor,
  });

  final String rotulo;
  final int total;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 15, color: cor),
          const SizedBox(width: 6),
          Text(
            rotulo,
            style: TextStyle(
              color: cor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
