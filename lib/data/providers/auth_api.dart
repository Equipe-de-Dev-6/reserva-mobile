import 'package:dio/dio.dart';
import '../models/auth_response.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi(this.apiClient);

  Future login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Falha ao autenticar: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
