import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../core/servicos/sessao_service.dart';
import '../../views/patrimonio/rotas_patrimonio.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/cabecalho_usuario.dart';
import '../../widgets/dialogo_logout.dart';

/// **Painel do Coordenador (RF05–RF07).**
///
/// É o menu do gestor da escola: de onde saem o dashboard de
/// indicadores, o acervo de patrimônios e o corpo docente.
///
/// Os atalhos são condicionados ao papel: o|Coordenador vê os três
/// módulos de gestão, mas nunca uma ação de escrita de bens — quem
/// escreve é quem tem a custódia do acervo.
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
                    icone: Icons.dashboard_customize_outlined,
                    titulo: 'Indicadores',
                    descricao:
                        'Total de bens, itens em uso, disponíveis, em '
                        'manutenção e a distribuição por categoria.',
                    aoTocar: () => Get.toNamed(Rotas.dashboard),
                  ),
                  const SizedBox(height: 14),
                  _AtalhoPainel(
                    icone: Icons.inventory_2_outlined,
                    titulo: 'Patrimônios',
                    descricao:
                        'Consulte, cadastre, entregue e devolva os '
                        'equipamentos da escola.',
                    aoTocar: () => Get.toNamed(RotasPatrimonio.lista),
                  ),
                  const SizedBox(height: 14),
                  _AtalhoPainel(
                    icone: Icons.school_outlined,
                    titulo: 'Professores',
                    descricao:
                        'Cadastre docentes e veja quantos bens cada um tem '
                        'sob responsabilidade.',
                    aoTocar: () => Get.toNamed(Rotas.professores),
                  ),
                  const SizedBox(height: 14),
                  _AtalhoPainel(
                    icone: Icons.account_circle_outlined,
                    titulo: 'Meu perfil',
                    descricao:
                        'Atualize seu telefone e contato, e altere sua '
                        'senha de acesso.',
                    aoTocar: () => Get.toNamed(Rotas.perfil),
                  ),
                  const SizedBox(height: 14),
                  _AtalhoPainel(
                    icone: Icons.people_alt_outlined,
                    titulo: 'Usuários do sistema',
                    descricao:
                        'Lista todos os usuários da escola, o papel de cada '
                        'um e permite promover ou rebaixar o acesso.',
                    aoTocar: () => Get.toNamed(Rotas.usuarios),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sessão ativa como $email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
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

/// Cartão de atalho do painel administrativo (RNF04).
///
/// Um único widget para todos os módulos: adicionar uma área nova é
/// inserir mais um `_AtalhoPainel` na lista, sem duplicar layout.
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
