import 'package:get/get.dart';

import '../core/servicos/professor_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';
import '../models/professor_model.dart';

/// Controller do detalhe do professor com seus bens (RF06.3).
///
/// O `id` chega pela própria rota nomeada (`/admin/professores/detalhe/:id`),
/// então o Controller o lê de `Get.parameters` em [onInit] — a View não
/// precisa transports nenhum parâmetro.
class ProfessorDetalheController extends GetxController {
  ProfessorDetalheController(this._service);

  final ProfessorService _service;

  // --- Estado reativo ---------------------------------------------------

  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;
  final Rxn<ProfessorDetalheModel> detalhe =
      Rxn<ProfessorDetalheModel>();

  @override
  void onInit() {
    super.onInit();
    final id = int.tryParse(Get.parameters['id'] ?? '');
    if (id == null) {
      // Rota chamada sem id válido: não há o que consultar.
      erro.value = 'Professor não encontrado.';
      return;
    }
    carregar(id);
  }

  // =========================================================================
  // CARREGAMENTO
  // =========================================================================
  Future<void> carregar(int id) async {
    carregando.value = true;
    erro.value = '';

    try {
      detalhe.value = await _service.detalhe(id);
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Recarrega usando o id da rota — é o que o botão "Tentar novamente"
  /// chama depois de uma falha de rede.
  Future<void> recarregar() async {
    final id = int.tryParse(Get.parameters['id'] ?? '');
    if (id != null) await carregar(id);
  }

  // =========================================================================
  // ATALHOS DE LEITURA
  // =========================================================================
  ProfessorModel? get professor => detalhe.value?.professor;

  List<PatrimonioModel> get patrimonios =>
      detalhe.value?.patrimonios ?? const [];

  bool get semBens => detalhe.value?.semBens ?? false;
}
