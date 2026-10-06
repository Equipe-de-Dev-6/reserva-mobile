/// Um bem escolar (equipamento) do acervo da instituição.
///
/// O formato segue o schema `Patrimonio` do Swagger. Um mesmo bem aparece
/// em três lugares do app — lista geral (RF07), detalhe do professor
/// (RF06) e "meus patrimônios" (RF08) — e em todos eles a API devolve
/// exatamente este JSON.
///
/// Tolerância: a API usa `null` para campos sem valor e o app prefere
/// string vazia, para que a UI nunca precise checar `null` antes de
/// desenhar. Por isso a leitura é feita por [PatrimonyModel._texto].
class PatrimonyModel {
  final int id;

  /// Código de tombamento, ex.: `PAT-2024-001`.
  final String codigo;

  /// Nome do equipamento, ex.: `Notebook Dell Latitude 3420`.
  final String nome;

  final String descricao;
  final String categoria;
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String estadoConservacao;

  /// Onde o bem está guardado. É o dado que o RF08 pede no card.
  final String localizacao;

  /// `disponivel`, `em_uso` ou `em_manutencao` (o backend também prevê
  /// `baixado`, tratado aqui como desconhecido).
  final String status;

  /// Id do docente responsável. Vem preenchido (como `professorId` ou,
  /// em respostas mais novas, como `responsavelId`) quando o bem está
  /// `em_uso`.
  final int? professorId;

  final String professorNome;
  final String professorEmail;

  /// Momento da atribuição (RN05 / RN04).
  final DateTime? dataAtribuicao;

  final String observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatrimonyModel({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao = '',
    this.categoria = '',
    this.marca = '',
    this.modelo = '',
    this.numeroSerie = '',
    this.estadoConservacao = '',
    this.localizacao = '',
    this.status = 'disponivel',
    this.professorId,
    this.professorNome = '',
    this.professorEmail = '',
    this.dataAtribuicao,
    this.observacoes = '',
    this.createdAt,
    this.updatedAt,
  });

  // --- Regras de status (RN05) -----------------------------------------
  // A UI pergunta `emUso`/`disponivel` em vez de comparar strings soltas,
  // evitando erro de digitação ao montar os badges de status.

  /// `true` quando o bem está sob guarda de um docente (RN04).
  bool get emUso => status == 'em_uso';

  /// `true` quando o bem está no estoque escolar, sem responsável (RN05).
  bool get disponivel => status == 'disponivel';

  bool get emManutencao => status == 'em_manutencao';

  /// Linha secundária do card: marca + modelo, ou a categoria quando a
  /// marca não foi informada.
  String get resumoEquipamento {
    final partes = [marca, modelo]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isNotEmpty) return partes.join(' · ');
    return categoria;
  }

  /// Data de atribuição já formatada para o card (`dd/MM/yyyy`).
  /// Devolve uma string vazia quando o bem nunca foi atribuído.
  String get dataAtribuicaoFormatada {
    final data = dataAtribuicao;
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  factory PatrimonyModel.fromJson(Map<String, dynamic> json) {
    // `professorId` e `responsavelId` são o mesmo vínculo visto por
    // serializações diferentes do backend; os dois são lidos.
    final professorId =
        _paraInt(json['professorId'] ?? json['responsavelId']);

    return PatrimonyModel(
      id: _paraInt(json['id']) ?? 0,
      codigo: _texto(json['codigo'] ?? json['tombamento']),
      nome: _texto(json['nome']),
      descricao: _texto(json['descricao']),
      categoria: _texto(json['categoria']),
      marca: _texto(json['marca']),
      modelo: _texto(json['modelo']),
      numeroSerie: _texto(json['numeroSerie']),
      estadoConservacao: _texto(json['estadoConservacao']),
      localizacao: _texto(json['localizacao']),
      status: _texto(json['status'], padrao: 'disponivel'),
      professorId: professorId,
      professorNome:
          _texto(json['professorNome'] ?? json['responsavelNome']),
      professorEmail:
          _texto(json['professorEmail'] ?? json['responsavelEmail']),
      dataAtribuicao: _paraData(json['dataAtribuicao']),
      observacoes: _texto(json['observacoes']),
      createdAt: _paraData(json['createdAt']),
      updatedAt: _paraData(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria,
        'marca': marca,
        'modelo': modelo,
        'numeroSerie': numeroSerie,
        'estadoConservacao': estadoConservacao,
        'localizacao': localizacao,
        'status': status,
        'professorId': professorId,
        'professorNome': professorNome,
        'professorEmail': professorEmail,
        'dataAtribuicao': dataAtribuicao?.toIso8601String(),
        'observacoes': observacoes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // --- Helpers de leitura tolerante -------------------------------------

  /// Converte `null`/ausente em string vazia.
  static String _texto(dynamic valor, {String padrao = ''}) {
    if (valor == null) return padrao;
    final texto = valor.toString().trim();
    return texto.isEmpty ? padrao : texto;
  }

  static int? _paraInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  static DateTime? _paraData(dynamic valor) {
    if (valor == null) return null;
    final data = DateTime.tryParse(valor.toString());
    // A API pode mandar uma data sem fuso ("2026-09-14"); nesse caso o
    // `tryParse` devolve null e a UI mostra o campo como ausente.
    return data?.toLocal();
  }
}
