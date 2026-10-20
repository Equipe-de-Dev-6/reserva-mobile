import 'package:flutter/material.dart';

import '../app/tema.dart';

/// Cartão de **indicador** do dashboard (RF05).
///
/// Um número grande, um rótulo curto e uma cor que traduz a situação.
/// Existe como widget porque o dashboard mostra seis deles: escrever o
/// card seis vezes na View seria justamente a duplicação que o RNF04
/// pede para evitar.
class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.detalhe,
  });

  /// O que está sendo medido ("Em uso", "Disponíveis"...).
  final String rotulo;

  /// O número. Vem como texto para aceitar "12" e "—" sem complicação.
  final String valor;

  final IconData icone;

  /// Cor do cartão. Cada situação tem a sua.
  final Color cor;

  /// Texto pequeno abaixo do número (ex.: "de 20 bens").
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 26,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: cor,
              ),
            ),
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 2),
            Text(
              detalhe!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Faixa de **distribuição por categoria** (RF05).
///
/// Uma barra proporcional por categoria. O comprimento da barra é
/// relativo à maior categoria — assim o gráfico mostra a *concentração*
/// do acervo, que é a informação que o Coordenador procura.
class BarraCategoria extends StatelessWidget {
  const BarraCategoria({
    super.key,
    required this.categoria,
    required this.quantidade,
    required this.fracao,
  });

  final String categoria;
  final int quantidade;

  /// Quanto a barra ocupa, de 0 a 1.
  final double fracao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$quantidade',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Tema.azulPrimario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fracao.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Tema.azulPrimario.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(Tema.azulPrimario),
            ),
          ),
        ],
      ),
    );
  }
}
