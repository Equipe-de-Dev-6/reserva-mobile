import 'dart:io' show Platform;

/// Configuração central da comunicação com a API em Go (porta 8081).
///
/// A URL base pode ser sobrescrita em tempo de build. Isso resolve o
/// problema do "qual endereço usar?" em cada dispositivo sem recompilar
/// o código:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8081/api
class ApiConfig {
  ApiConfig._();

  /// Valor injetado via `--dart-define`. Fica vazio se não for informado.
  static const String urlCustomizada = String.fromEnvironment('API_BASE_URL');

  /// Resolve a URL base da API conforme a plataforma em execução.
  static String get baseUrl {
    if (urlCustomizada.isNotEmpty) {
      return urlCustomizada;
    }
    if (Platform.isAndroid) {
      // No emulador Android o "localhost" do celular é a própria máquina
      // somente através do alias 10.0.2.2.
      return 'http://10.0.2.2:8081/api';
    }
    // Simulador iOS e desktop: o backend roda na mesma máquina.
    return 'http://localhost:8081/api';
  }

  /// Tempo limite de espera por resposta do servidor.
  static const Duration timeout = Duration(seconds: 15);
}
