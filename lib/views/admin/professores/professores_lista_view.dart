import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/rotas.dart';
import '../../../controllers/professor_lista_controller.dart';
import '../../../models/professor_model.dart';
import '../../../widgets/botao_primario.dart';
import '../../../widgets/campo_texto.dart';
import '../../../widgets/cartao_professor.dart';
import '../../../widgets/esqueleto_lista.dart';
import '../../../widgets/estado_vazio.dart';
import '../../../widgets/mensagem_erro.dart';

/// Listagem do corpo docente (RF06.1).
///
/// Acesso exclusivo do Coordenador: a rota é protegida pelo
/// `AdminMiddleware`, e o próprio backend responde 403 a um docente que
/// insistisse (RN03).
///
/// A tela cobre os três estados do RNF02: esqueleto durante o
/// carregamento, estado vazio sem docente cadastrado e mensagem de erro
/// com botão de nova tentativa.
class ProfessoresListaView extends GetView<ProfessorListaController> {
  const ProfessoresListaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professores')),
      body: SafeArea(
        child: Column(
          children: [
            const _ResumoDocentes(),
            _CampoBusca(controller: controller),
            Expanded(child: Obx(() => _corpo(context))),
          ],
        ),
      ),
      // O FAB some quando não há nenhum docente na lista: nesse caso o
      // próprio estado vazio já oferece o botão "Cadastrar professor".
      // Com os dois na tela, o FAB caía por cima do botão — e o usuário
      // via o botão cortado embaixo dele.
      floatingActionButton: Obx(() {
        final vazio = controller.professores.isEmpty &&
            controller.busca.value.trim().isEmpty;
        if (vazio) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: _abrirCadastro,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo professor'),
        );
      }),
    );
  }

  void _abrirCadastro() => Get.toNamed(Rotas.professorNovo);

  /// Decide o que desenhar conforme o estado do Controller (RNF02).
  Widget _corpo(BuildContext context) {
    final erro = controller.erro.value;
    final lista = controller.resultados;

    // Primeiro carregamento: esqueleto em vez de spinner centralizado.
    if (controller.carregando.value && controller.professores.isEmpty) {
      return const EsqueletoLista();
    }

    if (erro.isNotEmpty) {
      return _ErroComRetry(mensagem: erro, aoTentarNovamente: controller.recarregar);
    }

    if (lista.isEmpty) {
      // "Nenhum docente cadastrado" e "busca sem resultado" são
      // mensagens diferentes: a primeira orienta o próximo passo
      // (cadastrar), a segunda orienta a limpar o filtro.
      return controller.buscaSemResultado
          ? EstadoVazio(
              icone: Icons.search_off_rounded,
              titulo: 'Nenhum resultado',
              descricao:
                  'Nenhum docente encontrado para "${controller.busca.value}". '
                  'Tente outro termo.',
              acao: TextButton(
                onPressed: () => controller.filtrar(''),
                child: const Text('Limpar busca'),
              ),
            )
          : EstadoVazio(
              icone: Icons.school_outlined,
              titulo: 'Nenhum professor cadastrado',
              descricao:
                  'Cadastre o corpo docente. O professor não tem cadastro '
                  'próprio: o Coordinator registra e define a senha '
                  'provisória de acesso.',
              acao: BotaoPrimario(
                texto: 'Cadastrar professor',
                icone: Icons.person_add_alt_1_rounded,
                aoTocar: _abrirCadastro,
              ),
            );
    }

    return RefreshIndicator(
      onRefresh: controller.recarregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: lista.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => CartaoProfessor(
          professor: lista[i],
          aoTocar: () => _abrirDetalhe(lista[i]),
        ),
      ),
    );
  }

  void _abrirDetalhe(ProfessorModel p) =>
      Get.toNamed('${Rotas.professorDetalhe}/${p.id}');
}

/// Resumo do corpo docente: quantos docentes e quantos bens estão
/// distribuídos entre eles. É o retrato rápido que o RF06 pede na
/// listagem ("indicador da quantidade de bens").
class _ResumoDocentes extends StatelessWidget {
  const _ResumoDocentes();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfessorListaController>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4DB1), Color(0xFF0F2E6B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(
        () => Row(
          children: [
            _Numero(
              valor: '${controller.totalDocentes}',
              rotulo: controller.totalDocentes == 1 ? 'docente' : 'docentes',
            ),
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white.withValues(alpha: 0.25),
            ),
            _Numero(
              valor: '${controller.totalBens}',
              rotulo: controller.totalBens == 1 ? 'bem vinculado' : 'bens vinculados',
            ),
          ],
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controller});

  final ProfessorListaController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: CampoTexto(
        rotulo: 'Buscar professor',
        dica: 'Nome, e-mail, matrícula ou departamento',
        icone: Icons.search_rounded,
        teclado: TextInputType.text,
        // Sem `TextEditingController` de propósito: a busca é efêmera e
        // precisa ser limpa ao sair da tela, junto com o Controller.
        aoAlterar: controller.filtrar,
      ),
    );
  }
}

class _ErroComRetry extends StatelessWidget {
  const _ErroComRetry({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MensagemErro.erro(mensagem),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
