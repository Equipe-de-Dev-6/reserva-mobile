import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/professor_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/text_controllers.dart';
import '../core/utils/validadores.dart';
import '../models/professor_request.dart';

/// Controller do cadastro de professor (RF06.2 / RN02).
///
/// A senha **provisória** é definida aqui, pelo Coordenador — o app não
/// envia convite por e-mail, não existe fluxo de "primeiro acesso" no
/// backend. Por isso o formulário pede a senha e a confirmação.
class ProfessorCadastroController extends GetxController {
  ProfessorCadastroController(this._service);

  final ProfessorService _service;

  // --- Estado reativo ---------------------------------------------------

  final RxBool salvando = false.obs;
  final RxString erro = ''.obs;

  // --- Campos do formulário ---------------------------------------------

  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  final confirmarSenhaCtrl = TextEditingController();
  final matriculaCtrl = TextEditingController();
  final departamentoCtrl = TextEditingController();
  final telefoneCtrl = TextEditingController();
  final cpfCtrl = TextEditingController();

  final senhaOculta = true.obs;

  @override
  void onClose() {
    // Limpa, em vez de descartar (ver `core/utils/text_controllers.dart`).
    limparCampos([
      nomeCtrl,
      emailCtrl,
      senhaCtrl,
      confirmarSenhaCtrl,
      matriculaCtrl,
      departamentoCtrl,
      telefoneCtrl,
      cpfCtrl,
    ]);
    super.onClose();
  }

  // =========================================================================
  // RF06.2 — CADASTRO
  // =========================================================================
  Future<void> cadastrar(FormState formulario) async {
    erro.value = '';
    if (!formulario.validate()) return;

    salvando.value = true;
    try {
      final professor = await _service.cadastrar(
        ProfessorRequestModel(
          nome: nomeCtrl.text,
          email: emailCtrl.text.trim(),
          senha: senhaCtrl.text,
          matricula: matriculaCtrl.text,
          departamento: departamentoCtrl.text,
          telefone: telefoneCtrl.text,
          cpf: cpfCtrl.text,
        ),
      );

      // `Get.back(result: ...)` devolve o docente para a listagem, que
      // já atualiza a lista e mostra o snackbar. A tela de cadastro não
      // precisa conhecer a listagem para saber que terminou.
      Get.back<bool>(result: true);

      Get.snackbar(
        'Professor cadastrado',
        professor.nome.isEmpty
            ? 'Docente adicionado ao corpo docente.'
            : '${professor.nome} já pode acessar o app.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1B8A5A),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on AppException catch (e) {
      // 400 (campo obrigatório), 403 (não é admin) e 409 (e-mail já
      // cadastrado) chegam aqui já com a mensagem do backend.
      erro.value = e.mensagem;
    } finally {
      salvando.value = false;
    }
  }


  // =========================================================================
  // VALIDAÇÕES
  // =========================================================================
  String? validarNome(String? v) => Validadores.obrigatorio(v, 'o nome');

  String? validarEmail(String? v) => Validadores.email(v);

  String? validarSenha(String? v) => Validadores.senha(v, minimo: 6);

  String? validarConfirmacao(String? v) =>
      Validadores.confirmaSenha(senhaCtrl.text, v);

  String? validarCpf(String? v) => Validadores.cpf(v);

  String? validarTelefone(String? v) => Validadores.telefone(v);
}
