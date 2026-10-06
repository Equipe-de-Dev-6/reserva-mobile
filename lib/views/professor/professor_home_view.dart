import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../core/servicos/sessao_service.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/cabecalho_usuario.dart';
import '../../widgets/dialogo_logout.dart';
import '../../widgets/estado_vazio.dart';

/// Tela provisória do Painel do Professor.
///
/// A visão do docente é estritamente de leitura (RN03): aqui não haverá
/// botão de criar, editar ou excluir. A lista dos bens vinculados
/// (RF08) entra na Parte 5. O que já está entregue é o acesso ao
/// próprio Perfil (RF09 / RN06), liberado para os dois papéis.
class ProfessorHomeView extends GetView<AuthController> {
  const ProfessorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Get.find<SessaoService>().usuario.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Patrimônios'),
        actions: [
          IconButton(
            tooltip: 'Meu perfil',
            onPressed: () => Get.toNamed(Rotas.perfil),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => confirmarLogout(context, controller.logout),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CabecalhoUsuario(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  _AtalhoPainel(
                    icone: Icons.account_circle_outlined,
                    titulo: 'Meu perfil',
                    descricao:
                        'Atualizar telefone e contato, e alterar sua senha '
                        'de acesso.',
                    aoTocar: () => Get.toNamed(Rotas.perfil),
                  ),
                  const SizedBox(height: 14),
                  EstadoVazio(
                    icone: Icons.devices_other_outlined,
                    titulo: 'Módulo 3 em construção',
                    descricao: 'A consulta dos seus patrimônios será '
                        'implementada na Parte 5. '
                        'Sessão ativa como $email.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: BotaoPrimario(
                texto: 'Encerrar sessão',
                icone: Icons.logout_rounded,
                cor: Tema.perigo,
                aoTocar: () => confirmarLogout(context, controller.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de atalho do painel do docente (RNF04).
class _AtalhoPainel extends StatelessWidget {
  const _AtalhoPainel({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Tema.azulPrimario.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: Tema.azulPrimario, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.black.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
