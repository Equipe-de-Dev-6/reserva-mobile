import 'package:flutter/material.dart';

import '../app/tema.dart';

/// Badge de status patrimonial (RNF04).
///
/// Centraliza o texto e a cor de cada status para que o mesmo
/// patrimonio_id não apareça como "Em uso" num card e "em uso" noutro.
/// A regra de *o que* cada status significa fica no Model; aqui mora
/// apenas como ele é desenhado.
class BadgeStatus extends StatelessWidget {
  const BadgeStatus({super.key, required this.status});

  /// `disponivel`, `em_uso` ou `em_manutencao`.
  final String status;

  @override
  Widget build(BuildContext context) {
    final estilo = _EstiloDoStatus.para(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estilo.cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estilo.cor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: estilo.cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            estilo.rotulo,
            style: TextStyle(
              color: estilo.cor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tradução de status → { rótulo, cor }. Um valor privado, porque só o
/// badge precisa saber cores.
class _EstiloDoStatus {
  const _EstiloDoStatus(this.rotulo, this.cor);

  final String rotulo;
  final Color cor;

  static _EstiloDoStatus para(String status) => switch (status) {
        'em_uso' => const _EstiloDoStatus('Em uso', Tema.vermelhoPrimario),
        'disponivel' => const _EstiloDoStatus('Disponível', Tema.sucesso),
        'em_manutencao' => const _EstiloDoStatus('Manutenção', Tema.alerta),
        'baixado' => const _EstiloDoStatus('Baixado', Tema.perigo),
        _ => const _EstiloDoStatus('Desconhecido', Color(0xFF6B7280)),
      };
}
