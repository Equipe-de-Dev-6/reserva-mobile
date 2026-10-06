import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/tema.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/botao_primario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/mensagem_erro.dart';

/// Recuperação de senha em 3 etapas (RF03).
///
/// Etapa 0 → e-mail  ·  Etapa 1 → código de 6 dígitos  ·  Etapa 2 → nova senha
///
/// O [AnimatedSwitcher] entre as etapas entrega a transição suave
/// pedida no RNF01 sem exigir um pacote extra de animação.
class RecuperarSenhaView extends GetView<AuthController> {
  const RecuperarSenhaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Obx(
                    () => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (filho, animacao) {
                        return FadeTransition(
                          opacity: animacao,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(animacao),
                            child: filho,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(controller.etapaRecuperacao.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _IndicadorEtapas(
                                etapa: controller.etapaRecuperacao.value),
                            const SizedBox(height: 24),
                            _Mensagens(controller: controller),
                            const SizedBox(height: 20),
                            _CorpoEtapa(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso visual das 3 etapas.
class _IndicadorEtapas extends StatelessWidget {
  const _IndicadorEtapas({required this.etapa});

  final int etapa;

  static const _rotulos = ['E-mail', 'Código', 'Nova senha'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_rotulos.length, (i) {
        final concluida = i <= etapa;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _rotulos.length - 1 ? 0 : 8),
            child: Column(
              children: [
                // O círculo muda de cor conforme o avanço.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: concluida
                        ? Tema.vermelhoPrimario
                        : Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: concluida
                          ? Tema.vermelhoPrimario
                          : const Color(0xFFDDE3EE),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: concluida && i < etapa
                        ? const Icon(Icons.check,
                            size: 17, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: concluida
                                  ? Colors.white
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rotulos[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        i == etapa ? FontWeight.w700 : FontWeight.w400,
                    color:
                        Colors.black.withValues(alpha: i == etapa ? 0.85 : 0.45),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Mensagens extends StatelessWidget {
  const _Mensagens({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final erro = controller.erro.value;
    final aviso = controller.aviso.value;

    if (erro.isNotEmpty) {
      return MensagemErro.mensagem(erro, tipo: TipoMensagem.erro);
    }
    if (aviso.isNotEmpty) {
      return MensagemErro.mensagem(aviso, tipo: TipoMensagem.sucesso);
    }
    return Text(
      _descricao(controller.etapaRecuperacao.value),
      style: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  String _descricao(int etapa) => switch (etapa) {
        0 => 'Informe o e-mail cadastrado. Enviaremos um código de '
            'validação de 6 dígitos.',
        1 => 'Digite o código de 6 dígitos enviado para o e-mail informado.',
        _ => 'Crie uma nova senha com no mínimo 6 caracteres.',
      };
}

class _CorpoEtapa extends StatelessWidget {
  const _CorpoEtapa({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.etapaRecuperacao.value) {
      0 => _EtapaEmail(controller: controller),
      1 => _EtapaCodigo(controller: controller),
      _ => _EtapaNovaSenha(controller: controller),
    };
  }
}

/// Base das três etapas: cada uma é um `StatefulWidget` porque precisa
/// da sua própria FormKey. Compartilhar uma única key entre as etapas
/// quebraria o App ao manter dois formulários montados durante a
/// animação de troca.
abstract class _EtapaBase extends StatefulWidget {
  const _EtapaBase({required this.controller});

  final AuthController controller;

  /// Conteúdo específico da etapa (campos).
  Widget conteudo();

  /// Botão secundário, opcional.
  Widget? rodape() => null;

  @override
  State<_EtapaBase> createState() => _EtapaBaseState();
}
class _EtapaBaseState extends State<_EtapaBase> {
  final _formKey = GlobalKey<FormState>();

  AuthController get controller => widget.controller;

  void _enviar() {
    final estado = _formKey.currentState;
    if (estado == null) return;

    switch (controller.etapaRecuperacao.value) {
      case 0:
        controller.solicitarCodigo(estado);
      case 1:
        controller.verificarCodigo(estado);
      default:
        controller.redefinirSenha(estado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acaoSecundaria = widget.rodape();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.conteudo(),
          const SizedBox(height: 20),
          _botao(),
          if (acaoSecundaria != null) ...[
            const SizedBox(height: 8),
            acaoSecundaria,
          ],
        ],
      ),
    );
  }

  /// Botão principal, com o texto de cada etapa.
  Widget _botao() => BotaoPrimario(
        texto: switch (controller.etapaRecuperacao.value) {
          0 => 'Enviar código',
          1 => 'Validar código',
          _ => 'Redefinir senha',
        },
        icone: switch (controller.etapaRecuperacao.value) {
          0 => Icons.send_rounded,
          1 => Icons.verified_outlined,
          _ => Icons.password_rounded,
        },
        carregando: controller.carregando.value,
        aoTocar: _enviar,
      );
}

class _EtapaEmail extends _EtapaBase {
  const _EtapaEmail({required super.controller});

  @override
  Widget conteudo() => CampoTexto(
        rotulo: 'E-mail cadastrado',
        dica: 'seu.email@escola.com',
        icone: Icons.mail_outline_rounded,
        controlador: controller.recuperacaoEmailCtrl,
        teclado: TextInputType.emailAddress,
        validator: controller.validarEmailLogin,
        desabilitado: controller.carregando.value,
      );

  @override
  Widget? rodape() => TextButton(
        onPressed: controller.carregando.value ? null : () => Get.back(),
        child: const Text('Voltar para o login'),
      );
}

class _EtapaCodigo extends _EtapaBase {
  const _EtapaCodigo({required super.controller});

  @override
  Widget conteudo() => CampoTexto(
        rotulo: 'Código de validação',
        dica: '000000',
        icone: Icons.confirmation_number_outlined,
        controlador: controller.codigoCtrl,
        teclado: TextInputType.number,
        maxLength: 6,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        validator: controller.validarCodigo,
        desabilitado: controller.carregando.value,
      );

  @override
  Widget? rodape() => TextButton(
        onPressed: controller.carregando.value ? null : controller.etapaAnterior,
        child: const Text('Reenviar / alterar e-mail'),
      );
}

class _EtapaNovaSenha extends _EtapaBase {
  const _EtapaNovaSenha({required super.controller});

  @override
  Widget conteudo() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoTexto(
            rotulo: 'Nova senha',
            dica: 'Mínimo de 6 caracteres',
            icone: Icons.lock_outline_rounded,
            controlador: controller.novaSenhaCtrl,
            senha: true,
            obscureText: controller.novaSenhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeNovaSenha,
            validator: controller.validarNovaSenha,
            desabilitado: controller.carregando.value,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            rotulo: 'Confirmar nova senha',
            icone: Icons.lock_reset_rounded,
            controlador: controller.novaSenhaConfirmarCtrl,
            senha: true,
            obscureText: controller.novaSenhaOculta,
            aoAlternarVisibilidade: controller.alternarVisibilidadeNovaSenha,
            validator: controller.validarConfirmacaoNovaSenha,
            desabilitado: controller.carregando.value,
          ),
        ],
      );

  @override
  Widget? rodape() => TextButton(
        onPressed: controller.carregando.value ? null : controller.etapaAnterior,
        child: const Text('Voltar'),
      );
}
