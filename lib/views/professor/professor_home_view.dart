import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
/// entra na Parte 5.
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
                icone: Icons.devices_other_outlined,
                titulo: 'Módulo 3 em construção',
                descricao: 'A consulta dos seus patrimônios e o gerenciamento '
                    'de perfil serão implementados na Parte 5. '
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
