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
    // `putAsync` aguarda a leitura do armazenamento seguro antes de
    // qualquer tela ser desenhada — a Splash já sabe se há sessão.
    Get.putAsync<SessaoService>(() => SessaoService().init(), permanent: true);
    Get.put(ApiClient(Get.find<SessaoService>()), permanent: true);

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
