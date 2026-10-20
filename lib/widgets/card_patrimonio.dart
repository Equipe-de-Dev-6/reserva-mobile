import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../models/patrimonio_model.dart';
import 'badge_status.dart';

/// Card de um bem patrimonial.
///
/// **Widget único para os três lugares onde um bem aparece** (RNF04):
///
/// | Onde | Quem vê |
/// |------|---------|
/// | Listagem geral do acervo (RF07a) | Coordenador |
/// | Bens de um docente (RF06.3) | Coordenador |
/// | "Meus Patrimônios" (RF08) | Professor |
///
/// Ele é **estritamente informativo**: nenhum botão de criar, editar ou
/// excluir mora aqui. Quem tem ação de escrita (o Coordenador) coloca o
/// botão na tela, fora do card — assim o mesmo widget serve ao docente
/// sem precisar de uma variante "sem botões" (RN03).
///
/// [mostrarResponsavel] existe porque a lista do Coordenador mostra a quem
/// o bem pertence, enquanto no painel do docente o responsável é sempre
/// ele mesmo e poluiria o card.
class CardPatrimonio extends StatelessWidget {
  const CardPatrimonio({
    super.key,
    required this.patrimonio,
    this.aoTocar,
    this.mostrarResponsavel = true,
  });

  final PatrimonioModel patrimonio;

  /// Quando é informado, o card fica clicável. Sem ele, o card é só
  /// leitura — é o caso da tela do docente, que não navega para o detalhe
  /// administrativo.
  final VoidCallback? aoTocar;

  /// Exibe a linha "responsável" com o nome do docente.
  final bool mostrarResponsavel;

  @override
  Widget build(BuildContext context) {
    final conteudo = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconeCategoria(categoria: patrimonio.categoria),
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
                        patrimonio.nome.isEmpty
                            ? 'Bem sem nome'
                            : patrimonio.nome,
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
                    BadgeStatus(status: patrimonio.status, compacto: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 10),
                if (patrimonio.codigo.isNotEmpty)
                  _Linha(icone: Icons.qr_code_2_rounded, texto: patrimonio.codigo),
                if (patrimonio.localizacao.trim().isNotEmpty)
                  _Linha(
                    icone: Icons.place_outlined,
                    texto: patrimonio.localizacao.trim(),
                  ),
                if (patrimonio.dataAtribuicaoFormatada.isNotEmpty)
                  _Linha(
                    icone: Icons.event_available_outlined,
                    texto:
                        'Atribuído em ${patrimonio.dataAtribuicaoFormatada}',
                  ),
                if (mostrarResponsavel && patrimonio.temProfessor)
                  _Linha(
                    icone: Icons.person_outline,
                    texto: patrimonio.professorNomeFormatado,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (aoTocar == null) return Card(child: conteudo);

    return Card(
      // `InkWell` dentro do Card dá o ripple do toque sem precisar de
      // GestureDetector e sem perder a borda arredondada do tema.
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: conteudo,
      ),
    );
  }

  /// `Informática · Dell · Latitude 3420`, pulando o que estiver vazio.
  String get _subtitulo {
    final partes = <String>[
      if (patrimonio.categoria.trim().isNotEmpty) patrimonio.categoria.trim(),
      if (patrimonio.marca.trim().isNotEmpty) patrimonio.marca.trim(),
      if (patrimonio.modelo.trim().isNotEmpty) patrimonio.modelo.trim(),
    ];
    if (partes.isEmpty) return 'Sem categoria informada';
    return partes.join(' · ');
  }
}

/// Ícone quadrado com o símbolo da categoria do bem.
///
/// Categorias são texto livre no cadastro, então o mapeamento é por
/// palavra-chave e o fallback é o ícone genérico de equipamento.
class _IconeCategoria extends StatelessWidget {
  const _IconeCategoria({required this.categoria});

  final String categoria;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Tema.azulPrimario.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _icone(),
        color: Tema.azulPrimario,
        size: 24,
      ),
    );
  }

  IconData _icone() {
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
    if (c.contains('eletrônic') || c.contains('eletronic')) {
      return Icons.memory_rounded;
    }
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
