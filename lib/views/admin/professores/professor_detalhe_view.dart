import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/tema.dart';
import '../../../controllers/professor_detalhe_controller.dart';
import '../../../models/professor_model.dart';
import '../../../widgets/cartao_patrimonio.dart';
import '../../../widgets/esqueleto_lista.dart';
import '../../../widgets/estado_vazio.dart';
import '../../../widgets/linha_dado.dart';
import '../../../widgets/mensagem_erro.dart';

/// Detalhe do professor com os bens sob sua responsabilidade (RF06.3).
///
/// Uma única chamada (`GET /admin/professores/{id}`) devolve o docente e
/// a lista de patrimonies, então a tela mostra as duas coisas sem uma
/// segunda requisição.
class ProfessorDetalheView extends GetView<ProfessorDetalheController> {
  const ProfessorDetalheView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professor')),
      body: SafeArea(
        child: Obx(
          () => _corpo(context, controller.carregando.value, controller.erro.value),
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context, bool carregando, String erro) {
    if (carregando && controller.detalhe.value == null) {
      return const EsqueletoLista(quantidade: 3);
    }

    if (erro.isNotEmpty) {
      return _MensagemDeErro(mensagem: erro, aoTentarNovamente: controller.recarregar);
    }

    final detalhe = controller.detalhe.value;
    if (detalhe == null) {
      return const EstadoVazio(
        icone: Icons.person_search_outlined,
        titulo: 'Professor não encontrado',
        descricao: 'O registro informado não existe mais.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _CabecalhoProfessor(detalhe: detalhe),
        const SizedBox(height: 20),
        Row(
          children: [
            const TituloSecao('Bens sob responsabilidade', icone: Icons.inventory_2_outlined),
            const Spacer(),
            Text(
              '${detalhe.totalPatrimonios}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Tema.azulPrimario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (detalhe.semBens)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EstadoVazio(
              icone: Icons.inventory_2_outlined,
              titulo: 'Nenhum bem vinculado',
              descricao:
                  'Este professor ainda não tem equipamentos sob sua '
                  'responsabilidade. Use "Atribuir" na tela de patrimícios '
                  'para vincular um bem.',
            ),
          )
        else
          ...detalhe.patrimonios.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartaoPatrimonio(patrimonio: p),
            ),
          ),
      ],
    );
  }
}

class _CabecalhoProfessor extends StatelessWidget {
  const _CabecalhoProfessor({required this.detalhe});

  final ProfessorDetalheModel detalhe;

  @override
  Widget build(BuildContext context) {
    final p = detalhe.professor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Tema.azulPrimario, Tema.azulEscuro],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  p.iniciais,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.matricula.isEmpty ? 'Sem matrícula' : p.matricula,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LinhaBranca(rotulo: 'Departamento', valor: p.departamento),
          _LinhaBranca(rotulo: 'E-mail', valor: p.email),
          _LinhaBranca(rotulo: 'Telefone', valor: p.telefoneFormatado),
          if (p.cpf.isNotEmpty) _LinhaBranca(rotulo: 'CPF', valor: p.cpf),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${p.rotuloBens} (RN04)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rótulo/valor em branco, para o cartão de fundo escuro.
class _LinhaBranca extends StatelessWidget {
  const _LinhaBranca({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              rotulo,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MensagemDeErro extends StatelessWidget {
  const _MensagemDeErro({required this.mensagem, required this.aoTentarNovamente});

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
