/// Corpos das requisições de `PUT /api/profile` (RF09 / RN06).
///
/// Duas regras do backend orientam o desenho destes Models:
///
///  1. `PUT /profile` **não** é um "salvar tudo": ele aplica apenas os
///     campos presentes no corpo e responde `400` quando nenhum campo
///     chega (`{"error": "Nenhum campo fornecido para atualização"}`).
///     Por isso [AtualizarPerfilRequestModel.toJson] descarta valores
///     `null` — o Controller envia só o que de fato mudou.
///  2. A troca de senha viaja no **mesmo** endpoint, na chave
///     `newPassword`, e exige no mínimo 6 caracteres.
///
/// Os Models só montam JSON. Quem decide o que mudou — e quem compara a
/// confirmação da senha — é o Controller.
library;

// ---------------------------------------------------------------------------
// PUT /api/profile — dados cadastrais e de contato
// ---------------------------------------------------------------------------
class AtualizarPerfilRequestModel {
  /// Campos aceitos pelo endpoint. Um `null` significa "não mexer
  /// neste dado"; um texto (inclusive vazio, para limpar o campo) é
  /// enviado como está.
  final String? nome;
  final String? telefone;
  final String? departamento;
  final String? endereco;
  final String? cidadeUf;
  final String? contatoEmergencia;

  AtualizarPerfilRequestModel({
    this.nome,
    this.telefone,
    this.departamento,
    this.endereco,
    this.cidadeUf,
    this.contatoEmergencia,
  });

  /// Corpo effective da requisição: só o que foi preenchido.
  Map<String, dynamic> get campos {
    return {
      if (nome != null) 'nome': nome!.trim(),
      if (telefone != null) 'telefone': telefone!.trim(),
      if (departamento != null) 'departamento': departamento!.trim(),
      if (endereco != null) 'endereco': endereco!.trim(),
      if (cidadeUf != null) 'cidadeUf': cidadeUf!.trim(),
      if (contatoEmergencia != null)
        'contatoEmergencia': contatoEmergencia!.trim(),
    };
  }

  /// `true` quando nada mudou. O Controller usa isso para não disparar
  /// uma requisição que o backend rejeitaria com 400.
  bool get vazio => campos.isEmpty;

  Map<String, dynamic> toJson() => campos;
}

// ---------------------------------------------------------------------------
// PUT /api/profile — redefinição de senha (RF09)
// ---------------------------------------------------------------------------
///
/// A confirmação da senha **não** vai para o Model: ela é uma regra de
/// tela, validada pelo Controller antes da chamada.
class AlterarSenhaRequestModel {
  final String novaSenha;

  AlterarSenhaRequestModel({required this.novaSenha});

  /// O Swagger usa `newPassword` — a mesma chave do corpo completo.
  Map<String, dynamic> toJson() => {'newPassword': novaSenha};
}
