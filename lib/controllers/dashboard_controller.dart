import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_stats_model.dart';

/// Controller do **dashboard de indicadores** do Coordenador (RF05).
///
/// A tela mostra a situação patrimonial da escola em números: total de
/// bens, em uso, disponíveis, em manutenção e a distribuição por
/// categoria.
///
/// Todos os números vêm prontos do backend
/// (`GET /admin/patrimonios/stats`): o Controller não conta nada. Isso
/// evita que o cliente e o servidor discordem sobre o que é "disponível"
/// ou "em uso" — e o servidor é quem manda.
class DashboardController extends GetxController {
  DashboardController(this._service);

  final PatrimonioService _service;

  // --- Estado reativo ---------------------------------------------------

  /// `true` durante a carga dos indicadores.
  final RxBool carregando = false.obs;

  /// Mensagem de erro pronta para exibição (RNF02).
  final RxString erro = ''.obs;

  /// Os indicadores. `null` enquanto a carga não termina ou falhou.
  final Rxn<PatrimonioStatsModel> indicadores =
      Rxn<PatrimonioStatsModel>();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  /// Carrega os indicadores.
  ///
  /// [silencioso] suprime o spinner: usado pelo "Atualizar" quando já
  /// há dados na tela, para não piscar o painel inteiro.
  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) carregando.value = true;
    erro.value = '';

    try {
      indicadores.value = await _service.estatisticas();
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  // --- Atalhos de leitura ------------------------------------------------

  /// `true` quando a escola ainda não tem nenhum bem cadastrado.
  ///
  /// O dashboard mostra um estado vazio com a ação sugerida em vez de
  /// uma parede de zeros (RNF02).
  bool get acervoVazio => indicadores.value?.acervoVazio ?? true;

  /// Título do estado vazio.
  String get tituloEstadoVazio =>
      acervoVazio ? 'Nenhum bem cadastrado' : 'Indicadores indisponíveis';

  /// Texto do estado vazio.
  String get descricaoEstadoVazio => acervoVazio
      ? 'Cadastre o primeiro bem para começar a acompanhar o acervo.'
      : 'Não foi possível carregar os indicadores agora. Tente novamente.';
}
