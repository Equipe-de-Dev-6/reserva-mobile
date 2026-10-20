import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Converte uma [DioException] em [AppException] com mensagem amigável.
///
/// A API em Go responde erros no formato `{"error": "mensagem"}`.
/// Quando essa mensagem existe ela tem prioridade, pois já é escrita
/// pensando no usuário final.
String mensagemDeErro(DioException erro) {
  final resposta = erro.response;
  final dados = resposta?.data;

  // 1. Mensagem vinda do próprio backend.
  if (dados is Map && dados['error'] != null) {
    return dados['error'].toString();
  }
  if (dados is Map && dados['message'] != null) {
    return dados['message'].toString();
  }

  // 2. Sem corpo utilizável: mensagem padrão por código HTTP.
  switch (resposta?.statusCode) {
    case 400:
      return 'Dados inválidos. Revise as informações e tente novamente.';
    case 401:
      return 'E-mail ou senha incorretos.';
    case 403:
      return 'Você não tem permissão para realizar esta ação.';
    case 404:
      return 'Recurso não encontrado.';
    case 409:
      return 'Este registro já existe.';
    case 500:
      return 'Erro interno no servidor. Tente novamente mais tarde.';
  }

  // 3. Erro de rede (API fora do ar, Wi-Fi desligado, etc.).
  switch (erro.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'O servidor demorou para responder. Verifique sua conexão.';
    case DioExceptionType.connectionError:
      // O endereço entra na mensagem: é a informação que falta quando o
      // app roda em outro dispositivo (o emulador Android usa
      // `10.0.2.2`, o celular físico usa o IP da máquina na rede) e o
      // backend não está no lugar esperado.
      final endereco = erro.requestOptions.uri.toString();
      return 'Não foi possível conectar ao servidor ($endereco). '
          'Confira se o api.exe está rodando e use "Verificar conexão" '
          'para ver o endereço que o app está usando.';
    case DioExceptionType.badCertificate:
      return 'Certificado de segurança inválido.';
    case DioExceptionType.cancel:
      return 'Requisição cancelada.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}

/// Executa uma chamada HTTP traduzindo qualquer falha em [AppException].
///
/// ```dart
/// final resposta = await chamar(() => _dio.post('/auth/login', data: body));
/// ```
///
/// Assim nenhum Controller precisa conhecer o Dio: ele só lida com
/// [AppException].
Future<T> chamar<T>(Future<T> Function() acao) async {
  try {
    return await acao();
  } on AppException {
    rethrow;
  } on DioException catch (e) {
    throw AppException(mensagemDeErro(e), statusCode: e.response?.statusCode);
  } catch (e) {
    throw AppException('Ocorreu um erro inesperado. Tente novamente.');
  }
}
