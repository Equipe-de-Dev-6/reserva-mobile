/// Perfil do usuário logado.
///
/// A API devolve este objeto em `/auth/login` e em `/profile`.
/// O campo `id` chega como inteiro no JSON, mas o modelo também aceita
/// string para tolerar variations de serialização.
class UsuarioModel {
  final int? id;
  final String nome;
  final String email;
  final String role; // 'admin' (Coordenador) ou 'professor' (Docente)
  final String matricula;
  final String departamento;
  final String cpf;
  final String telefone;
  final String dataNascimento;
  final String genero;
  final String cep;
  final String endereco;
  final String cidadeUf;
  final String contatoEmergencia;
  final String tipoSanguineo;
  final String alergias;
  final int totalPatrimonios;
  final DateTime? createdAt;

  UsuarioModel({
    this.id,
    required this.nome,
    required this.email,
    this.role = 'professor',
    this.matricula = '',
    this.departamento = '',
    this.cpf = '',
    this.telefone = '',
    this.dataNascimento = '',
    this.genero = '',
    this.cep = '',
    this.endereco = '',
    this.cidadeUf = '',
    this.contatoEmergencia = '',
    this.tipoSanguineo = '',
    this.alergias = '',
    this.totalPatrimonios = 0,
    this.createdAt,
  });

  // --- Regras de RBAC ---------------------------------------------------
  // A View e os Controllers consultam estes atalhos em vez de comparar
  // strings soltas, evitando erros de digitação no controle de acesso.
  bool get isAdmin => role == 'admin';
  bool get isProfessor => role == 'professor';

  /// Iniciais usadas no avatar (ex.: "Coordenador Geral" -> "CG").
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  /// "Desconhecido" quando o contato não foi informado no cadastro.
  String get telefoneFormatado => telefone.isEmpty ? 'Não informado' : telefone;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: _paraInt(json['id']),
      nome: _paraTexto(json['nome']),
      email: _paraTexto(json['email']),
      role: _paraTexto(json['role'], padrao: 'professor'),
      matricula: _paraTexto(json['matricula']),
      departamento: _paraTexto(json['departamento']),
      cpf: _paraTexto(json['cpf']),
      telefone: _paraTexto(json['telefone']),
      dataNascimento: _paraTexto(json['dataNascimento']),
      genero: _paraTexto(json['genero']),
      cep: _paraTexto(json['cep']),
      endereco: _paraTexto(json['endereco']),
      cidadeUf: _paraTexto(json['cidadeUf']),
      contatoEmergencia: _paraTexto(json['contatoEmergencia']),
      tipoSanguineo: _paraTexto(json['tipoSanguineo']),
      alergias: _paraTexto(json['alergias']),
      totalPatrimonios: _paraInt(json['totalPatrimonios']) ?? 0,
      createdAt: DateTime.tryParse(_paraTexto(json['createdAt'])),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'email': email,
        'role': role,
        'matricula': matricula,
        'departamento': departamento,
        'cpf': cpf,
        'telefone': telefone,
        'dataNascimento': dataNascimento,
        'genero': genero,
        'cep': cep,
        'endereco': endereco,
        'cidadeUf': cidadeUf,
        'contatoEmergencia': contatoEmergencia,
        'tipoSanguineo': tipoSanguineo,
        'alergias': alergias,
      };

  UsuarioModel copyWith({
    String? nome,
    String? email,
    String? telefone,
    String? matricula,
    String? departamento,
    String? cpf,
    int? totalPatrimonios,
  }) {
    return UsuarioModel(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      role: role,
      matricula: matricula ?? this.matricula,
      departamento: departamento ?? this.departamento,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      dataNascimento: dataNascimento,
      genero: genero,
      cep: cep,
      endereco: endereco,
      cidadeUf: cidadeUf,
      contatoEmergencia: contatoEmergencia,
      tipoSanguineo: tipoSanguineo,
      alergias: alergias,
      totalPatrimonios: totalPatrimonios ?? this.totalPatrimonios,
      createdAt: createdAt,
    );
  }

  // --- Helpers de leitura tolerante -------------------------------------

  /// A API pode omitir campos ou devolver "" no lugar de null.
  static String _paraTexto(dynamic valor, {String padrao = ''}) {
    if (valor == null) return padrao;
    final texto = valor.toString();
    return texto.isEmpty ? padrao : texto;
  }

  static int? _paraInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }
}
