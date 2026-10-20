import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/patrimonio_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/text_controllers.dart';
import '../core/utils/validadores.dart';
import '../models/patrimonio_model.dart';
import '../models/status_patrimonio.dart';

/// Estado e regras do **formulário de patrimônio** (RF07a).
///
/// Serve às duas telas que usam o mesmo formulário:
///  * cadastro (`PatrimonioFormView` com `patrimonio == null`);
///  * edição (`PatrimonioFormView` com um bem já carregado).
///
/// Os campos são preenchidos a partir do [patrimonio] recebido, o que
/// evita `TextEditingController(text: ...)` — que só vale na primeira
/// construção do State e não atualiza quando o Model muda.
class PatrimonioFormController extends GetxController {
  PatrimonioFormController(this._service);

  final PatrimonioService _service;

  /// Bem em edição. `null` = cadastro.
  ///
  /// Vem de `Get.arguments` e é lido em [onInit]. Deixar a leitura para
  /// cá (e não para a View) evita o problema clássico do Controller
  /// nasce-antes-de-a-View-configurar: aqui a View só navega, e o
  /// Controller se resolve sozinho, como os demais do projeto.
  PatrimonioModel? patrimonio;

  final RxBool salvando = false.obs;
  final RxString erro = ''.obs;

  /// Bem gravado com sucesso, disponível depois do [salvar].
  ///
  /// Fica separado do retorno porque cadastro e edição têm resultados
  /// diferentes: o `PUT` devolve o bem inteiro, enquanto o `POST` devolve
  /// só o id. A View precisa responder a duas perguntas — "foi salvo?" e
  /// "com o quê?" — e um único `null` não dá conta das duas sem ambiguidade.
  final Rxn<PatrimonioModel> gravado = Rxn<PatrimonioModel>();

  /// Confirmação do cadastro devolvida pelo backend.
  final RxString mensagemSucesso = ''.obs;

  final TextEditingController codigoCtrl = TextEditingController();
  final TextEditingController nomeCtrl = TextEditingController();
  final TextEditingController descricaoCtrl = TextEditingController();
  final TextEditingController marcaCtrl = TextEditingController();
  final TextEditingController modeloCtrl = TextEditingController();
  final TextEditingController numeroSerieCtrl = TextEditingController();
  final TextEditingController localizacaoCtrl = TextEditingController();
  final TextEditingController observacoesCtrl = TextEditingController();

  /// Categoria e estado de conservação vêm de listas fixas — o backend
  /// não expõe catálogos para eles (ver `patrimonio_service.dart`).
  final RxString categoria = ''.obs;
  final RxString estadoConservacao = ''.obs;

  bool get editando => patrimonio != null;

  String get titulo => editando ? 'Editar patrimônio' : 'Novo patrimônio';

  /// Texto do botão de confirmação.
  String get textoBotao => editando ? 'Salvar alterações' : 'Cadastrar bem';

  /// O tombamento não muda depois do cadastro, então em edição o campo
  /// é apenas leitura — desabilitado, e não editável-com-esconderijo.
  bool get codigoBloqueado => editando;

  @override
  void onInit() {
    super.onInit();

    // A View só navega; quem descobre o modo é o Controller.
    if (patrimonio == null) {
      final argumentos = Get.arguments;
      if (argumentos is PatrimonioModel) {
        patrimonio = argumentos;
      } else if (argumentos is Map) {
        final candidato = argumentos['patrimonio'];
        if (candidato is PatrimonioModel) patrimonio = candidato;
      }
    }

    _preencherCampos();
  }

  void _preencherCampos() {
    final p = patrimonio;
    if (p == null) return;

    codigoCtrl.text = p.codigo;
    nomeCtrl.text = p.nome;
    descricaoCtrl.text = p.descricao;
    marcaCtrl.text = p.marca;
    modeloCtrl.text = p.modelo;
    numeroSerieCtrl.text = p.numeroSerie ?? '';
    localizacaoCtrl.text = p.localizacao;
    observacoesCtrl.text = p.observacoes;
    categoria.value = p.categoria;
    estadoConservacao.value = p.estadoConservacao;
  }

  @override
  void onClose() {
    // Limpa, em vez de descartar (ver `core/utils/text_controllers.dart`).
    limparCampos([
      codigoCtrl,
      nomeCtrl,
      descricaoCtrl,
      marcaCtrl,
      modeloCtrl,
      numeroSerieCtrl,
      localizacaoCtrl,
      observacoesCtrl,
    ]);
    super.onClose();
  }

