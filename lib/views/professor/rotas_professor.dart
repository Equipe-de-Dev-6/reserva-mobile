import 'package:get/get.dart';

import '../../app/middleware.dart';
import '../../controllers/patrimonio_detalhe_controller.dart';
import '../../core/servicos/api_client.dart';
import '../../core/servicos/patrimonio_service.dart';
import 'patrimonio_detalhe_professor_view.dart';

/// Nomes das rotas do painel do Docente que fogem do par
/// "home + meus-patrimônios" original.
///
/// Segue a convenção do módulo de Patrimônio (`rotas_patrimonio.dart`):
/// cada módulo tem dono definido e mora em arquivo próprio, para entrar
/// num PR sem tocar em código de terceiros. O dono de `app/rotas.dart`
/// concatena [paginasProfessor] na lista de `GetPage`.
class RotasProfessor {
  RotasProfessor._();

  /// Ficha completa de um bem, **somente leitura** (RF08 / RN03).
  ///
  /// O `id` do bem vai em `arguments` — é o mesmo contrato da tela de
  /// detalhe do Coordenador (`RotasPatrimonio.detalhe`).
  static const detalhePatrimonio = '/professor/patrimonios/detalhe';
}

/// Registra as dependências da ficha de leitura do docente.
///
/// O `PatrimonioService` é o mesmo sem estado do módulo de patrimônio
/// e é `permanent` pela mesma razão de lá: recriá-lo a cada rota abriria
/// uma nova instância a cada navegação.
///
/// O [PatrimonioDetalheController] também é o mesmo do Coordenador —
/// ele já carrega o bem pelo id e já esconde as ações de escrita quando
/// o papel logado não é admin (RN03). Só a View é outra: a do docente
/// não desenha nenhum botão de mutação.
class ProfessorPatrimonioBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.lazyPut<PatrimonioDetalheController>(
      () => PatrimonioDetalheController(Get.find<PatrimonioService>()),
    );
  }
}

/// Páginas deste módulo, prontas para entrar em `AppRotas.paginas`.
List<GetPage> get paginasProfessor => [
      GetPage(
        name: RotasProfessor.detalhePatrimonio,
        page: () => const PatrimonioDetalheProfessorView(),
        binding: ProfessorPatrimonioBinding(),
        // O bem é do próprio docente (o backend só devolve bens dele em
        // `GET /patrimonios/{id}`), então a guarda é a sessão — não há
        // restrição de papel nesta rota.
        middlewares: [AutenticadoMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ];
