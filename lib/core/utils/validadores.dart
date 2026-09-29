/// Validadores de formulário reutilizáveis.
///
/// Cada método devolve `null` quando o valor é válido, ou a mensagem de
/// erro a ser exibida abaixo do campo. Esse é o contrato esperado pelo
/// `TextFormField.validator` do Flutter.
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

  static String? cpf(String? valor) {
    final v = somenteNumeros(valor ?? '');
    if (v.isEmpty) return null; // CPF é opcional no cadastro.
    if (v.length != 11) return 'CPF deve ter 11 dígitos.';
    if (_cpfInvalido(v)) return 'CPF inválido.';
    return null;
  }

  static String? telefone(String? valor) {
    final v = somenteNumeros(valor ?? '');
    if (v.isEmpty) return null; // Telefone é opcional.
    if (v.length < 10 || v.length > 11) return 'Telefone inválido.';
    return null;
  }

  /// Validação de CPF pelos dois dígitos verificadores.
  static bool _cpfInvalido(String cpf) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return true; // 000..., 111...

    for (var tamanho = 9; tamanho < 11; tamanho++) {
      var soma = 0;
      for (var i = 0; i < tamanho; i++) {
        soma += int.parse(cpf[i]) * (tamanho + 1 - i);
      }
      var digito = (soma * 10) % 11;
      digito = digito == 10 ? 0 : digito;
      if (digito != int.parse(cpf[tamanho])) return true;
    }
    return false;
  }

  /// Máscara progressiva de telefone: (11) 98888-7777
  static String mascaraTelefone(String valor) {
    final d = somenteNumeros(valor);
    if (d.length <= 2) return d.isEmpty ? '' : '($d';
    if (d.length <= 6) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7, 11)}';
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
}
