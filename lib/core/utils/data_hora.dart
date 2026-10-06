/// Formatação de datas para exibição no app.
///
/// Existe como utilitário único porque três telas precisam do mesmo
/// formato (detalhe do bem, linha do tempo e cards) e o formato
/// brasileiro não deve ficar repetido em string solta dentro das Views.
class DataHora {
  DataHora._();

  /// `06/10/2026` — ou um traço quando a data não existe.
  ///
  /// Vários campos da API são opcionais e chegam como `null` (por
  /// exemplo `dataAtribuicao` de um bem ainda disponível). Formatá-los
  /// como "null" na tela seria pior que omitir a informação.
  static String data(DateTime? valor) {
    if (valor == null) return '—';
    return '${_dois(valor.day)}/${_dois(valor.month)}/${valor.year}';
  }

  /// `06/10/2026 às 14:32`
  static String dataHora(DateTime? valor) {
    if (valor == null) return '—';
    return '${data(valor)} às ${_dois(valor.hour)}:${_dois(valor.minute)}';
  }

  static String _dois(int numero) => numero.toString().padLeft(2, '0');
}
