import 'package:flutter/material.dart';

/// Estado vazio reutilizável (RNF02).
///
/// Usado quando uma lista vem sem itens — por exemplo, o professor sem
/// nenhum patrimônio atribuído, ou a busca sem resultados.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.titulo,
    this.descricao,
    this.icone = Icons.inbox_outlined,
    this.acao,
  });

  final String titulo;
  final String? descricao;
  final IconData icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    // O conteúdo precisa caber na altura disponível **e** continuar
    // acessível quando não cabe (tela baixa, texto grande, fonte do
    // sistema ampliada). Por isso ele rola em vez de estourar: o
    // `LayoutBuilder` devolve a altura disponível e o `ConstrainedBox`
    // garante que o conteúdo fique centralizado enquanto couber.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icone,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (descricao != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    descricao!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                if (acao != null) ...[const SizedBox(height: 20), acao!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
