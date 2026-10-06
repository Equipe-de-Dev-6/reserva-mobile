/// Exceção de negócio do aplicativo: carrega uma mensagem já pronta
/// para ser exibida ao usuário.
///
/// O objetivo é isolar as Views de detalhes de transporte (DioException,
/// SocketException...). Toda falha vira um [AppException] antes de chegar
/// no Controller, que por sua vez apenas mostra a mensagem.
class AppException implements Exception {
  final String mensagem;
  final int? statusCode;

  const AppException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}
