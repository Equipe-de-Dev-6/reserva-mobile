import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_ciclo_vida_controller.dart';
import '../../models/professor_model.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_patrimonio.dart';

/// **RF07b — Atribuição de um bem a um docente (RN05).**
///
/// O Coordenador escolhe, entre os docentes cadastrados, quem vai
/// receber o equipamento. O backend muda o status do bem para `em_uso`
/// e grava a movimentação no histórico.
///
/// A lista de docentes vem de `GET /admin/professores` — ou seja, **só**
/// quem o Coordenador cadastrou (RN02). O usuário não digita um id
/// qualquer: ele escolhe uma pessoa.
class PatrimonioAtribuicaoView extends StatefulWidget {
  const PatrimonioAtribuicaoView({super.key});

  @override
  State<PatrimonioAtribuicaoView> createState() =>
      _PatrimonioAtribuicaoViewState();
}

class _PatrimonioAtribuicaoViewState extends State<PatrimonioAtribuicaoView> {
  /// A FormKey mora na View (ver comentário em `auth_controller.dart`).
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatrimonioCicloVidaController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Atribuir bem')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _Resumo(controller: controller),
              const SizedBox(height: 18),
              _BuscaDocente(controller: controller),
              const SizedBox(height: 14),
              _ListaDocentes(controller: controller),
              const SizedBox(height: 18),
              CampoTexto(
                rotulo: 'Observações (opcional)',
                dica: 'Termo de responsabilidade assinado',
                icone: Icons.description_outlined,
                controlador: controller.observacoesCtrl,
                maxLength: 200,
                desabilitado: controller.salvando.value,
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
                  texto: 'Confirmar entrega',
                  icone: Icons.handshake_outlined,
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

  /// Confirma a atribuição e volta para a lista de patrimônios.
  Future<void> _confirmar(PatrimonioCicloVidaController controller) async {
    final ok = await controller.confirmar(_formKey.currentState!);
    if (!ok) return;

    Get.offNamed(RotasPatrimonio.lista);
    Get.snackbar(
      'Bem entregue',
      'O equipamento foi atribuído e já aparece na lista do docente.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Tema.sucesso,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}

/// Resumo do bem que está sendo entregue.
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
              'Equipamento a entregar',
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
          ],
        ),
      ),
    );
  }
}

/// Busca local na lista de docentes.
class _BuscaDocente extends StatelessWidget {
  const _BuscaDocente({required this.controller});

  final PatrimonioCicloVidaController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: controller.aoDigitarBuscaProfessor,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Buscar professor por nome, e-mail ou matrícula',
        prefixIcon: Icon(Icons.search, size: 20),
        isDense: true,
      ),
    );
  }
}

/// Lista de docentes com seleção.
class _ListaDocentes extends StatelessWidget {
  const _ListaDocentes({required this.controller});

  final PatrimonioCicloVidaController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.carregandoProfessores.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final professores = controller.professoresFiltrados;

      if (professores.isEmpty) {
        return EstadoVazio(
          icone: Icons.person_search_outlined,
          titulo: controller.professores.isEmpty
              ? 'Nenhum docente cadastrado'
              : 'Nenhum docente encontrado',
          descricao: controller.professores.isEmpty
              ? 'Cadastre um professor antes de atribuir equipamentos.'
              : 'Ajuste a busca para encontrar o professor.',
        );
      }

      final selecionado = controller.professorSelecionado.value;

      return Column(
        children: [
          for (final professor in professores)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CartaoProfessorSelecionavel(
                professor: professor,
                selecionado: selecionado == professor.id,
                aoTocar: () => controller.selecionarProfessor(professor.id),
              ),
            ),
        ],
      );
    });
  }
}

/// Card de docente selecionável.
class _CartaoProfessorSelecionavel extends StatelessWidget {
  const _CartaoProfessorSelecionavel({
    required this.professor,
    required this.selecionado,
    required this.aoTocar,
  });

  final ProfessorModel professor;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado
                  ? Tema.azulPrimario
                  : Colors.black.withValues(alpha: 0.08),
              width: selecionado ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Tema.azulPrimario.withValues(alpha: 0.12),
                child: Text(
                  professor.iniciais,
                  style: const TextStyle(
                    color: Tema.azulPrimario,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professor.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      professor.resumoInstitucional,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selecionado
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selecionado
                    ? Tema.azulPrimario
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
