import 'package:get/get.dart';

import '../../app/middleware.dart';
import '../../controllers/patrimonio_controller.dart';
import '../../controllers/patrimonio_detalhe_controller.dart';
import '../../controllers/patrimonio_form_controller.dart';
import '../../core/servicos/api_client.dart';
import '../../core/servicos/patrimonio_service.dart';
import 'patrimonio_detalhe_view.dart';
import 'patrimonio_form_view.dart';
import 'patrimonio_lista_view.dart';

/// Nomes das rotas do módulo de Patrimônio.
///
/// Moram em um arquivo próprio — e não em `app/rotas.dart` — porque
/// aquele arquivo tem dono definido na convenção de merge da equipe
/// (Guilherme). Assim o módulo entra inteiro em um PR sem tocar em
/// arquivo de terceiros: basta o dono do `rotas.dart` concatenar
/// [paginasPatrimonio] na lista de `GetPage`.
///
/// ```dart
/// // app/rotas.dart (Guilherme)
/// static final List<GetPage> paginas = [
///   ...paginasBase,
///   ...paginasPatrimonio,   // <- linha do PR do Gabriel
/// ];
/// ```
class RotasPatrimonio {
  RotasPatrimonio._();

  static const lista = '/admin/patrimonios';
  static const detalhe = '/admin/patrimonios/detalhe';
  static const form = '/admin/patrimonios/form';
}

/// Registra o [PatrimonioService] e os Controllers do módulo.
///
/// O Service é `permanent` porque é sem estado e reaproveitado pelas
/// três telas (listagem, detalhe e formulário) — criá-lo a cada rota
/// abriria uma nova instância a cada navegação. Os Controllers são
/// `lazyPut` e nascem junto com a tela, como os demais do projeto.
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
  }
}

/// Páginas do módulo, prontas para entrar em `AppRotas.paginas`.
///
/// Todas exigem sessão ativa ([AutenticadoMiddleware]). O bloqueio por
/// papel é feito pelo próprio Controller: só o Coordinator vê o botão de
/// cadastrar e as ações de escrita (RN03), e o backend recusa a operação
/// com 403 de qualquer forma.
List<GetPage> get paginasPatrimonio => [
      GetPage(
        name: RotasPatrimonio.lista,
        page: () => const PatrimonioListaView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware()],
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.detalhe,
        page: () => const PatrimonioDetalheView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
      GetPage(
        name: RotasPatrimonio.form,
        page: () => const PatrimonioFormView(),
        binding: PatrimonioBinding(),
        middlewares: [AutenticadoMiddleware()],
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ];
