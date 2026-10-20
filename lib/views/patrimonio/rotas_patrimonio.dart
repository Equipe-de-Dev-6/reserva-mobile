import 'package:get/get.dart';

import '../../app/middleware.dart';
import '../../controllers/patrimonio_ciclo_vida_controller.dart';
import '../../controllers/patrimonio_controller.dart';
import '../../controllers/patrimonio_detalhe_controller.dart';
import '../../controllers/patrimonio_form_controller.dart';
import '../../controllers/patrimonio_historico_controller.dart';
import '../../controllers/patrimonio_manutencao_controller.dart';
import '../../core/servicos/api_client.dart';
import '../../core/servicos/patrimonio_service.dart';
import '../../core/servicos/professor_service.dart';
import 'patrimonio_atribuicao_view.dart';
import 'patrimonio_detalhe_view.dart';
import 'patrimonio_devolucao_view.dart';
import 'patrimonio_form_view.dart';
import 'patrimonio_historico_view.dart';
import 'patrimonio_lista_view.dart';
import 'patrimonio_manutencao_view.dart';

/// Nomes das rotas do módulo de Patrimônio.
///
/// Moram em um arquivo próprio — e não em `app/rotas.dart` — porque
/// aquele arquivo tem dono definido na convenção de merge da equipe.
/// Assim o módulo entra inteiro em um PR sem tocar em arquivo de
/// terceiros: o dono do `rotas.dart` concatena [paginasPatrimonio] na
/// lista de `GetPage`.
///
/// ```dart
/// // app/rotas.dart
/// static final List<GetPage> paginas = [
///   ...paginasBase,
///   ...paginasPatrimonio,   // <- linha do PR do módulo de patrimônio
/// ];
/// ```
class RotasPatrimonio {
  RotasPatrimonio._();

  static const lista = '/admin/patrimonios';
  static const detalhe = '/admin/patrimonios/detalhe';
  static const form = '/admin/patrimonios/form';

  // --- RF07b — ciclo de vida -------------------------------------------
  static const atribuicao = '/admin/patrimonios/atribuir';
  static const devolucao = '/admin/patrimonios/devolver';
  static const historico = '/admin/patrimonios/historico';

  // --- manutenção (RN05) -----------------------------------------------
  /// Envio para conserto e conclusão do conserto — dois movimentos
  /// numa tela só, distinguidos pelo argumento `modo`
  /// (`'enviar'` ou `'concluir'`).
  static const manutencao = '/admin/patrimonios/manutencao';
}

/// Registra o [PatrimonioService] e os Controllers do módulo.
///
/// O Service é `permanent` porque é sem estado e reaproveitado pelas
/// telas (listagem, detalhe, formulário, ciclo de vida e histórico) —
/// criá-lo a cada rota abriria uma nova instância a cada navegação. Os
/// Controllers são `lazyPut` e nascem junto com a tela, como os demais
/// do projeto.
class PatrimonioBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );

    Get.lazyPut<PatrimonioController>(
      () => PatrimonioController(Get.find<PatrimonioService>()),
    );
    Get.lazyPut<PatrimonioDetalheController>(
      () => PatrimonioDetalheController(Get.find<PatrimonioService>()),
    );
    Get.lazyPut<PatrimonioFormController>(
      () => PatrimonioFormController(Get.find<PatrimonioService>()),
    );
    Get.lazyPut<PatrimonioHistoricoController>(
      () => PatrimonioHistoricoController(Get.find<PatrimonioService>()),
    );
    Get.lazyPut<PatrimonioManutencaoController>(
      () => PatrimonioManutencaoController(Get.find<PatrimonioService>()),
    );

    // O fluxo de atribuição precisa da lista de docentes para o seletor.
    Get.lazyPut<ProfessorService>(
      () => ProfessorService(Get.find<ApiClient>()),
    );
    Get.lazyPut<PatrimonioCicloVidaController>(
      () => PatrimonioCicloVidaController(
        Get.find<PatrimonioService>(),
        Get.find<ProfessorService>(),
      ),
    );
  }
}

/// Páginas do módulo, prontas para entrar em `AppRotas.paginas`.
///
/// Todas exigem sessão ativa ([AutenticadoMiddleware]) **e** papel de
/// Coordenador ([AdminMiddleware]): todo o módulo é escrita de gestão —
/// e um docente que force a rota é devolvido ao próprio painel sem ver
/// a tela. A barreira real continua sendo o backend, que responde `403`
/// a qualquer mutação de docente (RN03).
List<GetPage> get paginasPatrimonio => [
      GetPage(
        name: RotasPatrimonio.lista,
        page: () => const PatrimonioListaView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.detalhe,
        page: () => const PatrimonioDetalheView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.form,
        page: () => const PatrimonioFormView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),

      // --- RF07b — atribuição, devolução e histórico -------------------
      // A entrega e a devolução são ações do Coordenador (RN05): o
      // backend responde 403 para qualquer outro papel.
      GetPage(
        name: RotasPatrimonio.atribuicao,
        page: () => const PatrimonioAtribuicaoView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.devolucao,
        page: () => const PatrimonioDevolucaoView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.historico,
        page: () => const PatrimonioHistoricoView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),

      // --- manutenção (RN05) --------------------------------------------
      GetPage(
        name: RotasPatrimonio.manutencao,
        page: () => const PatrimonioManutencaoView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ];
