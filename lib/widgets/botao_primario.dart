import 'package:flutter/material.dart';

/// Botão primário padronizado do aplicativo (RNF04).
///
/// Concentra o comportamento de "carregando" para que **nenhuma tela
/// precise montar o seu próprio botão com spinner**. É usado no Login,
/// no Cadastro, na Recuperação de Senha e em todos os formulários dos
/// módulos 2 e 3.
class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.aoTocar,
    this.carregando = false,
    this.icone,
    this.cor,
  });

  final String texto;
  final VoidCallback? aoTocar;
  final bool carregando;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final corFinal = cor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        // Desabilitar durante o carregamento evita envio duplicado.
        onPressed: carregando ? null : aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: corFinal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: corFinal.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: carregando
            // Feedback tátil imediato durante a espera (RNF01).
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: 20),
                    const SizedBox(width: 10),
                  ],
                  // `Flexible` + ellipsis: um rótulo longo ("Cadastrar
                  // coordenador", "Confirmar devolução") precisa caber
                  // em telas de 360 px sem estourar a linha do botão.
                  Flexible(
                    child: Text(
                      texto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
