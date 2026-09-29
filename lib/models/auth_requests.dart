/// Requisições do módulo de Autenticação.
///
/// Cada Model cuida apenas de montar o JSON esperado pelo backend
/// (Go), respeitando os nomes de campo definidos no Swagger.
library;

// ---------------------------------------------------------------------------
// POST /api/auth/login
// ---------------------------------------------------------------------------
class LoginRequestModel {
  final String email;
  final String senha;

  LoginRequestModel({required this.email, required this.senha});

  /// O Swagger usa `password`, não `senha`.
  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': senha,
      };
}

// ---------------------------------------------------------------------------
// POST /api/auth/register  — RN01
// Auto-cadastro restrito a Coordenadores/Admins. Não há cadastro público
// de professor: o docente é criado pelo admin em /admin/professores.
// ---------------------------------------------------------------------------
class CadastroAdminRequestModel {
  final String nome;
  final String email;
  final String senha;
  final String departamento;
  final String telefone;
  final String cpf;

  CadastroAdminRequestModel({
    required this.nome,
    required this.email,
    required this.senha,
    this.departamento = '',
    this.telefone = '',
    this.cpf = '',
  });

  Map<String, dynamic> toJson() => {
        'nome': nome.trim(),
        'email': email.trim(),
        'password': senha,
        'departamento': departamento.trim(),
        'telefone': telefone.trim(),
        'cpf': cpf.trim(),
      };
}

// ---------------------------------------------------------------------------
// POST /api/auth/refresh e POST /api/auth/logout
// ---------------------------------------------------------------------------
class RefreshTokenRequestModel {
  final String refreshToken;

  RefreshTokenRequestModel({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

// ---------------------------------------------------------------------------
// POST /api/auth/forgot-password
// ---------------------------------------------------------------------------
class SolicitarCodigoRequestModel {
  final String email;

  SolicitarCodigoRequestModel({required this.email});

  Map<String, dynamic> toJson() => {'email': email.trim()};
}

/// Resposta de `/forgot-password`. Em produção o código chega por e-mail;
/// na versão atual o backend o exibe no console do servidor.
class SolicitarCodigoRespostaModel {
  final String mensagem;
  final int expiraEmSegundos;

  SolicitarCodigoRespostaModel({
    required this.mensagem,
    this.expiraEmSegundos = 0,
  });

  factory SolicitarCodigoRespostaModel.fromJson(Map<String, dynamic> json) {
    final expira = json['expiresIn'];
    return SolicitarCodigoRespostaModel(
      mensagem: (json['message'] ??
              'Código de confirmação gerado com sucesso.')
          .toString(),
      expiraEmSegundos:
          expira is int ? expira : int.tryParse('$expira') ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// POST /api/auth/verify-code
// ---------------------------------------------------------------------------
class VerificarCodigoRequestModel {
  final String email;
  final String codigo;

  VerificarCodigoRequestModel({required this.email, required this.codigo});

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'code': codigo.trim(),
      };
}

// ---------------------------------------------------------------------------
// POST /api/auth/reset-password
// ---------------------------------------------------------------------------
class RedefinirSenhaRequestModel {
  final String email;
  final String codigo;
  final String novaSenha;

  RedefinirSenhaRequestModel({
    required this.email,
    required this.codigo,
    required this.novaSenha,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'code': codigo.trim(),
        'newPassword': novaSenha,
      };
}
