import 'status_patrimonio.dart';

/// Resposta de `POST /api/patrimonios` (`CreatePatrimonioResponse`).
///
/// O backend confirma o cadastro mas **não** devolve o bem inteiro — só
/// o que a tela precisa para seguir em frente:
///
/// ```json
/// {
///   "message": "Patrimônio cadastrado com sucesso",
///   "patrimonioId": 8,
///   "codigo": "PAT-2024-008",
///   "status": "disponivel"
/// }
/// ```
///
/// [idVálido] resolve o caso em que a API confirma mas não devolve o id:
/// a Controller recarrega a lista em vez de tentar abrir um detalhe
/// inexistente.
class PatrimonioCriacaoModel {
  const PatrimonioCriacaoModel({
    required this.mensagem,
    required this.id,
    required this.codigo,
    required this.status,
  });

  final String mensagem;
  final int id;
  final String codigo;
  final StatusPatrimonio status;

  /// `true` quando veio um id utilizável para navegar ao detalhe.
  bool get idValido => id > 0;

  factory PatrimonioCriacaoModel.fromJson(Map<String, dynamic> json) {
    return PatrimonioCriacaoModel(
      mensagem: (json['message'] ?? '').toString(),
      id: _int(json['patrimonioId'] ?? json['id']) ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      status: StatusPatrimonio.fromValor(json['status']),
    );
  }

  static int? _int(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }
}
