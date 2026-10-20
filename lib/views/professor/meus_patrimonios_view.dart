import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/meus_patrimonios_controller.dart';
import '../../widgets/card_patrimonio.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_professor.dart';

/// **RF08 — "Meus Patrimônios": a visão do docente.**
///
/// Lista os equipamentos sob responsabilidade do professor autenticado,
/// com tombamento, data de atribuição, localização e responsável.
///
/// É **estritamente informativa**: não há botão de criar, editar,
/// excluir, atribuir ou devolver em nenhum lugar desta tela (RN03).
/// O card leva o docente à ficha completa do bem — também em modo
/// leitura ([RotasProfessor.detalhePatrimonio]).
class MeusPatrimoniosView extends GetView<MeusPatrimoniosController> {
  const MeusPatrimoniosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Patrimônios'),
        actions: [
          Obx(() {
            if (controller.carregando.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              );
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
    if (controller.carregando.value && controller.patrimonios.isEmpty) {
      return const _Esqueleto();
    }

    if (controller.erro.value.isNotEmpty && controller.patrimonios.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: Colors.black.withValues(alpha: 0.35)),
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

    if (controller.patrimonios.isEmpty) {
      return EstadoVazio(
        icone: Icons.devices_other_outlined,
        titulo: controller.tituloEstadoVazio,
        descricao: controller.descricaoEstadoVazio,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: controller.patrimonios.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, indice) {
          final patrimonio = controller.patrimonios[indice];
          // `mostrarResponsavel: false` — no painel do docente o
          // responsável é sempre ele mesmo e poluiria o card.
          //
          // `aoTocar` abre a ficha completa do bem em modo leitura
          // (RF08): o docente vê os detalhes, mas nenhuma ação de
          // escrita existe na tela seguinte (RN03).
          return CardPatrimonio(
            patrimonio: patrimonio,
            mostrarResponsavel: false,
            aoTocar: () => Get.toNamed(
              RotasProfessor.detalhePatrimonio,
              arguments: {'id': patrimonio.id},
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton da lista enquanto os bens carregam (RNF02).
class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    final cor = Colors.black.withValues(alpha: 0.06);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        height: 128,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
