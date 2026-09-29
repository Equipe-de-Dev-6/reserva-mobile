/// Corpo de `POST /api/admin/professores` (RN02).
///
/// O docente é cadastrado **exclusivamente** pelo Coordenador
/// autenticado, que também define a senha provisória de acesso.
/// Por isso a `role` não vai no corpo: o backend fixa "professor".
class ProfessorRequestModel {
  final String nome;
  final String email;
  final String senha;
  final String matricula;
  final String departamento;
  final String telefone;
  final String cpf;

  ProfessorRequestModel({
    required this.nome,
    required this.email,
    required this.senha,
    this.matricula = '',
    this.departamento = '',
    this.telefone = '',
    this.cpf = '',
  });

  Map<String, dynamic> toJson() => {
        'nome': nome.trim(),
        'email': email.trim(),
        'password': senha,
        'matricula': matricula.trim(),
        'departamento': departamento.trim(),
        'telefone': telefone.trim(),
        'cpf': cpf.trim(),
      };
}
