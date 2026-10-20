/// Resultado de uma verificação de conexão com a API.
///
/// É o que o botão **"Verificar conexão"** do login mostra: em vez de
/// um "não foi possível conectar" genérico, o usuário descobre ** qual
/// endereço ** o app está usando, se a API respondeu e quanto tempo
/// levou.
///
/// Isso resolve o problema mais comum de desenvolvimento com este
/// projeto: cada pessoa precisa do `api.exe` rodando **na própria
/// máquina**, e o endereço muda conforme o dispositivo (emulador
/// Android, iOS, web ou celular físico).
class ResultadoDiagnostico {
  const ResultadoDiagnostico({
    required this.endereco,
    required this.conseguiuConectar,
    this.detalhe = '',
    this.duracao,
  });

  /// Endereço base que o app está usando, por exemplo
  /// `http://10.0.2.2:8081/api`.
  final String endereco;

  /// `true` quando a API respondeu.
  final bool conseguiuConectar;

  /// Explicação do erro (ou observação), quando houve.
  final String detalhe;

  /// Quanto tempo a chamada levou.
  final Duration? duracao;

  /// Mensagem pronta para exibição.
  String get mensagem => conseguiuConectar
      ? 'API respondendo em ${duracao?.inMilliseconds ?? 0} ms.'
      : (detalhe.isEmpty ? 'A API não respondeu.' : detalhe);

  /// Sugestão de ação, mostrada quando a conexão falhou.
  ///
  /// Ela muda conforme o endereço: no emulador Android é `10.0.2.2`, no
  /// celular físico é o IP da máquina na rede — e cada caso tem uma
  /// correção diferente.
  String get sugestao {
    if (conseguiuConectar) return '';

    if (endereco.contains('10.0.2.2')) {
      return 'No emulador Android o endereço 10.0.2.2 é o correto. '
          'Verifique se o api.exe está rodando na sua máquina.';
    }
    if (endereco.contains('localhost') || endereco.contains('127.0.0.1')) {
      return 'No emulador, localhost é o próprio aparelho. '
          'Rode o api.exe na sua máquina e, se estiver no Android, use '
          '--dart-define=API_BASE_URL=http://10.0.2.2:8081/api';
    }
    return 'Confira se o api.exe está rodando na máquina que serve a API '
        'e se o endereço está correto (--dart-define=API_BASE_URL=...).';
  }
}
