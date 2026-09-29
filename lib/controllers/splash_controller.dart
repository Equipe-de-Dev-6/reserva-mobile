import 'package:get/get.dart';

import '../app/middleware.dart';
import '../app/rotas.dart';
import '../core/servicos/sessao_service.dart';

/// Controla a Splash.
///
/// É ela quem decide o "roteamento condicional conforme a role"
/// descrito no RF01 quando o app é aberto com uma sessão salva.
class SplashController extends GetxController {
  /// Enquanto `true`, a tela mostra o indicador de progresso.
  /// Vira `false` assim que a rota de destino é escolhida.
  final RxBool verificando = true.obs;

  @override
  void onReady() {
    super.onReady();
    _decidirDestino();
  }

  Future<void> _decidirDestino() async {
    // Pequena pausa para a animação de entrada ficar visível.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final sessao = Get.find<SessaoService>();

    // A leitura do armazenamento seguro acontece aqui, e não no
    // Binding, para que o registro das dependências permaneça
    // síncrono. Só depois de restaurar token e perfil é seguro
    // decidir para onde navegar.
    await sessao.init();
    verificando.value = false;

    if (sessao.autenticado) {
      Get.offAllNamed(rotaPorSessao(sessao));
    } else {
      Get.offAllNamed(Rotas.login);
    }
  }
}
