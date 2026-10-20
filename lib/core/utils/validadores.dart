import 'package:flutter/services.dart';

/// Validadores de formulário reutilizáveis.
///
/// Cada método devolve `null` quando o valor é válido, ou a mensagem de
/// erro a ser exibida abaixo do campo. Esse é o contrato esperado pelo
/// `TextFormField.validator` do Flutter.
///
/// Os `formatadores*` existem pelo mesmo motivo (RNF04): a máscara
/// progressiva de telefone e CPF é a mesma em todos os formulários —
/// cadastro do Coordenador, cadastro do Professor e Perfil — e viver
/// aqui evita três cópias da mesma `TextInputFormatter`.
class Validadores {
  Validadores._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _apenasNumeros = RegExp(r'\D');

  /// Remove tudo que não for dígito (usado para validar CPF/telefone).
  static String somenteNumeros(String valor) =>
      valor.replaceAll(_apenasNumeros, '');

  static String? obrigatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe $campo.';
    }
    return null;
  }

  static String? email(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Informe o e-mail.';
    if (!_email.hasMatch(v)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? senha(String? valor, {int minimo = 6}) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Informe a senha.';
    if (v.length < minimo) {
      return 'A senha deve ter ao menos $minimo caracteres.';
    }
    return null;
  }

  static String? confirmaSenha(String? senha, String? confirmacao) {
    if (confirmacao == null || confirmacao.isEmpty) {
      return 'Confirme a senha.';
    }
    if (senha != confirmacao) return 'As senhas não conferem.';
    return null;
  }

  /// Formato do CPF: **11 dígitos**, e nada mais.
  ///
  /// A decisão é do domínio: o CPF aqui é **dado de identificação**,
  /// não dado fiscal. O backend não confere o dígito verificador (testado:
  /// ele grava `123.456.789-45` sem reclamar) e a escola precisa
  /// cadastrar também pessoas cujo registro não foi emitido — professor
  /// convidado, servidor terceirizado, docente de outra instituição.
  ///
  /// Barrar o cadastro por causa de dígito verificador criaria atrito
  /// sem nenhuma proteção real: quem digita o CPF errado não consegue
  /// acessar o patrimônio de outra pessoa — o que protege é o token.
  ///
  /// A máscara (`111.222.333-44`) continua sendo aplicada no campo.
  static String? cpf(String? valor) {
    final v = somenteNumeros(valor ?? '');
    if (v.isEmpty) return null; // CPF é opcional no cadastro.
    if (v.length != 11) return 'CPF deve ter 11 dígitos.';
    return null;
  }

  /// Formato do telefone: de 8 a 15 dígitos.
  ///
  /// Cobre telefone fixo (10–11), celular (11) e o formato
  /// internacional E.164 (até 15). Como o CPF, o telefone é só dado de
  /// contato: o app não consulta nenhuma base para saber se o número
  /// existe.
  static String? telefone(String? valor) {
    final v = somenteNumeros(valor ?? '');
    if (v.isEmpty) return null; // Telefone é opcional.
    if (v.length < 8 || v.length > 15) {
      return 'Telefone deve ter de 8 a 15 dígitos.';
    }
    return null;
  }

  /// Máscara progressiva de telefone: (11) 98888-7777
  ///
  /// Aceita até 15 dígitos (o formato internacional E.164). O texto é
  /// **sempre preservado**: nenhum dígito é cortado ao aplicar a
  /// máscara.
  static String mascaraTelefone(String valor) {
    final d = somenteNumeros(valor);
    if (d.length <= 2) return d.isEmpty ? '' : '($d';
    if (d.length <= 6) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    if (d.length <= 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    // Acima de 11 dígitos (E.164): o que sobra vai para o fim, em vez
    // de ser descartado.
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-'
        '${d.substring(7, 11)} ${d.substring(11)}';
  }

  /// Máscara progressiva de CPF: 111.222.333-44
  static String mascaraCpf(String valor) {
    final d = somenteNumeros(valor);
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) {
      return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    }
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.'
        '${d.substring(6, 9)}-${d.substring(9)}';
  }

  /// Formatadores para o `CampoTexto` de telefone.
  ///
  /// Primeiro restringe o que pode ser digitado e depois aplica a máscara
  /// a cada tecla. O limite de 21 caracteres cobre os 15 dígitos do
  /// formato internacional já com a máscara aplicada — e impede que a
  /// máscara estoure e apague o texto.
  static List<TextInputFormatter> formatadoresTelefone() => [
        FilteringTextInputFormatter.allow(RegExp(r'[\d()\-\s]')),
        TextInputFormatter.withFunction((old, novo) {
          final texto = novo.text.length > 21 ? old.text : novo.text;
          final mascarado = mascaraTelefone(texto);
          return TextEditingValue(
            text: mascarado,
            selection: TextSelection.collapsed(offset: mascarado.length),
          );
        }),
      ];

  /// Formatadores para o `CampoTexto` de CPF (14 caracteres com máscara).
  static List<TextInputFormatter> formatadoresCpf() => [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((old, novo) {
          final texto = novo.text.length > 14 ? old.text : novo.text;
          final mascarado = mascaraCpf(texto);
          return TextEditingValue(
            text: mascarado,
            selection: TextSelection.collapsed(offset: mascarado.length),
          );
        }),
      ];
}
