import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_controller.dart';
import '../../core/servicos/patrimonio_service.dart';
import '../../core/servicos/sessao_service.dart';
import '../../models/patrimonio_model.dart';
import '../../widgets/badge_status.dart';
import '../../widgets/card_patrimonio.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/mensagem_erro.dart';
import 'patrimonio_detalhe_view.dart';
import 'patrimonio_form_view.dart';

/// **RF07a — Listagem de patrimônios com busca e filtros.**
///
/// A tela tem quatro estados e cada um ocupa a área da lista:
///
/// | Estado | O que aparece |
/// |--------|---------------|
/// | carregando | shimmer/skeleton dos cards (RNF02) |
/// | erro | [MensagemErro] com botão "Tentar novamente" |
/// | vazio | [EstadoVazio] — texto muda se há filtro ativo |
/// | lista | [CardPatrimonio] por bem |
///
/// O botão de cadastrar só aparece para o Coordinator: o Professor não
/// deve **enxergar** a ação de escrita (RN03).
class PatrimonioListaView extends GetView<PatrimonioController> {
  const PatrimonioListaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrimônios'),
        actions: [
          Obx(() => controller.carregando.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Atualizar',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: controller.carregar,
                )),
        ],
      ),

      // FAB escondido para o docente: a regra RN03 é de *visibilidade*,
      // não só de permissão no servidor.
      floatingActionButton: Obx(() {
        final ehAdmin =
            Get.find<SessaoService>().usuario.value?.isAdmin ?? false;
        if (!ehAdmin) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => Get.toNamed(
            RotasPatrimonio.form,
            arguments: const {'id': 0},
          ),
          icon: const Icon(Icons.add),
          label: const Text('Novo bem'),
        );
      }),

      body: SafeArea(
        child: Column(
          children: [
            _BarraFiltros(controller: controller),
            const Divider(height: 1),
            Expanded(child: _CorpoLista(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Busca + chips de status + menu de categoria.
class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({required this.controller});

  final PatrimonioController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // --- Busca por tombamento -------------------------------------
          TextField(
            controller: controller.buscaCtrl,
            onChanged: controller.aoDigitarBusca,
            onSubmitted: (_) => controller.buscarAgora(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por tombamento, nome ou marca',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Obx(() => controller.busca.value.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.buscaCtrl.clear();
                        controller.buscarAgora();
                      },
                    )),
            ),
          ),
          const SizedBox(height: 10),

          // --- Chips de status -----------------------------------------
          //
          // `SingleChildScrollView` horizontal em vez de `Wrap`: em iPhone
          // SE os quatro chips não cabem em uma linha, e quebrar em duas
          // linhas empurraria a lista para baixo a cada toque.
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Obx(() => _ChipStatus(
                      rotulo: 'Todos',
                      status: null,
                      selecionado: controller.statusSelecionado.value == null,
                      aoTocar: () => controller.alternarStatus(null),
                    )),
                ...StatusPatrimonio.filtráveis.map(
                  (status) => Obx(() => _ChipStatus(
                        rotulo: status.rotulo,
                        status: status,
                        selecionado:
                            controller.statusSelecionado.value == status,
                        aoTocar: () => controller.alternarStatus(status),
                      )),
                ),
                _ChipCategoria(controller: controller),
              ],
            ),
          ),

          // --- Resumo + limpar filtros ----------------------------------
          Obx(() {
            final temFiltro = controller.temFiltroAtivo.value;
            if (!temFiltro) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${controller.patrimonios.length} '
                      '${controller.patrimonios.length == 1 ? "resultado" : "resultados"}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.limparFiltros,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Limpar'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  const _ChipStatus({
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
    this.status,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback aoTocar;
  final StatusPatrimonio? status;

  @override
  Widget build(BuildContext context) {
    final cor = status == null ? Tema.azulPrimario : BadgeStatus.corDe(status!);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: (_) => aoTocar(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selecionado ? Colors.white : cor,
        ),
        selectedColor: cor,
        backgroundColor: cor.withValues(alpha: 0.08),
        side: BorderSide(color: cor.withValues(alpha: 0.35)),
      ),
    );
  }
}

/// Filtro de categoria: um `DropdownButton`, porque são quatro valores e
/// cada um já ocupa meia linha em tela estreita.
class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({required this.controller});

  final PatrimonioController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: Obx(() => DropdownButton<String?>(
              value: categoriasPatrimonio
                      .contains(controller.categoriaSelecionada.value)
                  ? controller.categoriaSelecionada.value
                  : null,
              hint: const Text('Categoria',
                  style: TextStyle(fontSize: 12.5)),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final categoria in categoriasPatrimonio)
                  DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria,
                        style: const TextStyle(fontSize: 13)),
                  ),
              ],
              onChanged: controller.escolherCategoria,
            )),
      ),
    );
  }
}

/// Carrega, erro, vazio e lista — decide qual dos quatro mostrar.
class _CorpoLista extends StatelessWidget {
  const _CorpoLista({required this.controller});

  final PatrimonioController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.carregando.value && controller.patrimonios.isEmpty) {
        return const ListaSkeletonPatrimonio();
      }

      if (controller.erro.value.isNotEmpty && controller.patrimonios.isEmpty) {
        return _EstadoErro(
          mensagem: controller.erro.value,
          aoTentarNovamente: controller.carregar,
        );
      }

      if (controller.patrimonios.isEmpty) {
        return EstadoVazio(
          icone: controller.temFiltroAtivo.value
              ? Icons.search_off_rounded
              : Icons.inventory_2_outlined,
          titulo: controller.tituloEstadoVazio,
          descricao: controller.descricaoEstadoVazio,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.carregar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          itemCount: controller.patrimonios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, indice) {
            final patrimonio = controller.patrimonios[indice];
            return CardPatrimonio(
              patrimonio: patrimonio,
              aoTocar: () => abrirDetalhe(patrimonio),
            );
          },
        ),
      );
    });
  }

  void abrirDetalhe(PatrimonioModel patrimonio) {
    Get.toNamed(RotasPatrimonio.detalhe, arguments: {'id': patrimonio.id});
  }
}

/// Falha de carga com ação de recuperação (RNF02).
class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final Future<void> Function() aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Colors.black.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            MensagemErro.erro(mensagem),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton dos cards durante a carga (RNF02).
///
/// Vive aqui, e não em `widgets/`, porque foi desenhado para a forma
/// exata do [CardPatrimonio]. Se a biblioteca de shimmer do time ficar
/// disponível, este é o ponto a substituir.
class ListaSkeletonPatrimonio extends StatefulWidget {
  const ListaSkeletonPatrimonio({super.key, this.quantidade = 5});

  final int quantidade;

  @override
  State<ListaSkeletonPatrimonio> createState() =>
      _ListaSkeletonPatrimonioState();
}

class _ListaSkeletonPatrimonioState extends State<ListaSkeletonPatrimonio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corBase = Colors.black.withValues(alpha: 0.06);
    final corBrilho = Colors.black.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final cor = Color.lerp(corBase, corBrilho, _controller.value)!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          itemCount: widget.quantidade,
          itemBuilder: (context, _) => Container(
            height: 116,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
