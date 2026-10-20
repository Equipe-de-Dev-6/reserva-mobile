import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/servicos/perfil_service.dart';
import '../core/servicos/sessao_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/text_controllers.dart';
import '../core/utils/validadores.dart';
import '../models/perfil_request.dart';
import '../models/usuario_model.dart';

/// Controller da tela de Perfil (RF09 / RN06).
///
/// A tela tem dois blocos independentes e eles não se misturam:
///
///  * **Dados cadastrais** — `GET /profile` na abertura e `PUT /profile`
///    para salvar. O RN06 dá ao docente autonomia sobre telefone e
///    contato, então não há restrição por role aqui.
///  * **Senha** — a troca também vai para `PUT /profile`, mas na chave
///    `newPassword`. Ela é enviada sozinha, para que uma falha ao trocar
///    a senha não derrube a atualização dos dados.
class PerfilController extends GetxController {
  PerfilController(this._perfilService, this._sessao);

  final PerfilService _perfilService;
  final SessaoService _sessao;

  // --- Estado reativo ---------------------------------------------------

  /// `true` durante o `GET /profile` inicial.
  final RxBool carregando = false.obs;

  /// `true` durante qualquer `PUT /profile`.
  final RxBool salvando = false.obs;

  final RxString erro = ''.obs;
  final RxString aviso = ''.obs;

  /// Erro do **último `GET /profile`**.
  ///
  /// Fica separado do [erro] da edição de propósito: abrir o formulário
  /// limpa a mensagem do formulário, mas isso não pode apagar a falha de
  /// carregamento — é ela que explica por que os campos estão vazios.
  final RxString erroCarregamento = ''.obs;

  /// `true` quando o formulário de dados está aberto (a tela começa
  /// mostrando os dados, como pede o RF09).
  final RxBool editando = false.obs;

  /// `true` quando o formulário de nova senha está aberto. Fica
  /// recolhido por padrão para não competir com os dados cadastrais.
  final RxBool editandoSenha = false.obs;

  /// Snapshot do perfil no momento em que o formulário foi aberto.
  /// É a referência para descobrir **o que mudou** e para o botão
  /// "Descartar" voltar ao estado do servidor.
  UsuarioModel? _original;

  final Rxn<UsuarioModel> perfil = Rxn<UsuarioModel>();

  // --- Campos de dados cadastrais ---------------------------------------

  final nomeCtrl = TextEditingController();
  final telefoneCtrl = TextEditingController();
  final departamentoCtrl = TextEditingController();
  final enderecoCtrl = TextEditingController();
  final cidadeUfCtrl = TextEditingController();
  final contatoEmergenciaCtrl = TextEditingController();

  // --- Campos de senha (RF09) -------------------------------------------

  final novaSenhaCtrl = TextEditingController();
  final confirmarSenhaCtrl = TextEditingController();
  final senhaOculta = true.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  @override
  void onClose() {
    // Limpa, em vez de descartar (ver `core/utils/text_controllers.dart`).
    // Esvaziar garante que nenhum dado de contato nem a senha fiquem
    // pendurados na memória depois que a tela sai — e descartar aqui
    // derrubaria a tela com "A TextEditingController was used after
    // being disposed".
    limparCampos([
      nomeCtrl,
      telefoneCtrl,
      departamentoCtrl,
      enderecoCtrl,
      cidadeUfCtrl,
      contatoEmergenciaCtrl,
      novaSenhaCtrl,
      confirmarSenhaCtrl,
    ]);
    super.onClose();
  }

