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
    this.obscureText, // RxBool externo (ex.: controller.senhaOculta)
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
  final bool senha;
  final VoidCallback? aoAlternarVisibilidade;
  final RxBool? obscureText; // Estado externo reativo (GetX)
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
  late bool _oculto = widget.senha;

  bool get _obscureText {
    if (widget.obscureText != null) return widget.obscureText!.value;
    return _oculto;
  }

  void _alternar() {
    if (widget.obscureText != null) {
      widget.obscureText!.toggle();
    } else {
      setState(() => _oculto = !_oculto);
    }
    widget.aoAlternarVisibilidade?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Lê o valor atual (reativo ou interno) sem usar Obx — evita rebuild
    // desnecessário que quebra pumpAndSettle nos testes.
    final obscure = _obscureText;

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
