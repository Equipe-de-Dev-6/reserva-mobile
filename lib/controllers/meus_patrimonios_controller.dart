import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';

/// Controller da tela **"Meus Patrimônios"** do docente (RF08).
///
/// É a visão de leitura pura do professor: os bens vinculados a ele,
/// com tombamento, data de atribuição, localização e detalhes.
///
/// Não existe nenhuma ação de mutação aqui — nem no Controller, nem na
/// View. O backend também recusa escrita de docente com `403` (RN03),
/// mas a barreira real do ponto de vista do usuário é não haver botão
/// nenhum na tela.
class MeusPatrimoniosController extends GetxController {
  MeusPatrimoniosController(this._service);

  final PatrimonioService _service;

  /// `true` durante a carga da lista.
  final RxBool carregando = false.obs;

  final RxString erro = ''.obs;

  /// Os bens do docente autenticado.
  final RxList<PatrimonioModel> patrimonios = <PatrimonioModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega a lista de bens.
  Future<void> carregar() async {
    carregando.value = true;
    erro.value = '';

    try {
      patrimonios.assignAll(await _service.meus());
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// `true` quando o docente não tem nenhum bem sob responsabilidade.
  bool get vazio => !carregando.value && erro.value.isEmpty && patrimonios.isEmpty;

  /// Texto do estado vazio.
  ///
  /// Distingue "nenhum bem" de "erro": no primeiro caso a sugestão é
  /// falar com a coordenação; no segundo, tentar de novo.
  String get tituloEstadoVazio =>
      erro.value.isNotEmpty ? 'Não foi possível carregar' : 'Nenhum equipamento';

  String get descricaoEstadoVazio => erro.value.isNotEmpty
      ? erro.value
      : 'Você ainda não tem equipamentos sob sua responsabilidade. '
          'Procure a coordenação do/almooxarifado da escola.';
}
