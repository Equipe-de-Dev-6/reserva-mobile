import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/servicos/professor_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';
import '../models/professor_model.dart';

/// Controller do **ciclo de vida** do bem: atribuição e devolução
/// (RF07b / RN05).
///
/// São dois fluxos numa tela só, porque um é a continuação do outro:
///
/// | Fluxo | O que faz | Status final |
/// |-------|-----------|--------------|
/// | Atribuição | escolhe um docente e entrega o bem | `em_uso` |
/// | Devolução  | desvincula o docente, com motivo | `disponivel` |
///
/// O Controller descobre sozinho qual fluxo é: o `Get.arguments` traz o
/// `id` do bem e o modo (`atribuir` ou `devolver`). A View só desenha o
/// que o Controller expõe.
class PatrimonioCicloVidaController extends GetxController {
  PatrimonioCicloVidaController(this._patrimonio, this._professores);

  final PatrimonioService _patrimonio;
  final ProfessorService _professores;

  // --- Estado reativo ---------------------------------------------------

  /// `true` durante o envio da atribuição/devolução.
  final RxBool salvando = false.obs;

  /// `true` enquanto a lista de docentes é carregada.
  final RxBool carregandoProfessores = false.obs;

  final RxString erro = ''.obs;

  /// Bem em movimento. Vem do `Get.arguments`.
  final Rxn<PatrimonioModel> patrimonio = Rxn<PatrimonioModel>();

  /// Docentes cadastrados, para o seletor da atribuição.
  final RxList<ProfessorModel> professores = <ProfessorModel>[].obs;

  /// Filtro digitado na busca da lista de docentes.
  final RxString buscaProfessor = ''.obs;

  // --- Campos do formulário ---------------------------------------------

  /// Observação opcional da entrega ("Termo de responsabilidade").
  final TextEditingController observacoesCtrl = TextEditingController();

  /// Motivo da devolução — é ele que aparece na linha do tempo.
  final TextEditingController motivoCtrl = TextEditingController();

  /// Id do docente escolhido. `null` = nenhum escolhido.
  final Rxn<int> professorSelecionado = Rxn<int>();

  // --- Modo da tela -------------------------------------------------------

  /// `true` no fluxo de devolução; `false` no de atribuição.
  bool get devolvendo => _modo == _Modo.devolver;

  /// `true` no fluxo de atribuição.
  bool get atribuindo => _modo == _Modo.atribuir;

  _Modo _modo = _Modo.atribuir;

  @override
  void onInit() {
    super.onInit();
    _lerArgumentos();
    if (atribuindo) {
      carregarProfessores();
    }
  }

  @override
  void onClose() {
    observacoesCtrl.dispose();
    motivoCtrl.dispose();
    super.onClose();
  }

  /// Lê o `id` do bem, o bem em si e o modo do fluxo vindos da rota.
  void _lerArgumentos() {
    final argumentos = Get.arguments;
    final Map<Object?, Object?> mapa =
        argumentos is Map ? argumentos : const <Object?, Object?>{};

    final id = mapa['id'];
    if (id is int) {
      _id = id;
    } else {
      final texto = id?.toString();
      _id = int.tryParse(texto ?? '') ?? 0;
    }

    // O bem em si vem junto quando a tela é aberta a partir do detalhe.
    // Sem ele, a View mostra apenas o tombamento — o suficiente para
    // confirmar a operação.
    final bem = mapa['patrimonio'];
    if (bem is PatrimonioModel) {
      patrimonio.value = bem;
      if (_id == 0) _id = bem.id;
    }

    _modo = mapa['modo'] == 'devolver' ? _Modo.devolver : _Modo.atribuir;
  }

  int _id = 0;

  /// Id do bem em movimento.
  int get id => _id;

  // -------------------------------------------------------------------------
  // DOCENTES (só no fluxo de atribuição)
  // -------------------------------------------------------------------------

  /// Carrega a lista de docentes para o seletor.
  ///
  /// O endpoint `GET /admin/professores` não aceita busca: o recorte é
  /// feito no aparelho, em [professoresFiltrados].
  Future<void> carregarProfessores() async {
    carregandoProfessores.value = true;
    erro.value = '';

    try {
      professores.assignAll(await _professores.listar());
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregandoProfessores.value = false;
    }
  }

  /// Docentes que casam com o termo digitado.
  ///
  /// A regra fica no Model ([ProfessorModel.correspondeAoTermo]) e não na
  /// View, para poder ser testada sem montar widget.
  List<ProfessorModel> get professoresFiltrados {
    final termo = buscaProfessor.value.trim();
    if (termo.isEmpty) return professores.toList();
    return professores.where((p) => p.correspondeAoTermo(termo)).toList();
  }

  /// Chamado a cada tecla digitada na busca de docente.
  void aoDigitarBuscaProfessor(String valor) {
    buscaProfessor.value = valor;
  }

  /// Seleciona (ou desmarca) um docente.
  void selecionarProfessor(int id) {
    professorSelecionado.value =
        professorSelecionado.value == id ? null : id;
  }

  /// Docente escolhido, ou `null`.
  ProfessorModel? get professorEscolhido {
    final id = professorSelecionado.value;
    if (id == null) return null;
    for (final professor in professores) {
      if (professor.id == id) return professor;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // ENVIO
  // -------------------------------------------------------------------------

  /// Executa o fluxo: atribui ou devolve, conforme a tela.
  ///
  /// Devolve `true` quando a operação foi concluída — é o sinal para a
  /// View fechar a tela. `false` mantém a tela aberta, com o motivo em
  /// [erro].
  Future<bool> confirmar(FormState formulario) async {
    erro.value = '';

    if (formulario.validate()) {
      // A validação do formulário (quando houver) já barrou.
      return false;
    }

    if (_id <= 0) {
      erro.value = 'Bem não informado.';
      return false;
    }

    salvando.value = true;
    try {
      if (devolvendo) {
        await _patrimonio.desatribuir(_id, motivo: motivoCtrl.text);
      } else {
        final professorId = professorSelecionado.value;
        if (professorId == null) {
          erro.value = 'Escolha o professor que vai receber o bem.';
          return false;
        }
        await _patrimonio.atribuir(
          _id,
          professorId,
          observacoes: observacoesCtrl.text,
        );
      }
      return true;
    } on AppException catch (e) {
      erro.value = e.mensagem;
      return false;
    } finally {
      salvando.value = false;
    }
  }

  // -------------------------------------------------------------------------
  // VALIDAÇÕES
  // -------------------------------------------------------------------------

  /// O motivo da devolução é o que fica registrado na linha do tempo:
  /// exigir que o Coordenador escreva o porquê é o que torna o histórico
  /// útil meses depois.
  String? validarMotivo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o motivo da devolução.';
    if (texto.length < 5) return 'Descreva o motivo com pelo menos 5 letras.';
    return null;
  }
}

enum _Modo { atribuir, devolver }
