import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Input padronizado do aplicativo (RNF04).
///
/// Evita repetir `InputDecoration` em todas as telas. Entre os recursos
/// já embutidos estão o botão de mostrar/ocultar senha, o teclado
/// correto conforme o tipo de dado e a máscara de telefone/CPF.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.rotulo,
    this.dica,
    this.icone,
    this.controlador,
    this.senha = false,
    this.aoAlternarVisibilidade,
    this.obscureText,
    this.teclado,
    this.formatters,
    this.maxLength,
    this.desabilitado = false,
    this.aoAlterar,
    this.validator,
  });

  final String rotulo;
  final String? dica;
  final IconData? icone;
  final TextEditingController? controlador;

  /// Marca o campo como sendo de senha: habilita o botão de
  /// mostrar/ocultar.
  final bool senha;

  /// Controle **externo** da visibilidade — normalmente um `RxBool` do
  /// Controller (`controller.senhaOculta`).
  ///
  /// Quando é informado, ele é a **única** fonte de verdade: o botão
  /// alterna este valor e a tela se redesenha sozinha.
  ///
  /// ⚠️ **Não combine com [aoAlternarVisibilidade].** Os dois
  /// alternando o mesmo valor fariam o toggle acontecer **duas vezes** —
  /// e a senha nunca apareceria. Foi exatamente assim que o botão
  /// "mostrar senha" ficou sem efeito em todas as telas.
  final RxBool? obscureText;

  /// Callback disparado quando a visibilidade muda no modo **interno**
  /// (quando [obscureText] não é informado).
  ///
  /// No modo externo ele **não** é chamado: o próprio `RxBool` já é a
  /// fonte de verdade.
  final VoidCallback? aoAlternarVisibilidade;

  final TextInputType? teclado;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool desabilitado;

  /// Disparado a cada tecla digitada. Usado pelos campos de busca,
  /// onde não existe `TextEditingController`: o Controller da tela
  /// filtra a lista a partir daqui.
  final ValueChanged<String>? aoAlterar;

  /// Função de validação fornecida pelo Controller da tela.
  /// Devolve `null` quando o valor é válido, ou a mensagem de erro.
  final String? Function(String?)? validator;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  /// Visibilidade no modo **interno** (sem [CampoTexto.obscureText]).
  late bool _oculto = widget.senha;

  void _alternar() {
    if (widget.obscureText != null) {
      // Uma única alternância: o `RxBool` é a fonte de verdade.
      // Chamar também o callback aqui inverteria duas vezes, e a
      // senha voltaria a ficar oculta.
      widget.obscureText!.toggle();
      return;
    }

    setState(() => _oculto = !_oculto);
    widget.aoAlternarVisibilidade?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Controle externo: é preciso **observar** o `RxBool`. Sem o
    // `Obx`, o `toggle()` mudava o valor mas a tela não se redesunha —
    // e o botão "mostrar senha" parecia não fazer nada.
    if (widget.obscureText != null) {
      return Obx(() => _campo(context, widget.obscureText!.value));
    }

    return _campo(context, _oculto);
  }

  Widget _campo(BuildContext context, bool obscure) {
    return TextFormField(
      controller: widget.controlador,
      obscureText: obscure,
      enabled: !widget.desabilitado,
      keyboardType: widget.teclado,
      inputFormatters: widget.formatters,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onChanged: widget.aoAlterar,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: widget.dica,
        counterText: '',
        prefixIcon: widget.icone == null ? null : Icon(widget.icone, size: 20),
        suffixIcon: widget.senha
            ? IconButton(
                onPressed: _alternar,
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
              )
            : null,
      ),
    );
  }
}
