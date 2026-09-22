class PatrimonyModel {
  final String id;
  final String tombamento;
  final String descricao;
  final String categoria;
  final String marca;
  final String? numeroSerie;
  final String status; // 'disponivel', 'em_uso', 'em_manutencao'
  final String? professorId; // Preenchido se status for 'em_uso'

  PatrimonyModel({
    required this.id,
    required this.tombamento,
    required this.descricao,
    required this.categoria,
    required this.marca,
    this.numeroSerie,
    required this.status,
    this.professorId,
  });

  factory PatrimonyModel.fromJson(Map json) {
    return PatrimonyModel(
      id: json['id'],
      tombamento: json['tombamento'],
      descricao: json['descricao'],
      categoria: json['categoria'],
      marca: json['marca'],
      numeroSerie: json['numeroSerie'],
      status: json['status'],
      professorId: json['professorId'],
    );
  }

  Map toJson() {
    return {
      'tombamento': tombamento,
      'descricao': descricao,
      'categoria': categoria,
      'marca': marca,
      'numeroSerie': numeroSerie,
      'status': status,
      'professorId': professorId,
    };
  }
}
