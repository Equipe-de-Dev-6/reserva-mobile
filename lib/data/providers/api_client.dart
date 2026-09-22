import 'package:dio/dio.dart';
import 'dart:io' show Platform;

class ApiClient {
  late Dio dio;

  ApiClient() {
    // Tratamento dinâmico de URL conforme o ambiente (Dica do escopo)
    String baseUrl = const String.fromEnvironment('API_URL', defaultValue: '');
    if (baseUrl.isEmpty) {
      if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8081/api'; // Emulador Android
      } else if (Platform.isIOS) {
        baseUrl = 'http://localhost:8081/api'; // Simulador iOS
      } else {
        baseUrl =
            'http://192.168.1.100:8081/api'; // Dispositivo físico (Altere o IP)
      }
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Interceptor para injeção automática do Token JWT
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token =
              await _getTokenDaSessaoLocal(); // Lógica de leitura do GetStorage/SharedPreferences
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Centralização do tratamento de erros HTTP (401, 403, 404)
          if (e.response?.statusCode == 403) {
            // Lida com o [RN03] (Acesso negado para Professor tentando escrever)
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future _getTokenDaSessaoLocal() async {
    // Implemente a leitura do token aqui
    return 'seu_token_jwt_salvo';
  }
}
