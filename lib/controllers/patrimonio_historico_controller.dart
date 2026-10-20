import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/utils/app_exception.dart';
import '../models/historico_model.dart';

/// Controller da **linha do tempo** do patrimônio (RF07b).
///
/// O histórico é gravado pelo backend a cada movimentação (cadastro,
/// atribuição, devolução, manutenção, edição). O app é estritamente
/// leitor: não existe método para criar ou editar um registro — e o
/// Professor nem chega a ver esta tela (RN03).
class PatrimonioHistoricoController extends GetxController {
  PatrimonioHistoricoController(this._service);

  final PatrimonioService _service;

  /// `true` durante a carga da linha do tempo.
  final RxBool carregando = false.obs;

  final RxString erro = ''.obs;

  /// A linha do tempo. `null` enquanto não carregou.
  final Rxn<HistoricoPatrimonioModel> historico =
      Rxn<HistoricoPatrimonioModel>();

  /// Id do bem, lido do `Get.arguments`.
  int id = 0;

  @override
  void onInit() {
    super.onInit();
    id = _lerId();
    carregar();
  }

  /// Lê o `id` do bem dos argumentos da rota.
  int _lerId() {
    final argumentos = Get.arguments;
    if (argumentos is int) return argumentos;
    if (argumentos is Map) {
      final valor = argumentos['id'];
      if (valor is int) return valor;
      return int.tryParse(valor?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  /// Carrega a linha do tempo. Cobre também o botão "Tentar novamente".
  Future<void> carregar() async {
    if (id <= 0) {
      erro.value = 'Patrimônio não informado.';
      carregando.value = false;
      return;
    }

    carregando.value = true;
    erro.value = '';

    try {
      historico.value = await _service.historico(id);
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Movimentações, da mais recente para a mais antiga.
  List<HistoricoModel> get itens => historico.value?.itens ?? const [];

  /// `true` quando o bem nunca entrou em nenhum movimento.
  bool get vazio => (historico.value?.total ?? 0) == 0;
}
