import 'status_patrimonio.dart';

/// Um registro da linha do tempo de um bem (`HistoricoItem`).
///
/// O histórico é gravado pelo backend em cada atribuição e devolução
/// (RF07b). O app é estritamente leitor deste dado: não existe método
/// para criar ou editar um registro, e o Professor nem chega a ver esta
/// tela (RN03).
///
/// ```json
/// {
///   "id": 1,
///   "patrimonioId": 1,
///   "professorId": 2,
///   "professorNome": "Prof. Carlos Drummond",
///   "adminId": 1,
///   "adminNome": "Coordenador Geral (Admin)",
///   "acao": "atribuicao",
///   "motivo": "Atribuição inicial de patrimônio ao docente responsável",
///   "dataRegistro": "2026-09-14T20:00:00Z"
/// }
/// ```
class HistoricoModel {
  const HistoricoModel({
    required this.id,
    required this.patrimonioId,
    this.professorId,
    this.professorNome,
    this.adminId,
    this.adminNome,
    this.acao = AcaoHistorico.outro,
    this.motivo = '',
    this.dataRegistro,
  });

  final int id;
  final int patrimonioId;

  /// Docente envolvido no movimento. Preenchido em atribuições e
  /// devoluções; em edições e manutenções pode ser `null`.
  final int? professorId;
  final String? professorNome;

  /// Coordenador que registrou o movimento.
  final int? adminId;
  final String? adminNome;

  final AcaoHistorico acao;

  /// Texto livre preenchido na devolução (RF07b — "motivo obrigatório").
  final String motivo;

  final DateTime? dataRegistro;

  /// `Atribuição a docente`, `Devolução do bem`, ...
  String get rotuloAcao => acao.rotulo;

  /// Quem executou o movimento, já legível.
  String get responsavel => (adminNome?.trim().isNotEmpty ?? false)
      ? adminNome!.trim()
      : (professorNome?.trim().isNotEmpty ?? false
          ? professorNome!.trim()
          : 'Sistema');

  /// `true` quando o registro é uma entrega de bem a um docente.
  bool get ehAtribuicao => acao == AcaoHistorico.atribuicao;

  /// `true` quando o registro é a devolução do bem.
  bool get ehDesatribuicao => acao == AcaoHistorico.desatribuicao;

  factory HistoricoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoModel(
      id: _int(json['id']) ?? 0,
      patrimonioId: _int(json['patrimonioId']) ?? 0,
      professorId: _int(json['professorId']),
      professorNome: _textoOpcional(json['professorNome']),
      adminId: _int(json['adminId']),
      adminNome: _textoOpcional(json['adminNome']),
      acao: AcaoHistorico.fromValor(json['acao']),
      motivo: _texto(json['motivo']),
      dataRegistro: _data(json['dataRegistro']),
    );
  }

  static String _texto(dynamic valor) {
    if (valor == null) return '';
    final texto = valor.toString().trim();
    return texto.isEmpty ? '' : texto;
  }

  static String? _textoOpcional(dynamic valor) {
    final texto = _texto(valor);
    return texto.isEmpty ? null : texto;
  }

  static int? _int(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  static DateTime? _data(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}

/// Resposta de `GET /admin/patrimonios/{id}/historico`.
///
/// A API já entrega o histórico do mais recente para o mais antigo, e o
/// campo `total` evita que a View precise contar os itens.
class HistoricoPatrimonioModel {
  const HistoricoPatrimonioModel({
    required this.patrimonioId,
    required this.itens,
    this.total = 0,
  });

  final int patrimonioId;
  final List<HistoricoModel> itens;
  final int total;

  /// `true` quando o bem nunca entrou em nenhum movimento.
  bool get vazio => itens.isEmpty;

  factory HistoricoPatrimonioModel.fromJson(Map<String, dynamic> json) {
    final lista = json['historico'];
    final itens = <HistoricoModel>[];
    if (lista is List) {
      for (final item in lista) {
        if (item is Map) {
          itens.add(HistoricoModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final total = _int(json['total']) ?? itens.length;
    return HistoricoPatrimonioModel(
      patrimonioId: _int(json['patrimonioId']) ?? 0,
      itens: itens,
      total: total,
    );
  }

  static int? _int(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }
}
