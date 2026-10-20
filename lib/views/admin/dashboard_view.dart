import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/patrimonio_stats_model.dart';
import '../../widgets/cartao_indicador.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/mensagem_erro.dart';

/// **RF05 — Dashboard de indicadores do Coordenador.**
///
/// A situação patrimonial da escola em uma tela: total de bens, itens
/// em uso, disponíveis, em manutenção, número de docentes e a
/// distribuição do acervo por categoria.
///
/// Todos os números vêm do backend (`GET /admin/patrimonios/stats`) —
/// o app não conta nada, para não divergir do servidor.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores'),
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
              onPressed: () => controller.carregar(silencioso: true),
            );
          }),
        ],
      ),
      body: SafeArea(child: Obx(() => _corpo(context))),
    );
  }

  Widget _corpo(BuildContext context) {
    if (controller.carregando.value) {
      return const _EsqueletoDashboard();
    }

    final dados = controller.indicadores.value;

    if (dados == null) {
      return _EstadoErro(
        mensagem: controller.erro.value.isEmpty
            ? 'Não foi possível carregar os indicadores.'
            : controller.erro.value,
        aoTentarNovamente: controller.carregar,
      );
    }

    if (dados.acervoVazio) {
      return EstadoVazio(
        icone: Icons.inventory_2_outlined,
        titulo: controller.tituloEstadoVazio,
        descricao: controller.descricaoEstadoVazio,
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.carregar(silencioso: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _GradeIndicadores(dados: dados),
          const SizedBox(height: 20),
          _SecaoDocentes(dados: dados),
          if (dados.categoriasOrdenadas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SecaoCategorias(dados: dados),
          ],
          if (controller.erro.value.isNotEmpty) ...[
            const SizedBox(height: 16),
            MensagemErro.erro(controller.erro.value),
          ],
        ],
      ),
    );
  }
}

/// Os quatro indicadores principais, em grade de duas colunas.
class _GradeIndicadores extends StatelessWidget {
  const _GradeIndicadores({required this.dados});

  final PatrimonioStatsModel dados;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      // `shrinkWrap` + `NeverScrollableScrollPhysics`: a grade vive
      // dentro do `ListView` da tela, não é uma lista rolável própria.
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        CartaoIndicador(
          rotulo: 'Total de bens',
          valor: '${dados.totalPatrimonios}',
          icone: Icons.inventory_2_outlined,
          cor: Tema.azulPrimario,
        ),
        CartaoIndicador(
          rotulo: 'Em uso',
          valor: '${dados.patrimoniosEmUso}',
          icone: Icons.person_outline,
          cor: Tema.azulEscuro,
          detalhe: 'atribuídos a docentes',
        ),
        CartaoIndicador(
          rotulo: 'Disponíveis',
          valor: '${dados.patrimoniosDisponiveis}',
          icone: Icons.check_circle_outline,
          cor: Tema.sucesso,
          detalhe: 'no almoxarifado',
        ),
        CartaoIndicador(
          rotulo: 'Em manutenção',
          valor: '${dados.patrimoniosEmManutencao}',
          icone: Icons.build_outlined,
          cor: Tema.alerta,
        ),
      ],
    );
  }
}

/// Resumo do corpo docente.
class _SecaoDocentes extends StatelessWidget {
  const _SecaoDocentes({required this.dados});

  final PatrimonioStatsModel dados;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 18, color: Tema.azulPrimario),
                const SizedBox(width: 8),
                Text(
                  'Corpo docente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Linha(
              rotulo: 'Docentes cadastrados',
              valor: '${dados.totalProfessores}',
            ),
            _Linha(
              rotulo: 'Com equipamentos sob responsabilidade',
              valor: '${dados.totalProfessoresComPatrimonios}',
            ),
          ],
        ),
      ),
    );
  }
}

/// Distribuição do acervo por categoria.
class _SecaoCategorias extends StatelessWidget {
  const _SecaoCategorias({required this.dados});

  final PatrimonioStatsModel dados;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 18, color: Tema.azulPrimario),
                const SizedBox(width: 8),
                Text(
                  'Acervo por categoria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entrada in dados.categoriasOrdenadas)
              BarraCategoria(
                categoria: entrada.key,
                quantidade: entrada.value,
                fracao: dados.percentualDe(entrada.key),
              ),
          ],
        ),
      ),
    );
  }
}

/// Linha "rótulo: valor" do bloco do corpo docente.
class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // `Flexible` + ellipsis: o rótulo é longo ("Com equipamentos
          // sob responsabilidade") e precisa ceder espaço ao número.
          Flexible(
            child: Text(
              rotulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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

/// Skeleton do dashboard enquanto os indicadores carregam (RNF02).
class _EsqueletoDashboard extends StatelessWidget {
  const _EsqueletoDashboard();

  @override
  Widget build(BuildContext context) {
    final cor = Colors.black.withValues(alpha: 0.06);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
