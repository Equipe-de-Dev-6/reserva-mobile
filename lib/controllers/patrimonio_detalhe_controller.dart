import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/servicos/sessao_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';
import '../models/status_patrimonio.dart';

/// Estado e regras da **tela de detalhe** de um bem (RF07a).
///
/// A tela recebe o `id` do bem por `Get.arguments`, então a rota
/// funciona sem a View precisar montar requisição nenhuma. O bem é
/// carregado em [onInit].
class PatrimonioDetalheController extends GetxController {
  PatrimonioDetalheController(this._service);

  final PatrimonioService _service;

  /// `true` durante a exclusão — evita que dois toques seguidos abram
  /// duas diálogos de confirmação.
  final RxBool excluindo = false.obs;

  final Rx<PatrimonioModel?> patrimonio = Rx<PatrimonioModel?>(null);
  final RxBool carregando = true.obs;
  final RxString erro = ''.obs;

  /// Só o Coordinator vê ações de escrita (RN03).
  bool get podeEditar =>
      Get.find<SessaoService>().usuario.value?.isAdmin ?? false;

  /// Id recebido pela rota.
  late final int id;

  @override
  void onInit() {
    super.onInit();

    final argumentos = Get.arguments;
    if (argumentos is int) {
      id = argumentos;
    } else if (argumentos is Map && argumentos['id'] is int) {
      id = argumentos['id'] as int;
    } else {
      id = 0;
    }

    carregar();
  }

  /// Busca o bem. Cobre também o botão "Tentar novamente" do estado de
  /// erro e o retorno do formulário de edição, que altera dados que só
  /// o servidor tem.
  Future<void> carregar() async {
    if (id <= 0) {
      erro.value = 'Patrimônio não informado.';
      carregando.value = false;
      return;
    }

    carregando.value = true;
    erro.value = '';

    try {
      patrimonio.value = await _service.detalhe(id);
    } on AppException catch (e) {
      // 403 cai aqui: o docente tentando abrir um bem de terceiro, ou
      // um item que saiu do acervo entre a listagem e o toque.
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Exclui o bem.
  ///
  /// Devolve `true` quando a exclusão aconteceu, para a View navegar
  /// para trás. A confirmação é responsabilidade da tela — este método
  /// executa, não pergunta.
  Future<bool> excluir() async {
    if (excluindo.value) return false;
    excluindo.value = true;

    try {
      await _service.excluir(id);
      return true;
    } on AppException catch (e) {
      erro.value = e.mensagem;
      return false;
    } finally {
      excluindo.value = false;
    }
  }

  /// Texto explicativo do status, exibido abaixo do `BadgeStatus`.
  String get descricaoStatus => patrimonio.value?.status.descricao ?? '';

  /// `true` quando o bem pode ser entregue a um docente.
  ///
  /// Não é o botão de atribuição (esse é o fluxo do ciclo de vida,
  /// RF07b): serve para o detalhe explicar por que o bem está ou não
  /// pronto para recebimento.
  bool get statusPermiteAtribuicao =>
      (patrimonio.value?.status ?? StatusPatrimonio.indefinido)
          .aceitaAtribuicao;
}
