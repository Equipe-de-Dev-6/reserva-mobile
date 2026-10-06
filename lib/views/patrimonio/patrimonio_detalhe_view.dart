import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/patrimonio_detalhe_controller.dart';
import '../../core/utils/data_hora.dart';
import '../../models/patrimonio_model.dart';
import '../../widgets/badge_status.dart';
import '../../widgets/mensagem_erro.dart';
import 'rotas_patrimonio.dart';

/// **RF07a — Tela de detalhe de um bem.**
///
/// Mostra a ficha completa: identificação, especificações, situação e
/// responsável. A edição usa o mesmo formulário do cadastro
/// (`PatrimonioFormView`), aberto com o bem em mãos — um formulário só,
/// com dois modos, em vez de duas telas quase iguais.
///
/// As ações de escrita só aparecem para o Coordinator (RN03).
class PatrimonioDetalheView extends GetView<PatrimonioDetalheController> {
  const PatrimonioDetalheView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do bem'),
        actions: [
          Obx(() {
            // Enquanto não há bem carregado, nem recarregar faz sentido.
            if (controller.patrimonio.value == null) {
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
      return _ErroDetalhe(
        mensagem: controller.erro.value,
        aoTentarNovamente: controller.carregar,
      );
    }

    final patrimonio = controller.patrimonio.value;
    if (patrimonio == null) {
      return _ErroDetalhe(
        mensagem: 'Bem não encontrado.',
        aoTentarNovamente: controller.carregar,
      );
    }

    return _Ficha(controller: controller, patrimonio: patrimonio);
  }
}

/// Modo de leitura.
class _Ficha extends StatelessWidget {
  const _Ficha({required this.controller, required this.patrimonio});

  final PatrimonioDetalheController controller;
  final PatrimonioModel patrimonio;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Padding inferior maior: dá espaço para o botão de excluir não
      // ficar colado na borda inferior (e atrás do gesture bar do iOS).
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Cabecalho(patrimonio: patrimonio, controller: controller),
        const SizedBox(height: 16),
        _Secao(
          titulo: 'Identificação',
          filhos: [
            _Linha(rotulo: 'Tombamento', valor: patrimonio.codigo),
            _Linha(rotulo: 'Categoria', valor: patrimonio.categoria),
            _Linha(rotulo: 'Marca', valor: patrimonio.marca),
            _Linha(rotulo: 'Modelo', valor: patrimonio.modelo),
            _Linha(
              rotulo: 'Número de série',
              valor: patrimonio.numeroSerieFormatado,
            ),
            _Linha(
              rotulo: 'Estado de conservação',
              valor: patrimonio.estadoConservacao,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Localização',
          filhos: [
            _Linha(
              rotulo: 'Onde está',
              valor: patrimonio.localizacao.isEmpty
                  ? 'Não informada'
                  : patrimonio.localizacao,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Responsável',
          filhos: [
            _Linha(
              rotulo: 'Professor',
              valor: patrimonio.professorNomeFormatado,
            ),
            if (patrimonio.professorEmail != null)
              _Linha(rotulo: 'E-mail', valor: patrimonio.professorEmail!),
            if (patrimonio.dataAtribuicao != null)
              _Linha(
                rotulo: 'Atribuído em',
                valor: DataHora.data(patrimonio.dataAtribuicao),
              ),
          ],
        ),
        if (patrimonio.observacoes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Secao(
            titulo: 'Observações',
            filhos: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  patrimonio.observacoes,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Registro',
          filhos: [
            _Linha(
              rotulo: 'Cadastrado em',
              valor: DataHora.dataHora(patrimonio.createdAt),
            ),
            _Linha(
              rotulo: 'Atualizado em',
              valor: DataHora.dataHora(patrimonio.updatedAt),
            ),
          ],
        ),

        // --- Ações de escrita: só Coordinator (RN03) -------------------
        if (controller.podeEditar) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(
              RotasPatrimonio.form,
              arguments: {'patrimonio': patrimonio},
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar cadastro'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmarExclusao(context),
            icon: Icon(Icons.delete_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            label: Text(
              'Excluir bem',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir patrimônio?'),
        content: Text(
          'O bem "${patrimonio.codigo}" será removido do acervo. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Excluir',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await controller.excluir();
    if (!context.mounted) return;

    if (ok) {
      Get.back<dynamic>();
      Get.snackbar(
        'Patrimônio excluído',
        '${patrimonio.codigo} foi removido do acervo.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

/// Cabeçalho com nome, tombamento e badge de status.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.patrimonio, required this.controller});

  final PatrimonioModel patrimonio;
  final PatrimonioDetalheController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    patrimonio.nome.isEmpty
                        ? 'Bem sem nome'
                        : patrimonio.nome,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 10),
                BadgeStatus(status: patrimonio.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              patrimonio.codigo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4DB1),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BadgeStatus.corDe(patrimonio.status)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                controller.descricaoStatus,
                style: TextStyle(
                  fontSize: 13,
                  color: BadgeStatus.corDe(patrimonio.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de seção com título.
class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.filhos});

  final String titulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...filhos,
          ],
        ),
      ),
    );
  }
}

/// Linha "rótulo: valor" que colapsa quando o valor é vazio.
///
/// Sem isso, um bem sem marca mostraria três linhas com "—" e o cartão
/// ficaria alto sem informação nenhuma.
class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              rotulo,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroDetalhe extends StatelessWidget {
  const _ErroDetalhe({required this.mensagem, required this.aoTentarNovamente});

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
            Icon(Icons.error_outline_rounded,
                size: 44, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            MensagemErro.erro(mensagem),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.offNamed(RotasPatrimonio.lista),
              child: const Text('Voltar para a lista'),
            ),
          ],
        ),
      ),
    );
  }
}
