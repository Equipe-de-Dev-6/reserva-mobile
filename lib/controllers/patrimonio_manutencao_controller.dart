import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/utils/app_exception.dart';
import '../models/patrimonio_model.dart';
import '../models/status_patrimonio.dart';

/// Controller do fluxo de **manutenção** do bem (RN05).
///
/// Dois movimentos opostos numa tela só, como no ciclo de vida de
/// atribuição/devolução — a tela descobre qual é o da vez pelo
/// `Get.arguments` (`modo`: `'enviar'` ou `'concluir'`):
///
/// | Movimento | O que faz | Status final |
/// |-----------|-----------|--------------|
/// | Envio     | tira o bem do almoxarifado para conserto | `em_manutencao` |
/// | Conclusão | devolve o bem consertado ao estoque      | `disponivel`    |
///
/// O backend não tem endpoint dedicado de manutenção: a troca de
/// status acontece no `PUT /patrimonios/{id}` (ver
/// [PatrimonioService.enviarParaManutencao]).
class PatrimonioManutencaoController extends GetxController {
  PatrimonioManutencaoController(this._patrimonio);

  final PatrimonioService _patrimonio;

  // --- Estado reativo ---------------------------------------------------

  /// `true` durante o envio da requisição.
  final RxBool salvando = false.obs;

  final RxString erro = ''.obs;

  /// Bem em manutenção. Vem do `Get.arguments`.
  final Rxn<PatrimonioModel> patrimonio = Rxn<PatrimonioModel>();

  // --- Campos do formulário ---------------------------------------------

  /// Defeito relatado (envio) ou serviço realizado (conclusão) — é o
  /// texto que aparece na linha do tempo do bem.
  final TextEditingController motivoCtrl = TextEditingController();

  // --- Modo da tela -------------------------------------------------------

  /// `true` no envio para conserto; `false` na conclusão.
  ///
  /// É público de propósito: o teste monta o Controller direto (o
  /// `Get.arguments` não tem setter) e precisa escolher o modo sem
  /// passar pelo roteador. Na aplicação, quem define é a rota.
  bool enviando = true;

  /// `true` na conclusão da manutenção.
  bool get concluindo => !enviando;

  /// Id do bem em movimento. Vem dos argumentos da rota; público pelo
  /// mesmo motivo do [enviando].
  int id = 0;

  @override
  void onInit() {
    super.onInit();
    _lerArgumentos();
  }

  @override
  void onClose() {
    motivoCtrl.dispose();
    super.onClose();
  }

  /// Lê o `id` do bem, o bem em si e o modo do movimento vindos da rota.
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
    final bem = mapa['patrimonio'];
    if (bem is PatrimonioModel) {
      patrimonio.value = bem;
      if (id == 0) id = bem.id;
    }

    if (mapa['modo'] == 'concluir') enviando = false;
  }

  // -------------------------------------------------------------------------
  // ENVIO
  // -------------------------------------------------------------------------

  /// Executa o movimento: envia para ou conclui a manutenção.
  ///
  /// Devolve `true` quando a operação foi concluída — é o sinal para a
  /// View fechar a tela. `false` mantém a tela aberta, com o motivo em
  /// [erro].
  Future<bool> confirmar(FormState formulario) async {
    erro.value = '';

    // `validate()` devolve `true` quando o formulário está **válido**.
    // Se for `false`, o próprio Form já exibiu a mensagem no campo.
    if (!formulario.validate()) return false;

    if (id <= 0) {
      erro.value = 'Bem não informado.';
      return false;
    }

    salvando.value = true;
    try {
      if (enviando) {
        await _patrimonio.enviarParaManutencao(
          id,
          observacao: motivoCtrl.text,
        );
      } else {
        await _patrimonio.concluirManutencao(
          id,
          observacao: motivoCtrl.text,
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

  /// O motivo é obrigatório nos dois movimentos: no envio é o defeito
  /// relatado, na conclusão é o serviço realizado. É o que a linha do
  /// tempo mostra meses depois.
  String? validarMotivo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return enviando
          ? 'Descreva o defeito apresentado pelo bem.'
          : 'Descreva o serviço realizado na manutenção.';
    }
    if (texto.length < 5) return 'Descreva o motivo com pelo menos 5 letras.';
    return null;
  }

  /// A regra de negócio impede enviar para manutenção um bem que tem
  /// docente responsável: primeiro ele precisa ser devolvido (RN05).
  ///
  /// Devolve `null` quando a operação é permitida, ou a mensagem que a
  /// View exibe.
  String? get bloqueioEnvio {
    final status = patrimonio.value?.status ?? StatusPatrimonio.indefinido;
    if (status == StatusPatrimonio.emUso) {
      return 'Este bem está com um professor. Registre a devolução '
          'antes de enviá-lo para manutenção.';
    }
    if (status == StatusPatrimonio.baixado) {
      return 'Bens baixados do acervo não passam por manutenção.';
    }
    return null;
  }
}
