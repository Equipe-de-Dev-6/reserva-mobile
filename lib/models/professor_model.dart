import 'patrimonio_model.dart';

/// Um docente cadastrado pelo Coordenador (RN02).
///
/// É a projeção usada pela tela de gestão de professores. Traz o
/// indicador `totalPatrimonios` — calculado pelo próprio backend — que é
/// exatamente o "quantos bens cada docente tem" exigido pelo RF06, e por
/// isso o modelo **não** calcula nada: se o contador está errado, o
/// problema é de dado, não de regra de tela.
class ProfessorModel {
  final int id;
  final String nome;
  final String email;
  final String matricula;
  final String departamento;
  final String telefone;
  final String cpf;

  /// Sempre `professor`: o backend fixa esse papel na criação (RN02).
  final String role;

  /// Contador de bens sob responsabilidade (RF06 / RN04).
  final int totalPatrimonios;

  final DateTime? createdAt;

  ProfessorModel({
    required this.id,
    required this.nome,
    required this.email,
    this.matricula = '',
    this.departamento = '',
    this.telefone = '',
    this.cpf = '',
    this.role = 'professor',
    this.totalPatrimonios = 0,
    this.createdAt,
  });

  /// Iniciais para o avatar, com a mesma regra do `UsuarioModel`:
  /// primeiro e último termo do nome ("Prof. Carlos Drummond" -> "PD").
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  /// "Não informado" quando o contato ficou em branco no cadastro.
  String get telefoneFormatado =>
      telefone.isEmpty ? 'Não informado' : telefone;

  /// `true` quando há ao menos um bem sob guarda do docente.
  ///
  /// O card da listagem usa isso para dar destaque ao docente que já
  /// recebeu a guarda de equipamentos.
  bool get possuiBens => totalPatrimonios > 0;

  /// Texto do indicador exibido no card da listagem (RF06).
  String get rotuloBens => totalPatrimonios == 1
      ? '1 bem sob responsabilidade'
      : '$totalPatrimonios bens sob responsabilidade';

  /// Subtítulo do card: matrícula e departamento, já com os vazios
  /// tratados — um docente sem matrícula ainda mostra o departamento.
  String get resumoInstitucional {
    final partes = [matricula, departamento]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'Sem matrícula informada';
    return partes.join(' · ');
  }

  /// Filtro de busca da listagem (RF06).
  ///
  /// O endpoint `GET /admin/professores` não aceita parâmetro de busca,
  /// então o recorte é feito no aparelho. A regra fica no Model — e não
  /// na View — para poder ser testada sem montar widget.
  bool correspondeAoTermo(String termo) {
    final alvo = termo.trim().toLowerCase();
    if (alvo.isEmpty) return true;

    return nome.toLowerCase().contains(alvo) ||
        email.toLowerCase().contains(alvo) ||
        matricula.toLowerCase().contains(alvo) ||
        departamento.toLowerCase().contains(alvo);
  }

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    return ProfessorModel(
      id: _paraInt(json['id']) ?? 0,
      nome: _texto(json['nome'], padrao: 'Docente sem nome'),
      email: _texto(json['email']),
      matricula: _texto(json['matricula']),
      departamento: _texto(json['departamento']),
      telefone: _texto(json['telefone']),
      cpf: _texto(json['cpf']),
      role: _texto(json['role'], padrao: 'professor'),
      totalPatrimonios: _paraInt(json['totalPatrimonios']) ?? 0,
      createdAt: _paraData(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'matricula': matricula,
        'departamento': departamento,
        'telefone': telefone,
        'cpf': cpf,
        'role': role,
        'totalPatrimonios': totalPatrimonios,
      };

  // --- Helpers de leitura tolerante -------------------------------------

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
    return DateTime.tryParse(valor.toString())?.toLocal();
  }
}

/// Resposta de `GET /admin/professores/{id}` (RF06).
///
/// Junta o docente com a relação de bens vinculados a ele — os dois
/// vêm na mesma resposta, então a tela de detalhe faz **uma** requisição
/// em vez de duas.
class ProfessorDetalheModel {
  final ProfessorModel professor;
  final List<PatrimonyModel> patrimonios;

  ProfessorDetalheModel({
    required this.professor,
    required this.patrimonios,
  });

  /// `true` quando o docente está sem nenhum bem vinculado (RN04 prevê
  /// zero, um ou muitos).
  bool get semBens => patrimonios.isEmpty;

  /// Total de bens efetivamente listado no detalhe.
  ///
  /// A listagem (`GET /admin/professores`) e o detalhe podem divergir se
  /// um bem for atribuído entre as duas chamadas. A tela de detalhe
  /// mostra este número, que é o que está realmente na lista.
  int get totalPatrimonios => patrimonios.length;

  factory ProfessorDetalheModel.fromJson(Map<String, dynamic> json) {
    final professor = ProfessorModel.fromJson(
      Map<String, dynamic>.from(json['professor'] ?? <String, dynamic>{}),
    );

    final lista = (json['patrimonios'] as List?) ?? const [];
    final patrimonios = lista
        .whereType<Map>()
        .map((m) => PatrimonyModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return ProfessorDetalheModel(
      professor: professor,
      patrimonios: patrimonios,
    );
  }
}
