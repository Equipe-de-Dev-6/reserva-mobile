import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../core/servicos/sessao_service.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/cabecalho_usuario.dart';
import '../../widgets/dialogo_logout.dart';
import '../../widgets/estado_vazio.dart';

/// Tela provisória do Painel do Coordenador.
///
/// Ela já valida o roteamento por role e o logout (RF04). O conteúdo
/// de gestão (dashboard, professores, patrimônios) entra na Parte 4.
class AdminHomeView extends GetView<AuthController> {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Get.find<SessaoService>().usuario.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Coordenador'),
        actions: [
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
              child: EstadoVazio(
                icone: Icons.dashboard_customize_outlined,
                titulo: 'Módulo 2 em construção',
                descricao: 'Dashboard de indicadores, gestão de professores e '
                    'gestão de patrimônios serão implementados na Parte 4. '
                    'Sessão ativa como $email.',
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
