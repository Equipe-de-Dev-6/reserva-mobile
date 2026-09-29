import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.teclado,
    this.formatters,
    this.maxLength,
    this.desabilitado = false,
    this.validator,
  });

  final String rotulo;
  final String? dica;
  final IconData? icone;
  final TextEditingController? controlador;
  final bool senha;
  final VoidCallback? aoAlternarVisibilidade;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool desabilitado;

  /// Função de validação fornecida pelo Controller da tela.
  /// Devolve `null` quando o valor é válido, ou a mensagem de erro.
  final String? Function(String?)? validator;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late bool _oculto = widget.senha;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      obscureText: _oculto,
      enabled: !widget.desabilitado,
      keyboardType: widget.teclado,
      inputFormatters: widget.formatters,
      maxLength: widget.maxLength,
      validator: widget.validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: widget.dica,
        counterText: '',
        prefixIcon: widget.icone == null ? null : Icon(widget.icone, size: 20),
        suffixIcon: widget.senha
            ? IconButton(
                onPressed: widget.aoAlternarVisibilidade ??
                    () => setState(() => _oculto = !_oculto),
                icon: Icon(
                  _oculto ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
              )
            : null,
      ),
    );
  }
}
