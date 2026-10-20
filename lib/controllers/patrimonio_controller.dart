import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/servicos/sessao_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/text_controllers.dart';
import '../models/patrimonio_model.dart';
import '../models/status_patrimonio.dart';

/// Estado e regras da **listagem** de patrimônios (RF07a).
///
/// Concentra o que a tela precisa saber e nada mais:
///
///  * o que está sendo exibido ([patrimonios]);
///  * se a chamada está em andamento ([carregando]);
///  * o que deu errado, em texto pronto ([erro]);
///  * os filtros ativos ([busca], [statusSelecionado],
///    [categoriaSelecionada]).
///
/// ## Debounce da busca
///
/// A busca dispara após [debounceBusca] sem digitação. Sem isso, cada
/// tecla geraria uma requisição — e o backend receberia `PAT-`, `PAT-2`,
/// `PAT-20`... em sequência. O Timer é cancelado em [onClose] para não
/// vazar quando o usuário sai da tela.
class PatrimonioController extends GetxController {
  PatrimonioController(this._service);

  final PatrimonioService _service;

  /// Intervalo de silêncio antes de consultar a API.
  static const Duration debounceBusca = Duration(milliseconds: 350);

  // --- Estado reativo ---------------------------------------------------

  final RxList<PatrimonioModel> patrimonios = <PatrimonioModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  /// Texto digitado no campo de busca (tombamento, nome, marca, modelo).
  final RxString busca = ''.obs;

  /// Filtros de status e categoria. `null` significa "todos".
  ///
  /// Ambos são `Rx` de tipo anulável (`Rx<String?>`), e não `RxString`:
  /// o GetX só oferece `RxString` para valores não-nulos, e "sem filtro"
  /// precisa ser um estado observável de verdade — se fosse um `String`
  /// vazio, a View não conseguiria distinguir "sem filtro" de "filtro em
  /// branco" sem um segundo campo.
  final Rx<StatusPatrimonio?> statusSelecionado = Rx<StatusPatrimonio?>(null);
  final Rx<String?> categoriaSelecionada = Rx<String?>(null);

  /// `true` quando algum filtro está ativo — usado para decidir entre
  /// "nenhum bem cadastrado" e "nenhum bem encontrado" no estado vazio.
  final RxBool temFiltroAtivo = false.obs;

  final TextEditingController buscaCtrl = TextEditingController();

  Timer? _timerBusca;

  /// Verdadeiro quando o usuário logado é o Coordenador.
  ///
  /// É o que habilita o botão de cadastrar bem. O botão é escondido, e
  /// não apenas desabilitado: um docente não deve enxergar a ação
  /// (RN03).
  bool get podeCadastrar =>
      Get.find<SessaoService>().usuario.value?.isAdmin ?? false;

  // -------------------------------------------------------------------------
  // Carga de dados
  // -------------------------------------------------------------------------

  /// Carrega a listagem aplicando os filtros atuais.
  ///
  /// [silencioso] suprime o spinner: usado quando só os filtros mudam e
  /// a lista anterior continua válida na tela, evitando o "piscar" da
  /// lista a cada clique num chip de filtro.
  Future<void> carregar({bool silencioso = false}) async {
    if (!silencioso) carregando.value = true;
    erro.value = '';

    try {
      patrimonios.assignAll(
        await _service.listar(
          busca: busca.value,
          status: statusSelecionado.value,
          categoria: categoriaSelecionada.value,
        ),
      );
    } on AppException catch (e) {
      erro.value = e.mensagem;
      // Uma falha ao filtrar não deve apagar o que já estava na tela:
      // o Coordenador ainda consegue ler o acervo anterior e tentar
      // limpar o filtro.
    } finally {
      carregando.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  @override
  void onClose() {
    _timerBusca?.cancel();
    // Limpa, em vez de descartar (ver `core/utils/text_controllers.dart`).
    limparCampos([buscaCtrl]);
    super.onClose();
  }

  // -------------------------------------------------------------------------
  // Busca (com debounce)
  // -------------------------------------------------------------------------

  /// Chamado a cada tecla digitada no campo de busca.
  void aoDigitarBusca(String valor) {
    busca.value = valor;
    _atualizarFiltroAtivo();

    _timerBusca?.cancel();
    _timerBusca = Timer(debounceBusca, carregar);
  }

  /// Busca imediata, sem espera — usado pelo botão "Buscar" e pelo
  /// `onSubmitted` do campo.
  Future<void> buscarAgora() async {
    _timerBusca?.cancel();
    busca.value = buscaCtrl.text;
    _atualizarFiltroAtivo();
    await carregar();
  }

  // -------------------------------------------------------------------------
  // Filtros
  // -------------------------------------------------------------------------

  /// Seleciona (ou desmarca) um status.
  ///
  /// Tocar no status já selecionado o desmarca: é o jeito mais rápido de
  /// voltar para "todos" sem procurar o chip "Todos".
  Future<void> alternarStatus(StatusPatrimonio? status) async {
    statusSelecionado.value =
        statusSelecionado.value == status ? null : status;
    _atualizarFiltroAtivo();
    await carregar(silencioso: true);
  }

  Future<void> escolherCategoria(String? categoria) async {
    categoriaSelecionada.value =
        categoriaSelecionada.value == categoria ? null : categoria;
    _atualizarFiltroAtivo();
    await carregar(silencioso: true);
  }

  /// Limpa busca, status e categoria de uma vez.
  Future<void> limparFiltros() async {
    _timerBusca?.cancel();
    buscaCtrl.clear();
    busca.value = '';
    statusSelecionado.value = null;
    categoriaSelecionada.value = null;
    temFiltroAtivo.value = false;
    await carregar();
  }

  void _atualizarFiltroAtivo() {
    temFiltroAtivo.value = busca.value.trim().isNotEmpty ||
        statusSelecionado.value != null ||
        categoriaSelecionada.value != null;
  }

  // -------------------------------------------------------------------------
  // Mensagens dos estados vazios (RNF02)
  // -------------------------------------------------------------------------

  /// Texto do [EstadoVazio] conforme o motivo da lista estar vazia.
  ///
  /// Distinguir "acervo vazio" de "busca sem resultado" importa: no
  /// primeiro caso a ação sugerida é cadastrar um bem; no segundo, é
  /// limpar o filtro.
  String get tituloEstadoVazio =>
      temFiltroAtivo.value ? 'Nenhum bem encontrado' : 'Nenhum bem cadastrado';

  String get descricaoEstadoVazio => temFiltroAtivo.value
      ? 'Ajuste a busca ou limpe os filtros para ver todo o acervo.'
      : 'Cadastre o primeiro bem para começar a controlar o patrimônio.';

}
