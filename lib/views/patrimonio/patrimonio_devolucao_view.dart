import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_ciclo_vida_controller.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_patrimonio.dart';

/// **RF07b — Devolução de um bem (RN05).**
///
/// O Coordenador desvincula o docente e registra o **motivo** da
/// devolução. O backend devolve o bem ao almoxarifado (status
/// `disponivel`), tira ele da visão do docente e grava a ocorrência no
/// histórico.
///
/// O motivo é obrigatório: é ele que explica, meses depois, por que o
/// equipamento saiu da mão de um docente.
class PatrimonioDevolucaoView extends StatefulWidget {
  const PatrimonioDevolucaoView({super.key});

  @override
  State<PatrimonioDevolucaoView> createState() =>
      _PatrimonioDevolucaoViewState();
}

class _PatrimonioDevolucaoViewState extends State<PatrimonioDevolucaoView> {
  /// A FormKey mora na View (ver comentário em `auth_controller.dart`).
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatrimonioCicloVidaController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar devolução')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _Resumo(controller: controller),
              const SizedBox(height: 18),
              CampoTexto(
                rotulo: 'Motivo da devolução',
                dica: 'Ex.: encerramento do ano letivo',
                icone: Icons.assignment_return_outlined,
                controlador: controller.motivoCtrl,
                maxLength: 200,
                validator: controller.validarMotivo,
                desabilitado: controller.salvando.value,
              ),
              const SizedBox(height: 10),
              Text(
                'O motivo fica registrado na linha do tempo do bem.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.erro.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MensagemErro.erro(controller.erro.value),
                );
              }),
              Obx(
                () => BotaoPrimario(
                  texto: 'Confirmar devolução',
                  icone: Icons.assignment_return_outlined,
                  carregando: controller.salvando.value,
                  aoTocar: () => _confirmar(controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirma a devolução e volta para a lista de patrimônios.
  Future<void> _confirmar(PatrimonioCicloVidaController controller) async {
    final ok = await controller.confirmar(_formKey.currentState!);
    if (!ok) return;

    Get.offNamed(RotasPatrimonio.lista);
    Get.snackbar(
      'Devolução registrada',
      'O bem voltou ao almoxarifado e saiu da lista do docente.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Tema.sucesso,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}

/// Resumo do bem que está sendo devolvido.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.controller});

  final PatrimonioCicloVidaController controller;

  @override
  Widget build(BuildContext context) {
    final patrimonio = controller.patrimonio.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipamento devolvido',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              patrimonio?.nome ?? 'Bem sem nome',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              patrimonio?.codigo.isNotEmpty ?? false
                  ? patrimonio!.codigo
                  : 'Sem tombamento',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Tema.azulPrimario,
              ),
            ),
            if ((patrimonio?.professorNomeFormatado ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 15, color: Colors.black.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Responsável atual: ${patrimonio!.professorNomeFormatado}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
