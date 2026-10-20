import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';

/// Tela de Login (RF01).
///
/// A View é "burra" de propósito: não valida, não chama a API e não
/// conhece o Dio. Ela apenas reflete o estado do [AuthController] e
/// detém a FormKey do seu próprio formulário.
class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Tema.azulPrimario, Tema.azulEscuro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const _Cabecalho(),
                    const SizedBox(height: 28),
                    _FormularioLogin(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.school_rounded,
              size: 46, color: Tema.azulPrimario),
        ),
        const SizedBox(height: 20),
        const Text(
          'Patrimônio Escolar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Acesse com suas credenciais institucionais',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FormularioLogin extends StatefulWidget {
  const _FormularioLogin({required this.controller});

  final AuthController controller;

  @override
  State<_FormularioLogin> createState() => _FormularioLoginState();
}

class _FormularioLoginState extends State<_FormularioLogin> {
  /// A FormKey mora na View: só ela sabe quando o `Form` sai da árvore.
  final _formKey = GlobalKey<FormState>();

  AuthController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoTexto(
              rotulo: 'E-mail',
              dica: 'seu.email@escola.com',
              icone: Icons.mail_outline_rounded,
              controlador: controller.emailCtrl,
              teclado: TextInputType.emailAddress,
              validator: controller.validarEmailLogin,
              desabilitado: controller.carregando.value,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              rotulo: 'Senha',
              dica: '••••••••',
              icone: Icons.lock_outline_rounded,
              controlador: controller.senhaCtrl,
              senha: true,
              obscureText: controller.senhaOculta,
              aoAlternarVisibilidade: controller.alternarVisibilidadeSenhaLogin,
              validator: controller.validarSenhaLogin,
              desabilitado: controller.carregando.value,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.carregando.value
                    ? null
                    : () => Get.toNamed(Rotas.recuperarSenha),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            // A faixa de erro só aparece quando há mensagem (RNF02).
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
                texto: 'Entrar',
                icone: Icons.login_rounded,
                carregando: controller.carregando.value,
                aoTocar: () =>
                    controller.login(_formKey.currentState!),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE8EDF6)),
            const SizedBox(height: 12),
            Text(
              'Ainda não possui conta?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            // RN01: o único cadastro disponível é o de Coordenador.
            TextButton(
              onPressed: controller.carregando.value
                  ? null
                  : () => Get.toNamed(Rotas.cadastroAdmin),
              child: const Text(
                'Cadastrar Coordenador',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
