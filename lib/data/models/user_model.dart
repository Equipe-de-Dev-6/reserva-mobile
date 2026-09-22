class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' ou 'professor'
  final String? matricula;
  final String? departamento;
  final String? telefone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.matricula,
    this.departamento,
    this.telefone,
  });

  factory UserModel.fromJson(Map json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      matricula: json['matricula'],
      departamento: json['departamento'],
      telefone: json['telefone'],
    );
  }

  Map toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'matricula': matricula,
      'departamento': departamento,
      'telefone': telefone,
    };
  }

  bool get isAdmin => role == 'admin';
}
