import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/patrimonio_detalhe_controller.dart';
import '../../core/utils/data_hora.dart';
import '../../models/patrimonio_model.dart';
import '../../widgets/badge_status.dart';
import '../../widgets/mensagem_erro.dart';

/// **RF08 — Tela de detalhe de um bem, na visão do Docente.**
///
/// A versão do Coordenador (`PatrimonioDetalheView`) termina em ações de
/// escrita: editar, excluir, atribuir, devolver, histórico. Nenhuma
/// delas pode existir aqui — o docente tem **leitura estrita** dos bens
/// vinculados a ele (RN03), e o backend recusaria qualquer mutação com
/// `403 Forbidden`.
///
/// Reaproveita o mesmo `PatrimonioDetalheController` da tela do
/// Coordenador: a lógica de carga (e o tratamento do `403` de um bem
/// que não é dele) é idêntica; só o desenho muda.
class PatrimonioDetalheProfessorView
    extends GetView<PatrimonioDetalheController> {
  const PatrimonioDetalheProfessorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do bem'),
        actions: [
          Obx(() {
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

    final patrimonio = controller.patrimonio.value;
    if (controller.erro.value.isNotEmpty || patrimonio == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: Colors.black.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              MensagemErro.erro(
                controller.erro.value.isEmpty
                    ? 'Bem não encontrado.'
                    : controller.erro.value,
              ),
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

    return _Ficha(patrimonio: patrimonio);
  }
}

/// Ficha em modo leitura — nenhuma ação de escrita nesta árvore (RN03).
class _Ficha extends StatelessWidget {
  const _Ficha({required this.patrimonio});

  final PatrimonioModel patrimonio;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _Cabecalho(patrimonio: patrimonio),
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
          titulo: 'Atribuição',
          filhos: [
            _Linha(
              rotulo: 'Atribuído em',
              valor: patrimonio.dataAtribuicaoFormatada,
            ),
          ],
        ),
        if (patrimonio.descricao.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Secao(
            titulo: 'Descrição',
            filhos: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  patrimonio.descricao,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                ),
              ),
            ],
          ),
        ],
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
          ],
        ),
      ],
    );
  }
}

/// Cabeçalho com nome, tombamento e badge de status.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.patrimonio});

  final PatrimonioModel patrimonio;

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
                color: Tema.azulPrimario,
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
                patrimonio.status.descricao,
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
