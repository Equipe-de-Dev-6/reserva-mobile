import 'package:flutter/material.dart';

/// Esqueleto (skeleton) de carregamento (RNF02).
///
/// Substitui o `CircularProgressIndicator` centralizado das listas: ele
/// mostra **onde** os cards vão aparecer, o que deixa a transição para o
/// conteúdo muito menos brusca. A animação é um pulso de opacidade —
/// nenhuma dependência extra foi adicionada ao projeto.
class EsqueletoLista extends StatelessWidget {
  const EsqueletoLista({
    super.key,
    this.quantidade = 4,
    this.altura = 104,
  });

  /// Quantos blocos desenhar (aproximando o tamanho da lista real).
  final int quantidade;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quantidade,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BlocoEsqueleto(largura: 46, altura: 46, arredondado: 23),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _BlocoEsqueleto(largura: 170, altura: 14),
                        SizedBox(height: 8),
                        _BlocoEsqueleto(largura: 120, altura: 11),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _BlocoEsqueleto(largura: 150, altura: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um único bloco pulsante.
class _BlocoEsqueleto extends StatefulWidget {
  const _BlocoEsqueleto({
    required this.largura,
    required this.altura,
    this.arredondado = 8,
  });

  final double largura;
  final double altura;
  final double arredondado;

  @override
  State<_BlocoEsqueleto> createState() => _BlocoEsqueletoState();
}

class _BlocoEsqueletoState extends State<_BlocoEsqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulso,
      builder: (context, child) {
        return Container(
          width: widget.largura,
          height: widget.altura,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.06 + 0.06 * _pulso.value),
            borderRadius: BorderRadius.circular(widget.arredondado),
          ),
        );
      },
    );
  }
}
