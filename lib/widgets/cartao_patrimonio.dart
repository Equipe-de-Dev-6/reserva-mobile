import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../models/patrimonio_model.dart';
import 'badge_status.dart';

/// Card de um bem patrimonial.
///
/// Usado na relação de bens do docente (RF06.3) e, reexportado sem
/// alteração, na listagem geral (RF07) e em "Meus Patrimônios" (RF08):
/// o formato do card é o mesmo nos três lugares, então ele mora uma vez
/// só em `widgets/`.
///
/// É estritamente informativo — nenhum botão de editar/excluir, como
/// exige a RN03 para o docente.
class CartaoPatrimonio extends StatelessWidget {
  const CartaoPatrimonio({
    super.key,
    required this.patrimonio,
    this.aoTocar,
  });

  final PatrimonyModel patrimonio;

  /// Quando é informado, o card fica clicável (navega para o histórico
  /// do bem no fluxo do Coordenador). Sem ele, o card é só leitura.
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final conteudo = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Tema.azulPrimario.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconeDaCategoria(patrimonio.categoria),
              color: Tema.azulPrimario,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        patrimonio.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BadgeStatus(status: patrimonio.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  patrimonio.resumoEquipamento,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                if (patrimonio.localizacao.isNotEmpty ||
                    patrimonio.codigo.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _Linha(
                    icone: Icons.qr_code_2_rounded,
                    texto: patrimonio.codigo,
                  ),
                  if (patrimonio.localizacao.isNotEmpty)
                    _Linha(
                      icone: Icons.place_outlined,
                      texto: patrimonio.localizacao,
                    ),
                  if (patrimonio.emUso &&
                      patrimonio.dataAtribuicaoFormatada.isNotEmpty)
                    _Linha(
                      icone: Icons.event_available_outlined,
                      texto:
                          'Atribuído em ${patrimonio.dataAtribuicaoFormatada}',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (aoTocar == null) {
      return Card(child: conteudo);
    }

    return Card(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: conteudo,
      ),
    );
  }

  /// Escolhe o ícone pela categoria informada no cadastro (RF07).
  /// Categorias livres: cai no ícone genérico de equipamento.
  static IconData _iconeDaCategoria(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('informática') || c.contains('informatica')) {
      return Icons.laptop_mac_rounded;
    }
    if (c.contains('audiovisual')) return Icons.videocam_outlined;
    if (c.contains('laboratório') || c.contains('laboratorio')) {
      return Icons.biotech_outlined;
    }
    if (c.contains('mobiliário') || c.contains('mobiliario')) {
      return Icons.chair_alt_outlined;
    }
    if (c.contains('esport')) return Icons.sports_basketball_outlined;
    return Icons.devices_other_rounded;
  }
}

/// Linha "ícone + texto" usada nos metadados do card.
class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icone, size: 14, color: Colors.black.withValues(alpha: 0.35)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
