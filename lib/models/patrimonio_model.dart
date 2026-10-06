import 'status_patrimonio.dart';

/// Um bem do acervo escolar.
///
/// ## Por que este Model foi reescrito
///
/// A versão anterior não batia com a API. Ela tratava `descricao` como
/// o *nome* do bem e não tinha `id` numérico, `localizacao`,
/// `modelo`, `dataAtribuicao` nem `professorNome` — ou seja, o detalhe
/// (`GET /patrimonios/{id}`) não tinha como ser montado. O formato real
/// devolvido pelo backend é:
///
/// ```json
/// {
///   "id": 1,
///   "codigo": "PAT-2024-001",
///   "nome": "Notebook Dell Latitude 3420",
///   "descricao": "Intel Core i5 11ª Ger, 16GB RAM, SSD 512GB",
///   "categoria": "Informática",
///   "marca": "Dell",
///   "modelo": "Latitude 3420",
///   "numeroSerie": "DL-992831",
///   "estadoConservacao": "Excelente",
///   "localizacao": "Gabinete dos Professores - Mesa 04",
///   "status": "em_uso",
///   "professorId": 2,
///   "professorNome": "Prof. Carlos Drummond",
///   "professorEmail": "professor@escola.com",
///   "dataAtribuicao": "2026-09-14T20:00:00Z",
///   "observacoes": "",
///   "createdAt": "2026-09-14T19:00:00Z",
///   "updatedAt": "2026-09-14T19:00:00Z"
/// }
/// ```
///
/// Todo campo opcional é lido por [_texto] e [_data], então um bem sem
/// `numeroSerie`, sem professor ou sem observação ainda vira um objeto
/// válido para desenhar.
class PatrimonioModel {
  const PatrimonioModel({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao = '',
    this.categoria = '',
    this.marca = '',
    this.modelo = '',
    this.numeroSerie,
    this.estadoConservacao = '',
    this.localizacao = '',
    this.status = StatusPatrimonio.indefinido,
    this.adminId,
    this.professorId,
    this.professorNome,
    this.professorEmail,
    this.dataAtribuicao,
    this.observacoes = '',
    this.createdAt,
    this.updatedAt,
  });

  final int id;

  /// Código de tombamento do bem (`PAT-2024-001`).
  ///
  /// É por este campo que a busca da RF07a acontece.
  final String codigo;

  /// Nome do bem, como oigiCadastro do Coating. Ex.: "Notebook Dell Latitude 3420".
  final String nome;

  /// Especificações / observação técnica do bem.
  final String descricao;

  final String categoria;
  final String marca;
  final String modelo;
  final String? numeroSerie;
  final String estadoConservacao;

  /// Onde o bem está fisicamente. Vem em branco quando o Coordinator
  /// ainda não registrou a placa de localização.
  final String localizacao;

  final StatusPatrimonio status;
  final int? adminId;

  /// Professor responsável. `null` enquanto o bem está [StatusPatrimonio.disponivel].
  final int? professorId;
  final String? professorNome;
  final String? professorEmail;
  final DateTime? dataAtribuicao;

  final String observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // --- Atalhos de leitura ------------------------------------------------

  /// Rótulo de domínio para [codigo], usado nos textos da interface
  /// ("Tombamento PAT-2024-001").
  String get tombamento => codigo;

  /// `Disponível`, `Em uso`, ... — o texto do `BadgeStatus`.
  String get rotuloStatus => status.rotulo;

  bool get temProfessor => professorId != null;

  /// `true` quando o bem está vinculado a um docente.
  ///
  /// A RN do projeto é simples: um bem em uso **sempre** tem professor.
  /// Um `em_uso` sem professor indicaria dado inconsistente vindo do
  /// banco, e o app trata como "em uso sem responsável" em vez de
  /// fingir que há alguém vinculado.
  bool get emUsoComResponsavel => status == StatusPatrimonio.emUso && temProfessor;

