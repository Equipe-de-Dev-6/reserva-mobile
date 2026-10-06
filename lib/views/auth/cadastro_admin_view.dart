import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/validadores.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';

/// Cadastro do Coordenador (RF02 / RN01).
///
/// Não existe cadastro público de professor: o docente é criado
/// exclusivamente pelo admin dentro do app (Módulo 2).
class CadastroAdminView extends GetView<AuthController> {
  const CadastroAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Coordenador')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: _Formulario(controller: controller),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deixa explícita a RN01 já na primeira dobra da tela.
class _AvisoRegra extends StatelessWidget {
  const _AvisoRegra();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tema.vermelhoPrimario.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Tema.vermelhoPrimario.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings_outlined,
              size: 20, color: Tema.vermelhoPrimario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este formulário cria exclusivamente o perfil do '
              'Coordenador (admin). Professores são cadastrados pelo '
              'Coordenador após o primeiro acesso.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.controller});

  final AuthController controller;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  /// A FormKey mora na View: só ela sabe quando o `Form` sai da árvore.
  final _formKey = GlobalKey<FormState>();

  AuthController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AvisoRegra(),
          const SizedBox(height: 20),
          CampoTexto(
            rotulo: 'Nome completo',
            dica: 'Prof. Coordenador Geral',
            icone: Icons.person_outline_rounded,
            controlador: controller.nomeCtrl,
            teclado: TextInputType.name,
            validator: controller.validarNome,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'E-mail',
            dica: 'coordenador@escola.com',
            icone: Icons.mail_outline_rounded,
            controlador: controller.cadastroEmailCtrl,
            teclado: TextInputType.emailAddress,
            validator: controller.validarEmailCadastro,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Senha',
            dica: 'Mínimo de 6 caracteres',
            icone: Icons.lock_outline_rounded,
            controlador: controller.cadastroSenhaCtrl,
            senha: true,
            validator: controller.validarSenhaCadastro,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenhaCadastro,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Confirmar senha',
            icone: Icons.lock_reset_rounded,
            controlador: controller.confirmarSenhaCtrl,
            senha: true,
            validator: controller.validarConfirmacao,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenhaCadastro,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 24),
          const _Subtitulo('Dados institucionais (opcionais)'),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Departamento',
            dica: 'Coordenação Pedagógica',
            icone: Icons.apartment_rounded,
            controlador: controller.departamentoCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Telefone',
            dica: '(11) 98888-7777',
            icone: Icons.phone_outlined,
            controlador: controller.telefoneCtrl,
            teclado: TextInputType.phone,
            validator: controller.validarTelefone,
            // Máscara progressiva compartilhada (RNF04): a mesma regra
            // vale para o telefone do Coordenador, do Professor e do
            // Perfil.
            formatters: Validadores.formatadoresTelefone(),
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'CPF',
            dica: '111.222.333-44',
            icone: Icons.badge_outlined,
            controlador: controller.cpfCtrl,
            teclado: TextInputType.number,
            validator: controller.validarCpf,
            formatters: Validadores.formatadoresCpf(),
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 24),
          Obx(() {
            final mensagem = controller.erro.value;
            if (mensagem.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MensagemErro.erro(mensagem),
            );
          }),
          Obx(
            () => BotaoPrimario(
              texto: 'Criar conta de Coordenador',
              icone: Icons.how_to_reg_rounded,
              carregando: controller.carregando.value,
              aoTocar: () =>
                  controller.cadastrarCoordenador(_formKey.currentState!),
            ),
          ),
        ],
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }
}
