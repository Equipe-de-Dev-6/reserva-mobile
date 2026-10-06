/// Situação de um bem no acervo.
///
/// Substitui as strings soltas (`'disponivel'`, `'em_uso'`...) que
/// apareciam espalhadas em Models, Services e Views. Com o enum, o
/// valor exato do backend fica declarado **uma única vez**, em [valor],
/// e a leitura passa a ser [StatusPatrimonio.fromValor] — que nunca
/// lança exceção, mesmo se a API inventar um estado novo.
///
/// Fica em `models/` e não importa `material.dart`: um Model não depende
/// de Flutter. O ícone de cada estado é responsabilidade do widget
/// `BadgeStatus`.
enum StatusPatrimonio {
  disponivel(
    api: 'disponivel',
    rotulo: 'Disponível',
    descricao: 'No acervo, sem docente responsável',
  ),
  emUso(
    api: 'em_uso',
    rotulo: 'Em uso',
    descricao: 'Atribuído a um professor',
  ),
  emManutencao(
    api: 'em_manutencao',
    rotulo: 'Em manutenção',
    descricao: 'Em conserto ou aguardando reparo',
  ),
  baixado(
    api: 'baixado',
    rotulo: 'Baixado',
    descricao: 'Retirado do acervo',
  ),

  /// Estado neutro, usado quando a API não devolve `status`.
  ///
  /// Não é um valor da `query`: ele existe só como destino do
  /// [fromValor], para que um campo ausente vire "Indefinido" na tela em
  /// vez de um `null` quebrando o card inteiro.
  indefinido(
    api: '',
    rotulo: 'Indefinido',
    descricao: 'Situação não informada pela API',
  );

  const StatusPatrimonio({
    required this.api,
    required this.rotulo,
    required this.descricao,
  });

  /// Valor traveling na query string e no corpo das requisições.
  final String api;

  /// Texto exibido ao usuário no `BadgeStatus`.
  final String rotulo;

  /// Explicação curta usada na tela de detalhe e nos filtros.
  final String descricao;

  /// Converte o valor do backend em enum.
  ///
  /// Valores desconhecidos ou ausentes viram [indefinido], em vez de
  /// derrubar a listagem inteira.
  static StatusPatrimonio fromValor(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    if (texto.isEmpty) return indefinido;

    for (final status in values) {
      if (status.api == texto) return status;
    }
    return indefinido;
  }

  /// Estados oferecidos como filtro na listagem (RF07a).
  ///
  /// [indefinido] fica de fora de propósito: ele não é um estado
  /// selecionável, é apenas o fallback de leitura.
  static const List<StatusPatrimonio> filtraveis = [
    disponivel,
    emUso,
    emManutencao,
    baixado,
  ];

  /// Só [disponivel] e [emManutencao] aceitam recebimento de bem.
  ///
  /// Usado pelo Controller para explicar por que o formulário de
  /// atribuição está bloqueado (ciclo de vida do bem — RF07b).
  bool get aceitaAtribuicao => this == disponivel || this == emManutencao;
}

/// Ações registradas na linha do tempo de um bem.
///
/// O histórico é gravado pelo backend; o app apenas exibe. O enum
/// traduz o código técnico (`atribuicao`) em rótulo legível, para que a
/// View não precise montar um `switch` com os valores do banco.
enum AcaoHistorico {
  criacao(api: 'criacao', rotulo: 'Cadastro do bem'),
  atribuicao(api: 'atribuicao', rotulo: 'Atribuição a docente'),
  desatribuicao(api: 'desatribuicao', rotulo: 'Devolução do bem'),
  manutencao(api: 'manutencao', rotulo: 'Envio para manutenção'),
  edicao(api: 'edicao', rotulo: 'Edição de cadastro'),
  exclusao(api: 'exclusao', rotulo: 'Baixa do acervo'),
  outro(api: '', rotulo: 'Movimento registrado');

  const AcaoHistorico({required this.api, required this.rotulo});

  final String api;
  final String rotulo;

  static AcaoHistorico fromValor(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    for (final acao in values) {
      if (acao.api.isNotEmpty && acao.api == texto) return acao;
    }
    return outro;
  }
}
