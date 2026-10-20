import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/tema.dart';
import '../../../controllers/professor_cadastro_controller.dart';
import '../../../core/utils/validadores.dart';
import '../../../widgets/botao_primario.dart';
import '../../../widgets/campo_texto.dart';
import '../../../widgets/linha_dado.dart';
import '../../../widgets/mensagem_erro.dart';

/// Cadastro de professor (RF06.2 / RN02).
///
/// O formulário deixa explícita a RN02 na primeira dobra: não existe
/// cadastro público de docente — quem cria o professor é o Coordenador
/// autenticado, e é ele quem define a **senha provisória** que o docente
/// vai usar no primeiro acesso.
class ProfessorCadastroView extends GetView<ProfessorCadastroController> {
  const ProfessorCadastroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Professor')),
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

class _Formulario extends StatefulWidget {
  const _Formulario({required this.controller});

  final ProfessorCadastroController controller;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  /// A FormKey mora na View: só ela sabe quando o `Form` sai da árvore.
  final _formKey = GlobalKey<FormState>();

  ProfessorCadastroController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AvisoRegra(),
          const SizedBox(height: 22),
          const TituloSecao('Dados de acesso', icone: Icons.badge_outlined),
          const SizedBox(height: 14),
          CampoTexto(
            rotulo: 'Nome completo',
            dica: 'Prof. Fernando Pessoa',
            icone: Icons.person_outline_rounded,
            controlador: controller.nomeCtrl,
            teclado: TextInputType.name,
            validator: controller.validarNome,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'E-mail institucional',
            dica: 'fernando.pessoa@escola.com',
            icone: Icons.mail_outline_rounded,
            controlador: controller.emailCtrl,
            teclado: TextInputType.emailAddress,
            validator: controller.validarEmail,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Senha provisória',
            dica: 'Mínimo de 6 caracteres',
            icone: Icons.lock_outline_rounded,
            controlador: controller.senhaCtrl,
            senha: true,
            obscureText: controller.senhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenha,
            validator: controller.validarSenha,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Confirmar senha provisória',
            icone: Icons.lock_reset_rounded,
            controlador: controller.confirmarSenhaCtrl,
            senha: true,
            obscureText: controller.senhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeSenha,
            validator: controller.validarConfirmacao,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 26),
          const TituloSecao('Dados institucionais', icone: Icons.apartment_rounded),
          const SizedBox(height: 14),
          CampoTexto(
            rotulo: 'Matrícula',
            dica: 'PROF-2024-03',
            icone: Icons.numbers_rounded,
            controlador: controller.matriculaCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Departamento',
            dica: 'História e Filosofia',
            icone: Icons.account_balance_outlined,
            controlador: controller.departamentoCtrl,
            teclado: TextInputType.text,
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Telefone',
            dica: '(11) 98765-1003',
            icone: Icons.phone_outlined,
            controlador: controller.telefoneCtrl,
            teclado: TextInputType.phone,
            validator: controller.validarTelefone,
            // Máscara compartilhada: a mesma regra nos três formulários.
            formatters: Validadores.formatadoresTelefone(),
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'CPF',
            dica: '234.567.890-11',
            icone: Icons.badge_outlined,
            controlador: controller.cpfCtrl,
            teclado: TextInputType.number,
            validator: controller.validarCpf,
            formatters: Validadores.formatadoresCpf(),
            desabilitado: controller.salvando.value,
          ),
          const SizedBox(height: 22),
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
              texto: 'Cadastrar professor',
              icone: Icons.how_to_reg_rounded,
              carregando: controller.salvando.value,
              aoTocar: () => controller.cadastrar(_formKey.currentState!),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deixa explícita a RN02 já na primeira dobra da tela.
class _AvisoRegra extends StatelessWidget {
  const _AvisoRegra();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tema.azulPrimario.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Tema.azulPrimario.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: Tema.azulPrimario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'O cadastro do docente é feito somente pelo Coordenador '
              '(RN02). Defina aqui a senha provisória de acesso e '
              'informe ao professor.',
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
