import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/servicos/sessao_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';
import '../models/status_patrimonio.dart';

/// Estado e regras da **tela de detalhe** de um bem (RF07a) e da
/// **exclusão** dele.
///
/// A tela recebe o `id` do bem por `Get.arguments`. O bem é carregado
/// em [onInit] para que a rota funcione sem a View precisar montar
/// qualquer requisição.
class PatrimonioDetalheController extends GetxController {
  PatrimonioDetalheController(this._service);

  final PatrimonioService _service;

  /// `true` enquanto o formulário está aberto (RF07a).
  final RxBool editando = false.obs;

  /// `true` durante a confirmação de exclusão — evita que dois toques
  /// seguidos abram duas diálogos.
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

  /// Busca o bem. Também cobre o botão "Tentar novamente" do estado de
  /// erro.
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

  void abrirEdicao() => editando.value = true;
  void fecharEdicao() => editando.value = false;

  /// Chamado pelo formulário depois de salvar, com o bem já atualizado.
  ///
  /// Substitui o objeto em memória em vez de refazer o GET: a resposta
  /// do `PUT` não traz o bem completo, e a tela não deve piscar.
  void aplicarAtualizacao(PatrimonioModel atualizado) {
    patrimonio.value = atualizado;
    editando.value = false;
  }

  /// Exclui o bem e volta para a listagem.
  ///
  /// Devolve `true` quando a exclusão aconteceu, para a View decidir se
  /// navega para trás.
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

  /// Status exibido no badge do detalhe, com o texto explicativo
  /// embaixo. Se o `PUT` mudou o status, o detalhe reflete sem recarregar.
  String get descricaoStatus => patrimonio.value?.status.descricao ?? '';

  /// `true` quando o bem está disponível para recebimento — usado para
  /// explicar, no detalhe, por que a atribuição está ou não disponível
  /// (o fluxo em si é do ciclo de vida, RF07b).
  bool get statusPermiteAtribuicao =>
      (patrimonio.value?.status ?? StatusPatrimonio.indefinido)
          .aceitaAtribuicao;
}