  // =========================================================================
  // GET /profile — dados cadastrais
  // =========================================================================
  Future<void> carregar() async {
    carregando.value = true;
    erro.value = '';

    try {
      final dados = await _perfilService.meuPerfil();
      perfil.value = dados;
      _original = dados;
      erroCarregamento.value = '';
      _preencherCampos(dados);
    } on AppException catch (e) {
      erro.value = e.mensagem;
      erroCarregamento.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  // =========================================================================
  // PUT /profile — dados cadastrais
  // =========================================================================
  void abrirEdicao() {
    erro.value = '';
    aviso.value = '';
    editando.value = true;
  }

  void fecharEdicao() {
    erro.value = '';
    aviso.value = '';
    editando.value = false;

    // Descartar edição devolve os campos ao valor do servidor.
    final base = _original;
    if (base != null) _preencherCampos(base);
  }

  Future<void> salvarDados(FormState formulario) async {
    erro.value = '';
    aviso.value = '';
    if (!formulario.validate()) return;

    // Perfil ainda não carregado (a chamada anterior falhou): a mensagem
    // de erro do `GET` é mais útil do que uma validação de campo — os
    // campos estão vazios porque não vieram.
    final original = _original;
    if (original == null) {
      erro.value = erroCarregamento.value.isEmpty
          ? 'Aguarde o carregamento dos dados antes de editar.'
          : erroCarregamento.value;
      return;
    }

    // A validação acontece **também** aqui, e não só no `Form` da View.
    // A regra fica no Controller (como em todo o resto do projeto) e a
    // tela não vira o único guardião dela: se a View esquecer de ligar o
    // `validator` em algum campo, o dado inválido não chega na API.
    final erroNome = validarNome(nomeCtrl.text);
    if (erroNome != null) {
      erro.value = erroNome;
      return;
    }

    final erroTelefone = validarTelefone(telefoneCtrl.text);
    if (erroTelefone != null) {
      erro.value = erroTelefone;
      return;
    }

    final request = _montarRequest(original);
    if (request.vazio) {
      // O backend responde 400 quando nenhum campo chega. Em vez de
      // enviar e tomar um erro, a tela avisa que não há o que salvar.
      aviso.value = 'Nenhum dado foi alterado.';
      return;
    }

    salvando.value = true;
    try {
      final atualizado = await _perfilService.atualizarDados(request);
      await _sincronizarSessao(atualizado);

      aviso.value = 'Dados atualizados com sucesso.';
      // Volta para a modo leitura já com os valores novos na tela.
      editando.value = false;
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      salvando.value = false;
    }
  }

  /// Monta o corpo só com o que mudou.
  ///
  /// O endpoint aplica apenas os campos presentes e devolve 400 se nenhum
  /// vier — enviar o formulário inteiro sobrescreveria dados que o
  /// usuário não tocou e geraria erro em "salvar sem mudar nada".
  AtualizarPerfilRequestModel _montarRequest(UsuarioModel original) {
    final nome = nomeCtrl.text.trim();
    final telefone = telefoneCtrl.text.trim();
    final departamento = departamentoCtrl.text.trim();
    final endereco = enderecoCtrl.text.trim();
    final cidadeUf = cidadeUfCtrl.text.trim();
    final contato = contatoEmergenciaCtrl.text.trim();

    return AtualizarPerfilRequestModel(
      nome: nome != original.nome ? nome : null,
      telefone: telefone != original.telefone ? telefone : null,
      departamento: departamento != original.departamento ? departamento : null,
      endereco: endereco != original.endereco ? endereco : null,
      cidadeUf: cidadeUf != original.cidadeUf ? cidadeUf : null,
      contatoEmergencia:
          contato != original.contatoEmergencia ? contato : null,
    );
  }

  // =========================================================================
  // PUT /profile — redefinição de senha
  // =========================================================================
  void abrirSenha() {
    erro.value = '';
    aviso.value = '';
    _limparCamposSenha();
    editandoSenha.value = true;
  }

  void fecharSenha() {
    erro.value = '';
    aviso.value = '';
    _limparCamposSenha();
    editandoSenha.value = false;
  }

  void alternarVisibilidadeSenha() => senhaOculta.toggle();

  Future<void> alterarSenha(FormState formulario) async {
    erro.value = '';
    aviso.value = '';
    if (!formulario.validate()) return;

    // Mesma política de [salvarDados]: a regra mora no Controller, e o
    // `Form` é só a primeira das barreiras.
    final erroSenha = validarNovaSenha(novaSenhaCtrl.text);
    if (erroSenha != null) {
      erro.value = erroSenha;
      return;
    }

    final erroConfirmacao = validarConfirmacaoSenha(confirmarSenhaCtrl.text);
    if (erroConfirmacao != null) {
      erro.value = erroConfirmacao;
      return;
    }

    salvando.value = true;
    try {
      final usuario = await _perfilService.alterarSenha(
        AlterarSenhaRequestModel(novaSenha: novaSenhaCtrl.text),
      );

      // A troca de senha não muda os dados exibidos, mas a resposta do
      // backend é o usuário atualizado: aproveitamos para reidratar a
      // sessão e manter tudo consistente.
      await _sincronizarSessao(usuario);

      _limparCamposSenha();
      aviso.value = 'Senha alterada com sucesso.';
    } on AppException catch (e) {
      // 400 aqui significa senha curta demais ou corpo vazio.
      erro.value = e.mensagem;
    } finally {
      salvando.value = false;
    }
  }

  void _limparCamposSenha() {
    novaSenhaCtrl.clear();
    confirmarSenhaCtrl.clear();
  }

  // =========================================================================
  // INTEGRAÇÃO COM A SESSÃO
  // =========================================================================

  /// Mantém o `SessaoService` em dia com o que o servidor respondeu.
  ///
  /// `CabecalhoUsuario` e o roteamento por role leem o perfil da sessão
  /// (RF01), então sem esta sincronização o nome/avatar continuariam
  /// mostrando o valor antigo até o próximo login.
  ///
  /// A sessão só é reescrita se a resposta trouxer o perfil completo; um
  /// objeto parcial preservaria o que já está em memória.
  Future<void> _sincronizarSessao(UsuarioModel atualizado) async {
    if (atualizado.nome.isEmpty && atualizado.email.isEmpty) return;

    // `PUT /profile` devolve `totalPatrimonios` zerado; o `GET` é a
    // fonte confiável desse contador. Quando a resposta do PUT vier com
    // ele zerado, reaproveitamos o valor que já conhecíamos.
    final anterior = perfil.value;
    final usuario = atualizado.totalPatrimonios == 0 &&
            anterior != null &&
            anterior.totalPatrimonios > 0
        ? atualizado.copyWith(
            totalPatrimonios: anterior.totalPatrimonios,
          )
        : atualizado;

    perfil.value = usuario;
    _original = usuario;
    _preencherCampos(usuario);
    await _sessao.atualizarUsuario(usuario);
  }

  // =========================================================================
  // CAMPOS
  // =========================================================================
  void _preencherCampos(UsuarioModel u) {
    nomeCtrl.text = u.nome;
    telefoneCtrl.text = u.telefone;
    departamentoCtrl.text = u.departamento;
    enderecoCtrl.text = u.endereco;
    cidadeUfCtrl.text = u.cidadeUf;
    contatoEmergenciaCtrl.text = u.contatoEmergencia;
  }

  // =========================================================================
  // VALIDAÇÕES
  // =========================================================================
  String? validarNome(String? v) => Validadores.obrigatorio(v, 'o nome');

  String? validarTelefone(String? v) => Validadores.telefone(v);

  String? validarNovaSenha(String? v) => Validadores.senha(v, minimo: 6);

  String? validarConfirmacaoSenha(String? v) =>
      Validadores.confirmaSenha(novaSenhaCtrl.text, v);
}
