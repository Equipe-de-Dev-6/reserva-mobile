/// Usuário da escola, devolvido por `GET /admin/users` (Parte 6).
///
/// É a projeção de leitura do cadastro de usuários: id, nome, e-mail,
/// papel, matrícula, departamento, telefone, total de bens e data de
/// criação. Nenhum dado sensível (senha, token) aparece aqui — o model
/// é só para exibição na tela de administração.
class UsuarioAdminModel {
  const UsuarioAdminModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.matricula = '',
    this.departamento = '',
    this.telefone = '',
    this.totalPatrimonios = 0,
    this.createdAt,
  });

  final int id;
  final String nome;
  final String email;
  /// 'admin' | 'professor' | 'user'
  final String role;
  final String matricula;
  final String departamento;
  final String telefone;
  final int totalPatrimonios;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isProfessor => role == 'professor';

  /// Rótulo amigável do papel, para exibição na interface.
  String get rotuloPapel => switch (role) {
        'admin' => 'Coordenador',
        'professor' => 'Professor',
        _ => 'Usuário',
      };

  /// Iniciais para o avatar (mesma regra de `ProfessorModel`):
  /// "Prof. Carlos Drummond" -> "PD".
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: _paraInt(json['id']) ?? 0,
      nome: _texto(json['nome'], padrao: 'Sem nome'),
      email: _texto(json['email']),
      role: _texto(json['role'], padrao: 'user'),
      matricula: _texto(json['matricula']),
      departamento: _texto(json['departamento']),
      telefone: _texto(json['telefone']),
      totalPatrimonios: _paraInt(json['totalPatrimonios']) ?? 0,
      createdAt: _paraData(json['createdAt']),
    );
  }

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
