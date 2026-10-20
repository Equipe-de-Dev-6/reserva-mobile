import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/perfil_controller.dart';
import '../../core/utils/validadores.dart';
import '../../models/usuario_model.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/esqueleto_lista.dart';
import '../../widgets/linha_dado.dart';
import '../../widgets/mensagem_erro.dart';

/// Tela de Perfil (RF09 / RN06).
///
/// Aberta por|Coordenador **e** por docente: a RN06 dá ao professor
/// autonomia para manter o próprio telefone e trocar a própria senha.
///
/// Três estados dentro da mesma tela, todos guiados pelo Controller:
///  * **leitura** — dados cadastrais, como o RF09 pede;
///  * **edição** — abre o formulário já preenchido e envia só o que
///    mudou;
///  * **segurança** — o formulário de nova senha, que também usa
///    `PUT /profile` (chave `newPassword`).
class PerfilView extends GetView<PerfilController> {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SafeArea(
        child: Obx(() => _corpo(context)),
      ),
    );
  }

  Widget _corpo(BuildContext context) {
    final carregando = controller.carregando.value;
    final usuario = controller.perfil.value;
    final erro = controller.erro.value;

    if (carregando && usuario == null) {
      return const EsqueletoLista(quantidade: 2, altura: 150);
    }

    if (usuario == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MensagemErro.erro(
                erro.isEmpty ? 'Não foi possível carregar o perfil.' : erro,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: controller.carregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _Cabecalho(usuario: usuario),
        const SizedBox(height: 16),
        _CartaoDados(controller: controller, usuario: usuario),
        const SizedBox(height: 16),
        _CartaoSenha(controller: controller),
      ],
    );
  }
}

/// Avatar + identificação. `CabecalhoUsuario` mostra a faixa dos painéis;
/// aqui o foco é a ficha do próprio usuário.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.usuario});

  final UsuarioModel usuario;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Tema.azulPrimario, Tema.azulEscuro],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              usuario.iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    usuario.isAdmin
                        ? 'Coordenador (admin)'
                        : 'Professor (docente)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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

/// Bloco 1 — dados cadastrais (leitura) e edição (RN06).
class _CartaoDados extends StatelessWidget {
  const _CartaoDados({required this.controller, required this.usuario});

  final PerfilController controller;
  final UsuarioModel usuario;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // `Expanded` dá largura **finita** ao `TituloSecao`: sem
                // ele, o `Row` interno do título receberia largura
                // infinita e o Flutter reclamaria de `Flexible` sob
                // constraint ilimitada (erro de layout em tempo real).
                const Expanded(
                  child: TituloSecao('Dados cadastrais',
                      icone: Icons.badge_outlined),
                ),
                const Spacer(),
                if (!controller.editando.value)
                  TextButton.icon(
                    onPressed: controller.abrirEdicao,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Obx(
              () => controller.editando.value
                  ? _FormularioDados(controller: controller)
                  : _Leitura(controller: controller, usuario: usuario),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leitura extends StatelessWidget {
  const _Leitura({required this.controller, required this.usuario});

  final PerfilController controller;
  final UsuarioModel usuario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinhaDado(rotulo: 'Nome', valor: usuario.nome, icone: Icons.person_outline),
        LinhaDado(rotulo: 'E-mail', valor: usuario.email, icone: Icons.mail_outline),
        LinhaDado(rotulo: 'Matrícula', valor: usuario.matricula, icone: Icons.numbers),
        LinhaDado(
            rotulo: 'Departamento',
            valor: usuario.departamento,
            icone: Icons.apartment_rounded),
        LinhaDado(rotulo: 'CPF', valor: usuario.cpf, icone: Icons.badge_outlined),
        const Divider(height: 26, color: Color(0xFFE8EDF6)),
        const TituloSecao('Contato', icone: Icons.contact_phone_outlined),
        const SizedBox(height: 4),
        // Telefone em destaque: é o dado que o RF09 pede explicitamente
        // para o docente poder atualizar sozinho (RN06).
        LinhaDado(rotulo: 'Telefone', valor: usuario.telefone, icone: Icons.phone_outlined),
        LinhaDado(
          rotulo: 'E-mail emergência',
          valor: usuario.contatoEmergencia,
          icone: Icons.emergency_outlined,
        ),
        LinhaDado(rotulo: 'Endereço', valor: usuario.endereco, icone: Icons.home_outlined),
        LinhaDado(rotulo: 'Cidade/UF', valor: usuario.cidadeUf, icone: Icons.location_city_outlined),
        Obx(() {
          final aviso = controller.aviso.value;
          if (aviso.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: MensagemErro.mensagem(aviso, tipo: TipoMensagem.sucesso),
          );
        }),
        Obx(() {
          final erro = controller.erro.value;
          if (erro.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: MensagemErro.erro(erro),
          );
        }),
      ],
    );
  }
}

