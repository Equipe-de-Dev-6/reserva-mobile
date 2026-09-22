class ProfessorRequestModel {
  final String nome;
  final String email;
  final String senha;
  final String matricula;

  ProfessorRequestModel({
    required this.nome,
    required this.email,
    required this.senha,
    required this.matricula,
  });

  Map toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'matricula': matricula,
      'role': 'professor', // Fixado pela regra de negócio
    };
  }
}
