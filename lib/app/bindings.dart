import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/meus_patrimonios_controller.dart';
import '../controllers/perfil_controller.dart';
import '../controllers/professor_cadastro_controller.dart';
import '../controllers/professor_detalhe_controller.dart';
import '../controllers/professor_lista_controller.dart';
import '../controllers/splash_controller.dart';
import '../core/servicos/api_client.dart';
import '../core/servicos/auth_service.dart';
import '../core/servicos/patrimonio_service.dart';
import '../core/servicos/perfil_service.dart';
import '../core/servicos/professor_service.dart';
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

/// Bindings das telas de gestão de professores (RF06).
///
/// As três telas compartilham o mesmo [ProfessorService]: ele é criado
/// uma vez por rota e entregue aos Controllers que a rota precisa. As
/// Views nunca instalam nada — `GetView<T>` só faz `Get.find<T>()`, e o
/// `find` só funciona porque o binding registrou a dependência.
///
/// Os Controllers das listagem, cadastro e detalhe são registrados todos
/// aqui porque as três rotas usam este mesmo binding. Cada um é
/// `lazyPut`: o Controller só nasce quando a View daquele tipo é
/// procurada, e morre quando a rota é destruída, sem estado vazando
/// de uma tela para outra.
class ProfessorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfessorService>(
      () => ProfessorService(Get.find<ApiClient>()),
    );
    Get.lazyPut<ProfessorListaController>(
      () => ProfessorListaController(Get.find<ProfessorService>()),
    );
    Get.lazyPut<ProfessorCadastroController>(
      () => ProfessorCadastroController(Get.find<ProfessorService>()),
    );
    Get.lazyPut<ProfessorDetalheController>(
      () => ProfessorDetalheController(Get.find<ProfessorService>()),
    );
  }
}

/// Binding da tela de Perfil (RF09).
class PerfilBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PerfilService>(
      () => PerfilService(Get.find<ApiClient>(), Get.find<SessaoService>()),
    );
    Get.lazyPut<PerfilController>(
      () => PerfilController(
        Get.find<PerfilService>(),
        Get.find<SessaoService>(),
      ),
    );
  }
}

/// Binding do dashboard de indicadores (RF05).
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.lazyPut<DashboardController>(
      () => DashboardController(Get.find<PatrimonioService>()),
    );
  }
}

/// Binding da tela "Meus Patrimônios" do docente (RF08).
class MeusPatrimoniosBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.lazyPut<MeusPatrimoniosController>(
      () => MeusPatrimoniosController(Get.find<PatrimonioService>()),
    );
  }
}
