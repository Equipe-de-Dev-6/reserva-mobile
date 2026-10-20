import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_historico_controller.dart';
import '../../core/utils/data_hora.dart';
import '../../models/historico_model.dart';
import '../../models/status_patrimonio.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/mensagem_erro.dart';

/// **RF07b — Histórico / linha do tempo do patrimônio.**
///
/// Cada movimentação do bem — cadastro, atribuição, devolução,
/// manutenção, edição — vira um evento na linha do tempo.
///
/// É a tela que responde "quem tinha este equipamento e quando?". O
/// histórico é gravado pelo backend; o app é só leitor.
class PatrimonioHistoricoView extends GetView<PatrimonioHistoricoController> {
  const PatrimonioHistoricoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico do bem'),
        actions: [
          Obx(() {
            if (controller.carregando.value) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: controller.carregar,
            );
          }),
        ],
      ),
      body: SafeArea(child: Obx(() => _corpo(context))),
    );
  }

  Widget _corpo(BuildContext context) {
    if (controller.carregando.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.erro.value.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 44, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              MensagemErro.erro(controller.erro.value),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.carregar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.vazio) {
      return const EstadoVazio(
        icone: Icons.history_toggle_off_rounded,
        titulo: 'Nenhuma movimentação registrada',
        descricao:
            'Assim que o bem for entregue a um docente ou devolvido ao '
            'almoxarifado, as movimentações aparecem aqui.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: controller.itens.length,
      itemBuilder: (context, indice) => _ItemLinhaTempo(
        item: controller.itens[indice],
        // O último item não desenha a linha vertical: ela terminaria
        // no vazio.
        ehUltimo: indice == controller.itens.length - 1,
      ),
    );
  }
}

/// Um evento da linha do tempo.
class _ItemLinhaTempo extends StatelessWidget {
  const _ItemLinhaTempo({required this.item, required this.ehUltimo});

  final HistoricoModel item;
  final bool ehUltimo;

  @override
  Widget build(BuildContext context) {
    final cor = _corDaAcao(item.acao);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trilho vertical com o marcador do evento.
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: cor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(_iconeDaAcao(item.acao), size: 15, color: cor),
                ),
                if (!ehUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cor.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.rotuloAcao,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: cor,
                              ),
                            ),
                          ),
                          Text(
                            DataHora.data(item.dataRegistro),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (item.motivo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.motivo,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14,
                              color: Colors.black.withValues(alpha: 0.4)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.responsavel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          if (item.professorNome != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.school_outlined,
                                size: 14,
                                color: Colors.black.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.professorNome!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cor por tipo de ação.
  static Color _corDaAcao(AcaoHistorico acao) => switch (acao) {
        AcaoHistorico.atribuicao => Tema.azulPrimario,
        AcaoHistorico.desatribuicao => Tema.sucesso,
        AcaoHistorico.manutencao => Tema.alerta,
        AcaoHistorico.exclusao => Tema.perigo,
        AcaoHistorico.criacao => const Color(0xFF6B7280),
        _ => const Color(0xFF6B7280),
      };

  /// Ícone por tipo de ação.
  static IconData _iconeDaAcao(AcaoHistorico acao) => switch (acao) {
        AcaoHistorico.atribuicao => Icons.assignment_ind_outlined,
        AcaoHistorico.desatribuicao => Icons.assignment_return_outlined,
        AcaoHistorico.manutencao => Icons.build_outlined,
        AcaoHistorico.edicao => Icons.edit_outlined,
        AcaoHistorico.exclusao => Icons.delete_outline,
        AcaoHistorico.criacao => Icons.add_box_outlined,
        _ => Icons.circle_outlined,
      };
}