  // -------------------------------------------------------------------------
  // Validações
  //
  // Expostas publicamente porque são passadas como `validator:` nas
  // Views. Ficarem aqui mantém a regra em um único lugar, mesmo que o
  // layout do formulário mude.
  // -------------------------------------------------------------------------

  /// O tombamento é a identidade do bem e o backend rejeita duplicado
  /// com 409 — a validação local só cobre o formato.
  String? validarCodigo(String? valor) =>
      Validadores.obrigatorio(valor, 'o código de tombamento');

  String? validarNome(String? valor) => Validadores.obrigatorio(valor, 'o nome do bem');

  String? validarNumeroSerie(String? valor) {
    final v = valor?.trim() ?? '';
    // Opcional, mas quando informado não pode ter espaço no meio —
    // é etiqueta física, não texto livre.
    if (v.contains(' ')) return 'O número de série não pode conter espaços.';
    return null;
  }

  // -------------------------------------------------------------------------
  // Envio
  // -------------------------------------------------------------------------

  /// Valida, envia e informa se a gravação aconteceu.
  ///
  /// Devolve `false` quando a validação local barrou o envio **ou** quando
  /// a API falhou — nos dois casos o motivo fica em [erro] (ou nos campos,
  /// no caso da validação) e a tela **não** deve navegar.
  ///
  /// Esse retorno é o que impede o erro clássico de fechar a tela com a
  /// mensagem "cadastrado" quando, na verdade, nada foi gravado.
  Future<bool> salvar(FormState formulario) async {
    erro.value = '';
    gravado.value = null;
    mensagemSucesso.value = '';

    // Validação local barrou: nada foi enviado e a tela permanece aberta
    // para o usuário corrigir.
    if (!formulario.validate()) return false;

    salvando.value = true;
    try {
      if (editando) {
        final atualizado = _modeloAtualizado();
        await _service.atualizar(patrimonio!.id, atualizado);
        gravado.value = atualizado;
        return true;
      }

      final novo = _modeloNovo();
      final criacao = await _service.criar(novo);
      // O `POST` não devolve o bem completo (só o id), mas o Model que foi
      // enviado serve de retorno para a tela querer reabrir o detalhe.
      gravado.value = novo;
      mensagemSucesso.value = criacao.mensagem;
      return true;
    } on AppException catch (e) {
      erro.value = e.mensagem;
      return false;
    } finally {
      salvando.value = false;
    }
  }

  /// Monta o Model do formulário preservando o que o usuário não edita:
  /// `id`, `status` e o vínculo com o professor.
  ///
  /// Este detalhe importa: se o formulário recriasse o Model só com os
  /// campos visíveis, salvar uma edição poderia enviar `professorId`
  /// vazio e desvincular o bem do docente.
  PatrimonioModel _modeloAtualizado() {
    final atual = patrimonio!;
    return PatrimonioModel(
      id: atual.id,
      codigo: atual.codigo,
      nome: nomeCtrl.text.trim(),
      descricao: descricaoCtrl.text.trim(),
      categoria: categoria.value,
      marca: marcaCtrl.text.trim(),
      modelo: modeloCtrl.text.trim(),
      numeroSerie: numeroSerieCtrl.text.trim(),
      estadoConservacao: estadoConservacao.value,
      localizacao: localizacaoCtrl.text.trim(),
      status: atual.status,
      adminId: atual.adminId,
      professorId: atual.professorId,
      professorNome: atual.professorNome,
      professorEmail: atual.professorEmail,
      dataAtribuicao: atual.dataAtribuicao,
      observacoes: observacoesCtrl.text.trim(),
      createdAt: atual.createdAt,
      updatedAt: atual.updatedAt,
    );
  }

  PatrimonioModel _modeloNovo() {
    return PatrimonioModel(
      // `id` é zerado porque o cadastro é sempre "disponível" — o
      // servidor define o id e o status inicial.
      id: 0,
      codigo: codigoCtrl.text.trim().toUpperCase(),
      nome: nomeCtrl.text.trim(),
      descricao: descricaoCtrl.text.trim(),
      categoria: categoria.value,
      marca: marcaCtrl.text.trim(),
      modelo: modeloCtrl.text.trim(),
      numeroSerie: numeroSerieCtrl.text.trim(),
      estadoConservacao: estadoConservacao.value,
      localizacao: localizacaoCtrl.text.trim(),
      status: StatusPatrimonio.disponivel,
      observacoes: observacoesCtrl.text.trim(),
    );
  }
}
