import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/rotas.dart';
import '../../../app/tema.dart';
import '../../../controllers/admin_usuarios_controller.dart';
import '../../../models/status_patrimonio.dart';
import '../../../models/usuario_admin_model.dart';
import '../../../widgets/badge_status.dart';
import '../../../widgets/botao_primario.dart';
import '../../../widgets/campo_texto.dart';
import '../../../widgets/cartao_professor.dart';
import '../../../widgets/esqueleto_lista.dart';
import '../../../widgets/estado_vazio.dart';
import '../../../widgets/mensagem_erro.dart';

/// Listagem de usuários do sistema (Parte 6 — Administração Geral).
///
/// Acesso exclusivo do Coordenador: a rota é protegida pelo
/// `AdminMiddleware`, e o próprio backend responde `403` a um docente
/// que insistisse (RN03). A alteração de papel é uma operação de
/// elevação de privilégio — por isso exige confirmação explícita.
///
/// A tela cobre os três estados do RNF02: esqueleto durante o
/// carregamento, estado vazio sem usuário cadastrado e mensagem de erro
/// com botão de nova tentativa.
class UsuariosListaView extends GetView<AdminUsuariosController> {
  const UsuariosListaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários do sistema')),
      body: SafeArea(
        child: Column(
          children: [
            _CampoBusca(controller: controller),
            Expanded(child: Obx(() => _corpo(context))),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final vazio = controller.usuarios.isEmpty &&
            controller.busca.value.trim().isEmpty;
        if (vazio) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: controller.recarregar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        );
      }),
    );
  }

  /// Decide o que desenhar conforme o estado do Controller (RNF02).
  Widget _corpo(BuildContext context) {
    final erro = controller.erro.value;
    final lista = controller.resultados;

    if (controller.carregando.value && controller.usuarios.isEmpty) {
      return const EsqueletoLista();
    }

    if (erro.isNotEmpty) {
      return _ErroComRetry(mensagem: erro, aoTentarNovamente: controller.recarregar);
    }

    if (lista.isEmpty) {
      return controller.buscaSemResultado
          ? EstadoVazio(
              icone: Icons.search_off_rounded,
              titulo: 'Nenhum resultado',
              descricao:
                  'Nenhum usuário encontrado para "${controller.busca.value}". '
                  'Tente outro termo.',
              acao: TextButton(
                onPressed: () => controller.filtrar(''),
                child: const Text('Limpar busca'),
              ),
            )
          : EstadoVazio(
              icone: Icons.person_off_outlined,
              titulo: 'Nenhum usuário cadastrado',
              descricao:
                  'Ainda não há usuários no sistema da escola. '
                  'Use a API para criar o primeiro.',
              acao: BotaoPrimario(
                texto: 'Atualizar',
                icone: Icons.refresh_rounded,
                aoTocar: controller.recarregar,
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
        itemBuilder: (context, i) => _CardUsuario(
          usuario: lista[i],
          aoAlterarPapel: controller.alterarPapel,
        ),
      ),
    );
  }
}

/// Campo de busca por nome, e-mail, matrícula, departamento ou telefone.
class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controller});

  final AdminUsuariosController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: CampoTexto(
        rotulo: 'Buscar usuário',
        dica: 'Nome, e-mail, matrícula, departamento ou telefone',
        icone: Icons.search_rounded,
        teclado: TextInputType.text,
        aoAlterar: controller.filtrar,
      ),
    );
  }
}

/// Card de um usuário com o seletor de papel.
class _CardUsuario extends StatelessWidget {
  const _CardUsuario({
    required this.usuario,
    required this.aoAlterarPapel,
  });

  final UsuarioAdminModel usuario;
  final Future<bool> Function(int id, String novoPapel) aoAlterarPapel;

  @override
  Widget build(BuildContext context) {
    final papelAtual = usuario.role;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(usuario: usuario),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          usuario.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.resumoInstitucional,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  BadgeStatus(
                    status: _statusParaBadge(papelAtual),
                    compacto: true,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Alterar papel de ${usuario.nome}',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _confirmarAlteracaoPapel(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mapeia o papel textual para um `StatusPatrimonio` apenas para
  /// reaproveitar a paleta de cores do `BadgeStatus` (que já existe no
  /// projeto). Não há relação semântica — é reuso de cor.
  StatusPatrimonio _statusParaBadge(String papel) => switch (papel) {
        'admin' => StatusPatrimonio.emUso,
        'professor' => StatusPatrimonio.disponivel,
        _ => StatusPatrimonio.indefinido,
      };

  Future<void> _confirmarAlteracaoPapel(BuildContext context) async {
    final papelNovo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoPapel(usuario: usuario),
    );
    if (papelNovo == null || papelNovo == usuario.role) return;

    final ok = await aoAlterarPapel(usuario.id, papelNovo);
    if (!ok && context.mounted) {
      // O erro já fica visível no Controller (em `erro`); a View apenas
      // não fecha o diálogo — o usuário lê e tenta de novo.
      return;
    }
    if (context.mounted) {
      Get.snackbar(
        'Papel atualizado',
        '${usuario.nome} agora é ${_rotulo(papelNovo)}.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1B8A5A),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  String _rotulo(String papel) => switch (papel) {
        'admin' => 'Coordenador',
        'professor' => 'Professor',
        _ => 'Usuário',
      };
}

/// Avatar com as iniciais do usuário.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.usuario});

  final UsuarioAdminModel usuario;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Tema.azulPrimario.withValues(alpha: 0.12),
      child: Text(
        usuario.iniciais,
        style: const TextStyle(
          color: Tema.azulPrimario,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Diálogo de confirmação para alterar o papel de um usuário.
///
/// É uma operação de **elevação de privilégio**: o diálogo avisa
/// claramente antes de dar acesso total ao patrimônio da escola.
class _DialogoPapel extends StatelessWidget {
  const _DialogoPapel({required this.usuario});

  final UsuarioAdminModel usuario;

  @override
  Widget build(BuildContext context) {
    String? papelSelecionado;

    return AlertDialog(
      title: Text('Alterar papel de ${usuario.nome}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Papel atual: ${_rotulo(usuario.role)}.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ..._papeisDisponiveis.map((papel) {
            return RadioListTile<String>(
              title: Text(_rotulo(papel)),
              value: papel,
              groupValue: papelSelecionado,
              onChanged: (novo) => papelSelecionado = novo,
              activeColor: Tema.azulPrimario,
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotaoPrimario(
          texto: 'Confirmar',
          aoTocar: papelSelecionado == null ||
                  papelSelecionado == usuario.role
              ? null
              : () => Navigator.of(context).pop(papelSelecionado),
        ),
      ],
    );
  }

  static const _papeisDisponiveis = ['admin', 'professor', 'user'];

  String _rotulo(String papel) => switch (papel) {
        'admin' => 'Coordenador',
        'professor' => 'Professor',
        _ => 'Usuário',
      };
}

/// Falha de carga com ação de recuperação (RNF02).
class _ErroComRetry extends StatelessWidget {
  const _ErroComRetry({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final Future<void> Function() aoTentarNovamente;

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

/// Extensão para expor `resumoInstitucional` no `UsuarioAdminModel`,
/// igual ao que `ProfessorModel` já faz.
extension UsuarioAdminResumo on UsuarioAdminModel {
  String get resumoInstitucional {
    final partes = [matricula, departamento]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'Sem matrícula informada';
    return partes.join(' · ');
  }
}
