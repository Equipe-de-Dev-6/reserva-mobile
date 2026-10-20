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
  ///
  /// É público de propósito: o teste monta o Controller direto (o
  /// `Get.arguments` não tem setter) e precisa escolher o fluxo sem
  /// passar pelo roteador. Na aplicação, quem define é a rota.
  bool devolvendo = false;

  /// `true` no fluxo de atribuição.
  bool get atribuindo => !devolvendo;

  /// Id do bem em movimento.
  ///
  /// Vem dos argumentos da rota; fica público pelo mesmo motivo do
  /// [devolvendo].
  int id = 0;

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
  ///
  /// Só preenche o que ainda estiver vazio: quem chamou o Controller
  /// com o id ou o modo já definidos tem prioridade sobre a rota.
  void _lerArgumentos() {
    final argumentos = Get.arguments;
    final Map<Object?, Object?> mapa =
        argumentos is Map ? argumentos : const <Object?, Object?>{};

    final idDosArgumentos = mapa['id'];
    if (id == 0) {
      if (idDosArgumentos is int) {
        id = idDosArgumentos;
      } else {
        id = int.tryParse(idDosArgumentos?.toString() ?? '') ?? 0;
      }
    }

    // O bem em si vem junto quando a tela é aberta a partir do detalhe.
    // Sem ele, a View mostra apenas o tombamento — o suficiente para
    // confirmar a operação.
    final bem = mapa['patrimonio'];
    if (bem is PatrimonioModel) {
      patrimonio.value = bem;
      if (id == 0) id = bem.id;
    }

    if (mapa['modo'] == 'devolver') devolvendo = true;
  }

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

    // `validate()` devolve `true` quando o formulário está **válido**.
    // Se for `false`, o próprio Form já exibiu a mensagem no campo e a
    // operação não pode seguir.
    if (!formulario.validate()) return false;

    if (id <= 0) {
      erro.value = 'Bem não informado.';
      return false;
    }

    // O motivo da devolução é validado aqui também, e não só no `Form`
    // da View: a regra mora no Controller (como em todo o resto do
    // projeto) e a tela não é o único guardião dela.
    if (devolvendo) {
      final erroMotivo = validarMotivo(motivoCtrl.text);
      if (erroMotivo != null) {
        erro.value = erroMotivo;
        return false;
      }
    }

    salvando.value = true;
    try {
      if (devolvendo) {
        await _patrimonio.desatribuir(id, motivo: motivoCtrl.text);
      } else {
        final professorId = professorSelecionado.value;
        if (professorId == null) {
          erro.value = 'Escolha o professor que vai receber o bem.';
          return false;
        }
        await _patrimonio.atribuir(
          id,
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
