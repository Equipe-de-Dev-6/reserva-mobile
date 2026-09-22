class UserModel {
  final String? id;
  final String nome;
  final String email;
  final String role; // 'admin' ou 'professor'
  final String? matricula; // Presente apenas para professores

  UserModel({
    this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.matricula,
  });

  // Getters auxiliares para controle de permissões (RBAC) na View/Controller
  bool get isAdmin => role == 'admin';
  bool get isProfessor => role == 'professor';

  // Deserialização (JSON -> Objeto)
  factory UserModel.fromJson(Map json) {
    return UserModel(
      id: json['id']?.toString(),
      nome: json['nome'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'professor',
      matricula: json['matricula'],
    );
  }

  // Serialização (Objeto -> JSON)
  Map toJson() {
    final Map data = {'nome': nome, 'email': email, 'role': role};

    if (id != null) data['id'] = id;
    if (matricula != null) data['matricula'] = matricula;

    return data;
  }
}