class _FormularioDados extends StatefulWidget {
  const _FormularioDados({required this.controller});

  final PerfilController controller;

  @override
  State<_FormularioDados> createState() => _FormularioDadosState();
}

class _FormularioDadosState extends State<_FormularioDados> {
  /// A FormKey mora na View (ver comentário em `auth_controller.dart`).
  final _formKey = GlobalKey<FormState>();

  PerfilController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          CampoTexto(
            rotulo: 'Nome',
            icone: Icons.person_outline_rounded,
            controlador: controller.nomeCtrl,
            teclado: TextInputType.name,
            validator: controller.validarNome,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Telefone',
            dica: '(11) 98888-7777',
            icone: Icons.phone_outlined,
            controlador: controller.telefoneCtrl,
            teclado: TextInputType.phone,
            validator: controller.validarTelefone,
            formatters: Validadores.formatadoresTelefone(),
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Departamento',
            icone: Icons.apartment_rounded,
            controlador: controller.departamentoCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Endereço',
            dica: 'Rua das Letras, 50',
            icone: Icons.home_outlined,
            controlador: controller.enderecoCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Cidade / UF',
            dica: 'São Paulo / SP',
            icone: Icons.location_city_outlined,
            controlador: controller.cidadeUfCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Contato de emergência',
            dica: 'Helena (11) 98888-0000',
            icone: Icons.emergency_outlined,
            controlador: controller.contatoEmergenciaCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 14),
          Obx(() {
            final erro = controller.erro.value;
            if (erro.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MensagemErro.erro(erro),
            );
          }),
          Obx(
            () => BotaoPrimario(
              texto: 'Salvar alterações',
              icone: Icons.save_outlined,
              carregando: controller.salvando.value,
              aoTocar: () => controller.salvarDados(_formKey.currentState!),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.salvando.value
                ? null
                : controller.fecharEdicao,
            child: const Text('Descartar alterações'),
          ),
        ],
      ),
    );
  }
}

/// Bloco 2 — redefinição da senha de acesso.
class _CartaoSenha extends StatelessWidget {
  const _CartaoSenha({required this.controller});

  final PerfilController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Obx(
          () => controller.editandoSenha.value
              ? _FormularioSenha(controller: controller)
              : InkWell(
                  onTap: controller.abrirSenha,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: Tema.azulPrimario),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TituloSecao('Alterar senha',
                                  icone: Icons.lock_outline_rounded),
                              SizedBox(height: 4),
                              Text(
                                'Troque sua senha de acesso a qualquer momento.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
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
        ),
      ),
    );
  }
}

class _FormularioSenha extends StatefulWidget {
  const _FormularioSenha({required this.controller});

  final PerfilController controller;

  @override
  State<_FormularioSenha> createState() => _FormularioSenhaState();
}

class _FormularioSenhaState extends State<_FormularioSenha> {
  final _formKey = GlobalKey<FormState>();

  PerfilController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSecao('Alterar senha', icone: Icons.lock_outline_rounded),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Nova senha',
            dica: 'Mínimo de 6 caracteres',
            icone: Icons.lock_outline_rounded,
            controlador: controller.novaSenhaCtrl,
            senha: true,
            obscureText: controller.senhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenha,
            validator: controller.validarNovaSenha,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Confirmar nova senha',
            icone: Icons.lock_reset_rounded,
            controlador: controller.confirmarSenhaCtrl,
            senha: true,
            obscureText: controller.senhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenha,
            validator: controller.validarConfirmacaoSenha,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 14),
          Obx(() {
            final erro = controller.erro.value;
            if (erro.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MensagemErro.erro(erro),
            );
          }),
          Obx(
            () => BotaoPrimario(
              texto: 'Alterar senha',
              icone: Icons.password_rounded,
              carregando: controller.salvando.value,
              aoTocar: () => controller.alterarSenha(_formKey.currentState!),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                controller.salvando.value ? null : controller.fecharSenha,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
