import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_manutencao_controller.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_patrimonio.dart';

/// **Manutenção de um bem (RN05).**
///
/// Dois movimentos do ciclo de vida numa tela só:
///
///  * **Envio** — o bem sai do almoxarifado para conserto, com o defeito
///    relatado registrado na linha do tempo (status `em_manutencao`).
///  * **Conclusão** — o conserto termina e o bem volta ao estoque,
///    pronto para uma nova atribuição (status `disponivel`).
///
/// O motivo é obrigatório nos dois casos: é ele que explica, meses
/// depois, por que o bem saiu (ou voltou) de circulação.
class PatrimonioManutencaoView extends StatefulWidget {
  const PatrimonioManutencaoView({super.key});

  @override
  State<PatrimonioManutencaoView> createState() =>
      _PatrimonioManutencaoViewState();
}

class _PatrimonioManutencaoViewState extends State<PatrimonioManutencaoView> {
  /// A FormKey mora na View (ver comentário em `auth_controller.dart`).
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatrimonioManutencaoController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.enviando ? 'Enviar para manutenção' : 'Concluir manutenção',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _Resumo(controller: controller),
              const SizedBox(height: 18),
              // Um bem em uso não pode ir direto para conserto: o
              // docente precisa devolver antes (RN05). O bloqueio é do
              // Controller e a explicação fica na própria tela.
              if (controller.bloqueioEnvio != null)
                MensagemErro.erro(controller.bloqueioEnvio!)
              else ...[
                CampoTexto(
                  rotulo: controller.enviando
                      ? 'Defeito apresentado'
                      : 'Serviço realizado',
                  dica: controller.enviando
                      ? 'Ex.: não liga, tela trincada'
                      : 'Ex.: troca da fonte de alimentação',
                  icone: Icons.build_outlined,
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
                    texto: controller.enviando
                        ? 'Confirmar envio'
                        : 'Confirmar conclusão',
                    icone: Icons.build_outlined,
                    carregando: controller.salvando.value,
                    aoTocar: () => _confirmar(controller),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Executa o movimento e volta para a lista de patrimônios.
  Future<void> _confirmar(PatrimonioManutencaoController controller) async {
    final ok = await controller.confirmar(_formKey.currentState!);
    if (!ok) return;

    final enviando = controller.enviando;

    Get.offNamed(RotasPatrimonio.lista);
    Get.snackbar(
      enviando ? 'Bem enviado para manutenção' : 'Manutenção concluída',
      enviando
          ? 'O bem saiu de circulação até o conserto terminar.'
          : 'O bem voltou ao almoxarifado e está disponível.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Tema.sucesso,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}

/// Resumo do bem que está entrando ou saindo da manutenção.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.controller});

  final PatrimonioManutencaoController controller;

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
              controller.enviando
                  ? 'Equipamento enviado para conserto'
                  : 'Equipamento consertado',
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
            if ((patrimonio?.localizacao ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 15, color: Colors.black.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      patrimonio!.localizacao.trim(),
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