  /// Série não informada aparece como "Não informado" e não como vazio,
  /// para o card não ficar com um buraco na linha.
  String get numeroSerieFormatado =>
      (numeroSerie?.trim().isNotEmpty ?? false) ? numeroSerie!.trim() : 'Não informado';

  String get professorNomeFormatado =>
      (professorNome?.trim().isNotEmpty ?? false) ? professorNome!.trim() : 'Sem responsável';

  /// `Em uso · Prof. Carlos Drummond`, usado como subtítulo do card.
  String get resumoResponsavel => temProfessor
      ? '${rotuloStatus} · $professorNomeFormatado'
      : rotuloStatus;

  // --- Serialização -----------------------------------------------------

  factory PatrimonioModel.fromJson(Map<String, dynamic> json) {
    return PatrimonioModel(
      id: _int(json['id']) ?? 0,
      codigo: _texto(json['codigo']),
      nome: _texto(json['nome']),
      descricao: _texto(json['descricao']),
      categoria: _texto(json['categoria']),
      marca: _texto(json['marca']),
      modelo: _texto(json['modelo']),
      numeroSerie: _textoOpcional(json['numeroSerie']),
      estadoConservacao: _texto(json['estadoConservacao']),
      localizacao: _texto(json['localizacao']),
      status: StatusPatrimonio.fromValor(json['status']),
      adminId: _int(json['adminId']),
      professorId: _int(json['professorId']),
      professorNome: _textoOpcional(json['professorNome']),
      professorEmail: _textoOpcional(json['professorEmail']),
      dataAtribuicao: _data(json['dataAtribuicao']),
      observacoes: _texto(json['observacoes']),
      createdAt: _data(json['createdAt']),
      updatedAt: _data(json['updatedAt']),
    );
  }

  /// Corpo usado pelo `POST /patrimonios`.
  ///
  /// O `id`, `status` e as datas ficam de fora de propósito: são
  /// definidos pelo servidor. `professorId` também não vai no cadastro —
  /// vincular um bem a um docente é o fluxo de atribuição (RF07b), e
  /// mandar `null` aqui apagaria o vínculo de um bem já atribuído quando
  /// a tela de cadastro fosse reaproveitada.
  Map<String, dynamic> toJson() => {
        'codigo': codigo.trim(),
        'nome': nome.trim(),
        'descricao': descricao.trim(),
        'categoria': categoria.trim(),
        'marca': marca.trim(),
        'modelo': modelo.trim(),
        'numeroSerie': numeroSerie?.trim() ?? '',
        'estadoConservacao': estadoConservacao.trim(),
        'localizacao': localizacao.trim(),
        'observacoes': observacoes.trim(),
      };

  /// Corpo usado pelo `PUT /patrimonios/{id}`.
  ///
  /// Mesmos campos do [toJson] mais o [status], que é a única coisa que
  /// a API permite mudar fora da atribuição. O `codigo` (tombamento)
  /// **não** é editável: identificador de tombamento muda com processo
  /// patrimonial, não por um campo de formulário.
  Map<String, dynamic> toJsonAtualizacao() => {
        ...toJson(),
        'status': status.api,
      };

  /// Cópia com campos trocados — usada para atualizar a lista em memória
  /// depois de um `PUT` sem refazer a requisição de listagem.
  PatrimonioModel copyWith({
    String? nome,
    String? descricao,
    String? categoria,
    String? marca,
    String? modelo,
    String? numeroSerie,
    String? estadoConservacao,
    String? localizacao,
    StatusPatrimonio? status,
    String? observacoes,
  }) {
    return PatrimonioModel(
      id: id,
      codigo: codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      estadoConservacao: estadoConservacao ?? this.estadoConservacao,
      localizacao: localizacao ?? this.localizacao,
      status: status ?? this.status,
      adminId: adminId,
      professorId: professorId,
      professorNome: professorNome,
      professorEmail: professorEmail,
      dataAtribuicao: dataAtribuicao,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // --- Helpers de leitura tolerante -------------------------------------
  // O banco devolve `""` onde não há valor; tratar isso como vazio evita
  // "null" na tela e evita `?? ''` repetido em cada campo.

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
