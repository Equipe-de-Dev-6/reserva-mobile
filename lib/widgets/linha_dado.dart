import 'package:flutter/material.dart';

/// Linha rótulo/valor dos dados cadastrais (RF09).
///
/// O `UsuarioModel` tem ~14 campos; desenhá-los um a um na View geraria
/// repetição. Este widget padroniza o par "rótulo em cima, valor abaixo",
/// com o valor ausente virando "Não informado" — informação útil no
/// lugar de um espaço em branco.
class LinhaDado extends StatelessWidget {
  const LinhaDado({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;

  /// Texto exibido quando o campo não foi preenchido no cadastro.
  static const String naoInformado = 'Não informado';

  @override
  Widget build(BuildContext context) {
    final vazio = valor.trim().isEmpty;
    final texto = vazio ? naoInformado : valor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 17, color: Colors.black.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 116,
            child: Text(
              rotulo,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: vazio ? FontWeight.w400 : FontWeight.w600,
                fontStyle: vazio ? FontStyle.italic : FontStyle.normal,
                color: vazio
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de uma seção dentro de um cartão ("Dados cadastrais",
/// "Segurança"). Só estilo — a semântica fica no texto do próprio View.
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.icone});

  final String texto;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icone != null) ...[
          Icon(icone, size: 17, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            texto.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }
}
