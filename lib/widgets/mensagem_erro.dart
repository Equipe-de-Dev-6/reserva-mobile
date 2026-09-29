import 'package:flutter/material.dart';

/// Faixa de mensagem usada dentro dos formulários.
///
/// Cobre os três estados de feedback do requisito RNF02:
///  * [TipoMensagem.erro]    → falha (ex.: 401, 403, erro de rede)
///  * [TipoMensagem.aviso]   → informação
///  * [TipoMensagem.sucesso] → operação concluída
class MensagemErro extends StatelessWidget {
  const MensagemErro.mensagem(
    this.texto, {
    super.key,
    this.tipo = TipoMensagem.erro,
  });

  /// Caixa de erro com ícone de alerta (atalho mais usado).
  const MensagemErro.erro(String texto, {Key? key})
      : this.mensagem(texto, tipo: TipoMensagem.erro, key: key);

  final String texto;
  final TipoMensagem tipo;

  @override
  Widget build(BuildContext context) {
    final cor = switch (tipo) {
      TipoMensagem.erro => const Color(0xFFC0392B),
      TipoMensagem.aviso => const Color(0xFFD9822B),
      TipoMensagem.sucesso => const Color(0xFF1B8A5A),
    };
    final icone = switch (tipo) {
      TipoMensagem.erro => Icons.error_outline,
      TipoMensagem.aviso => Icons.warning_amber_rounded,
      TipoMensagem.sucesso => Icons.check_circle_outline,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: cor, fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum TipoMensagem { erro, aviso, sucesso }
