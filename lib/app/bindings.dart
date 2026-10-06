import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/splash_controller.dart';
import '../core/servicos/api_client.dart';
import '../core/servicos/auth_service.dart';
import '../core/servicos/sessao_service.dart';
import 'rotas.dart';

/// Injeção de dependências (a "D" do padrão de projeto solicitado).
///
/// Os Bindings do GetX criam e descartam os Controllers junto com a
/// rota. Isso mantém a tela de Login "limpa" quando o usuário sai dela:
/// o controller é destruído e na volta nasce um novo, sem estado antigo.
/// Nenhuma tela instancia Service ou Controller manualmente.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // O registro é SÍNCRONO de propósito. Com `Get.putAsync` a instância
    // só entra no contêiner do GetX depois que o Future resolve, o que
    // deixaria o `Get.find` da linha seguinte sem resposta — e o
    // `ApiClient`, que o login depende, nunca seria registrado.
    //
    // A leitura do armazenamento seguro é assíncrona, mas isso é feito
    // explicitamente pelo SplashController (que é justamente a tela
    // responsável por decidir o destino com base na sessão salva).
    final sessao = Get.put(SessaoService(), permanent: true);
    Get.put(ApiClient(sessao), permanent: true);

    // Ponte entre a camada de rede e a navegação: quando o token
    // expira e não pode ser renovado, voltamos para o Login.
    ApiClient.aoExpirarSessao = _rotarParaLogin;
  }

  static void _rotarParaLogin() {
    if (Get.currentRoute == Rotas.login) return;
    Get.offAllNamed(Rotas.login);
  }
}

/// Controller compartilhado pelas telas de autenticação.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
      () => AuthService(Get.find<ApiClient>(), Get.find<SessaoService>()),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthService>()),
    );
  }
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
