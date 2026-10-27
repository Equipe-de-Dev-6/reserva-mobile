/// Métricas gerais do sistema, devolvidas por `GET /admin/stats` (Parte 6).
///
/// São usadas no dashboard do Coordenador como um bloco extra, ao lado
/// dos indicadores patrimoniais: total de usuários, quantos são admin,
/// quantos são professores, quantos usuários comuns, sessões ativas e
/// códigos de recuperação de senha pendentes.
class AdminStatsModel {
  const AdminStatsModel({
    this.totalUsers = 0,
    this.totalAdmins = 0,
    this.totalProfessores = 0,
    this.standardUsers = 0,
    this.activeRefreshTokens = 0,
    this.pendingResetCodes = 0,
  });

  /// Total de usuários cadastrados na escola.
  final int totalUsers;

  /// Usuários com papel de `admin`.
  final int totalAdmins;

  /// Usuários com papel de `professor`.
  final int totalProfessores;

  /// Usuários com papel comum (`user`).
  final int standardUsers;

  /// Tokens de refresh ativos — aproximação de "sessões ativas".
  final int activeRefreshTokens;

  /// Códigos de recuperação de senha ainda válidos (não expirados).
  final int pendingResetCodes;

  /// `true` quando não há nenhum usuário cadastrado.
  bool get sistemaVazio => totalUsers == 0;

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: _int(json['totalUsers']),
      totalAdmins: _int(json['totalAdmins']),
      totalProfessores: _int(json['totalProfessores']),
      standardUsers: _int(json['standardUsers']),
      activeRefreshTokens: _int(json['activeRefreshTokens']),
      pendingResetCodes: _int(json['pendingResetCodes']),
    );
  }

  static int _int(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
