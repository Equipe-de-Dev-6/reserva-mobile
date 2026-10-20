import 'package:get/get.dart';

import '../core/servicos/professor_service.dart';
import '../core/utils/app_exception.dart';
import '../models/professor_model.dart';

/// Controller da listagem de professores (RF06).
///
/// Ele concentra o *estado da tela* (carregando, erro, termo de busca) e
/// a única regra de negócio dela: o recorte por busca. A View apenas
/// desenha o que este Controller expõe.
class ProfessorListaController extends GetxController {
  ProfessorListaController(this._service);

  final ProfessorService _service;

  // --- Estado reativo ---------------------------------------------------

  /// Spinner/esqueleto enquanto a lista não chegou (RNF02).
  final RxBool carregando = false.obs;

  /// Mensagem de erro amigável (401/403/404/rede) — vazia = sem erro.
  final RxString erro = ''.obs;

  /// Corpo completo devolvido por `GET /admin/professores`.
  final RxList<ProfessorModel> professores = <ProfessorModel>[].obs;

  /// Texto digitado na busca.
  final RxString busca = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  // =========================================================================
  // CARREGAMENTO
  // =========================================================================
  Future<void> carregar() async {
    carregando.value = true;
    erro.value = '';

    try {
      professores.assignAll(await _service.listar());
    } on AppException catch (e) {
      erro.value = e.mensagem;
      // Lista vazia + erro é o estado que a View desenha como
      // "não foi possível carregar". Não engolir a exceção aqui
      // significaria repetir o `try/catch` em toda a tela.
    } finally {
      carregando.value = false;
    }
  }

  /// Recarrega mantendo o termo de busca: quem estava filtrando a lista
  /// não perde o filtro ao puxar para baixo.
  Future<void> recarregar() => carregar();

  // =========================================================================
  // BUSCA (o endpoint não aceita filtro — RN de recorte local)
  // =========================================================================
  void filtrar(String termo) {
    busca.value = termo;
  }

  /// Resultado da busca sobre a lista completa.
  ///
  /// É um getter, não um estado: derivar é mais seguro que duplicar,
  /// porque não existe caminho em que a lista exibida fique
  /// dessincronizada da lista em memória.
  List<ProfessorModel> get resultados {
    final termo = busca.value;
    if (termo.trim().isEmpty) return List.unmodifiable(professores);

    return List.unmodifiable(
      professores.where((p) => p.correspondeAoTermo(termo)),
    );
  }

  // =========================================================================
  // INDICADORES DO CABEÇALHO
  // =========================================================================
  int get totalDocentes => professores.length;

  /// Soma dos bens de todos os docentes — o "total de vínculos" da
  /// escola, útil para o Coordenador enxergar a carga em um olhar.
  int get totalBens => professores.fold<int>(
        0,
        (soma, p) => soma + p.totalPatrimonios,
      );

  /// `true` quando existe corpo docente cadastrado, mas a busca não
  /// encontrou ninguém. Permite distinguir "nenhum professor" de
  /// "nenhum resultado" (RNF02).
  bool get buscaSemResultado =>
      professores.isNotEmpty && resultados.isEmpty;
}
