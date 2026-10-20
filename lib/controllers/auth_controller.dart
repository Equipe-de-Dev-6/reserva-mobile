import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/middleware.dart';
import '../app/rotas.dart';
import '../core/servicos/api_client.dart';
import '../core/servicos/auth_service.dart';
import '../core/servicos/sessao_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/text_controllers.dart';
import '../core/utils/validadores.dart';
import '../models/auth_requests.dart';
import '../models/resultado_diagnostico.dart';

/// Controller do módulo de autenticação (RF01 a RF04).
///
/// Ele concentra o *estado da tela* (carregando, erro, etapa atual) e a
/// *regra de negócio da tela* (validar, chamar a API, rotear). A View
/// apenas desenha o que este Controller expõe.
///
/// Sobre as FormKeys: elas NÃO ficam aqui de propósito. Uma GlobalKey
/// pertence a uma View, porque só ela sabe quando aquele `Form` sai da
/// árvore. Se o Controller a guardasse, duas instâncias da mesma tela
/// (o que acontece durante uma transição de rota) usariam a mesma key e
/// o Flutter lançaria "Duplicate GlobalKey". O que fica aqui são as
/// *regras* de validação; a View passa o `FormState` do seu formulário.
class AuthController extends GetxController {
  AuthController(this._authService);

  final AuthService _authService;

  // --- Estado reativo ---------------------------------------------------

  /// Aparece o spinner e desabilita os botões durante a chamada HTTP.
  final RxBool carregando = false.obs;

  /// Mensagem de erro exibida dentro do formulário.
  final RxString erro = ''.obs;

  /// Mensagem de sucesso (usada na recuperação de senha).
  final RxString aviso = ''.obs;

  /// `true` durante a verificação de conexão com a API.
  final RxBool verificandoConexao = false.obs;

  /// Resultado da última verificação de conexão (null = nunca feita).
  ///
  /// Aparece na tela de Login para dizer **qual endereço** o app está
  /// usando e se a API respondeu — é o que resolve o "não foi possível
  /// conectar ao servidor" na hora, sem precisar abrir o terminal.
  final Rxn<ResultadoDiagnostico> diagnostico =
      Rxn<ResultadoDiagnostico>();

  // --- Campos de Login (RF01) -------------------------------------------

  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  final senhaOculta = true.obs;

  // --- Campos de Cadastro de Coordenador (RF02) --------------------------

  final nomeCtrl = TextEditingController();
  final cadastroEmailCtrl = TextEditingController();
  final cadastroSenhaCtrl = TextEditingController();
  final confirmarSenhaCtrl = TextEditingController();
  final departamentoCtrl = TextEditingController();
  final telefoneCtrl = TextEditingController();
  final cpfCtrl = TextEditingController();
  final cadastroSenhaOculta = true.obs;

  // --- Campos da Recuperação de senha em 3 etapas (RF03) -----------------

  final recuperacaoEmailCtrl = TextEditingController();
  final codigoCtrl = TextEditingController();
  final novaSenhaCtrl = TextEditingController();
  final novaSenhaConfirmarCtrl = TextEditingController();
  final novaSenhaOculta = true.obs;

  /// 0 = e-mail · 1 = código · 2 = nova senha
  final RxInt etapaRecuperacao = 0.obs;

  /// E-mail usado na recuperação, repassado entre as etapas.
  String _emailRecuperacao = '';

  @override
  void onClose() {
    // Os campos são **limpos**, não descartados — ver
    // `core/utils/text_controllers.dart` para o porquê (descartar
    // aqui derrubava a tela de Login com "A TextEditingController was
    // used after being disposed").
    limparCampos([
      emailCtrl,
      senhaCtrl,
      nomeCtrl,
      cadastroEmailCtrl,
      cadastroSenhaCtrl,
      confirmarSenhaCtrl,
      departamentoCtrl,
      telefoneCtrl,
      cpfCtrl,
      recuperacaoEmailCtrl,
      codigoCtrl,
      novaSenhaCtrl,
      novaSenhaConfirmarCtrl,
    ]);
    super.onClose();
  }

  // =========================================================================
  // RF01 — LOGIN
  // =========================================================================
  Future<void> login(FormState formulario) async {
    _limparMensagens();
    if (!formulario.validate()) return;

    // A validação vive **também** no Controller: se a tela esquecer de
    // ligar o `validator` em algum campo, o dado inválido não chega na
    // API (e o login não gasta uma requisição à toa).
    final erroEmail = validarEmailLogin(emailCtrl.text);
    if (erroEmail != null) {
      erro.value = erroEmail;
      return;
    }

    final erroSenha = validarSenhaLogin(senhaCtrl.text);
    if (erroSenha != null) {
      erro.value = erroSenha;
      return;
    }

    carregando.value = true;
    try {
      final resposta = await _authService.login(
        emailCtrl.text.trim(),
        senhaCtrl.text,
      );

      // Persistência segura do JWT + perfil antes de navegar.
      final sessao = Get.find<SessaoService>();
      await sessao.salvar(
        token: resposta.token,
        refreshToken: resposta.refreshToken,
        usuario: resposta.usuario,
      );

      // Roteamento condicional conforme a role (admin x professor).
      Get.offAllNamed(rotaPorSessao(sessao));
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }


  // =========================================================================
  // RF02 — CADASTRO DE COORDENADOR (RN01)
  // =========================================================================
  Future<void> cadastrarCoordenador(FormState formulario) async {
    _limparMensagens();
    if (!formulario.validate()) return;

    // Mesma política: nome, e-mail, senha e a confirmação são
    // validados aqui também.
    final erroNome = validarNome(nomeCtrl.text);
    if (erroNome != null) {
      erro.value = erroNome;
      return;
    }

    final erroEmail = validarEmailCadastro(cadastroEmailCtrl.text);
    if (erroEmail != null) {
      erro.value = erroEmail;
      return;
    }

    final erroSenha = validarSenhaCadastro(cadastroSenhaCtrl.text);
    if (erroSenha != null) {
      erro.value = erroSenha;
      return;
    }

    final erroConfirmacao = validarConfirmacao(confirmarSenhaCtrl.text);
    if (erroConfirmacao != null) {
      erro.value = erroConfirmacao;
      return;
    }

    carregando.value = true;
    try {
      await _authService.cadastrarCoordenador(
        CadastroAdminRequestModel(
          nome: nomeCtrl.text,
          email: cadastroEmailCtrl.text.trim(),
          senha: cadastroSenhaCtrl.text,
          departamento: departamentoCtrl.text,
          telefone: telefoneCtrl.text,
          cpf: cpfCtrl.text,
        ),
      );

      // Reaproveita o e-mail no formulário de login para facilitar.
      emailCtrl.text = cadastroEmailCtrl.text.trim();
      Get.offNamed(Rotas.login);
      Get.snackbar(
        'Cadastro realizado',
        'Coordenador cadastrado! Faça login para continuar.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1B8A5A),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }


  // =========================================================================
  // RF03 — RECUPERAÇÃO DE SENHA
  // =========================================================================

  /// Etapa 1: envia o e-mail e recebe o código de 6 dígitos.
  Future<void> solicitarCodigo(FormState formulario) async {
    _limparMensagens();
    if (!formulario.validate()) return;

    // Mesma política do resto do projeto: a regra mora **também** no
    // Controller, e não só no `Form` da View. Se a tela esquecer de
    // ligar o `validator` em algum campo, o dado inválido não chega na
    // API.
    final erroEmail = validarEmailLogin(recuperacaoEmailCtrl.text);
    if (erroEmail != null) {
      erro.value = erroEmail;
      return;
    }

    carregando.value = true;
    try {
      _emailRecuperacao = recuperacaoEmailCtrl.text.trim();
      final resposta = await _authService.solicitarCodigo(_emailRecuperacao);
      aviso.value = resposta.mensagem;
      etapaRecuperacao.value = 1;
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Etapa 2: valida o código recebido.
  Future<void> verificarCodigo(FormState formulario) async {
    _limparMensagens();
    if (!formulario.validate()) return;

    // O código tem exatamente 6 dígitos — validado aqui também, e não
    // só pelo `Form`.
    final erroCodigo = validarCodigo(codigoCtrl.text);
    if (erroCodigo != null) {
      erro.value = erroCodigo;
      return;
    }

    carregando.value = true;
    try {
      await _authService.verificarCodigo(_emailRecuperacao, codigoCtrl.text);
      aviso.value = 'Código validado. Defina a nova senha.';
      etapaRecuperacao.value = 2;
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Etapa 3: grava a nova senha.
  Future<void> redefinirSenha(FormState formulario) async {
    _limparMensagens();
    if (!formulario.validate()) return;

    // A senha nova é validada aqui também (mínimo de 6 caracteres e
    // confirmação igual à digitada).
    final erroSenha = validarNovaSenha(novaSenhaCtrl.text);
    if (erroSenha != null) {
      erro.value = erroSenha;
      return;
    }

    final erroConfirmacao = validarConfirmacaoNovaSenha(novaSenhaConfirmarCtrl.text);
    if (erroConfirmacao != null) {
      erro.value = erroConfirmacao;
      return;
    }

    carregando.value = true;
    try {
      await _authService.redefinirSenha(
        email: _emailRecuperacao,
        codigo: codigoCtrl.text,
        novaSenha: novaSenhaCtrl.text,
      );

      _limparRecuperacao();
      Get.offNamed(Rotas.login);
      Get.snackbar(
        'Senha redefinida',
        'Agora você pode entrar com a nova senha.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1B8A5A),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Volta uma etapa (mantendo o e-mail digitado).
  void etapaAnterior() {
    if (etapaRecuperacao.value > 0) {
      etapaRecuperacao.value -= 1;
      _limparMensagens();
    }
  }

  void _limparRecuperacao() {
    etapaRecuperacao.value = 0;
    recuperacaoEmailCtrl.clear();
    codigoCtrl.clear();
    novaSenhaCtrl.clear();
    novaSenhaConfirmarCtrl.clear();
    _limparMensagens();
  }

  void _limparMensagens() {
    erro.value = '';
    aviso.value = '';
  }


  // =========================================================================
  // DIAGNÓSTICO DE CONEXÃO
  // =========================================================================

  /// Verifica se a API está de pé e guarda o resultado em [diagnostico].
  ///
  /// É o botão "Verificar conexão" da tela de Login: em vez de só dizer
  /// que não conectou, o app mostra **qual endereço** tentou e o que a
  /// API respondeu.
  Future<void> verificarConexao() async {
    verificandoConexao.value = true;
    try {
      diagnostico.value = await Get.find<ApiClient>().verificarConexao();
    } finally {
      verificandoConexao.value = false;
    }
  }

  // =========================================================================
  // RF04 — LOGOUT
  // =========================================================================
  Future<void> logout() async {
    carregando.value = true;
    try {
      // Invalida o refresh token no servidor. Uma falha aqui não pode
      // impedir a saída do usuário do aparelho.
      await _authService.logout();
    } catch (_) {
      // Ignorado de propósito: o logout local é obrigatório.
    } finally {
      await Get.find<SessaoService>().limpar();
      carregando.value = false;
      Get.offAllNamed(Rotas.login);
    }
  }

  // =========================================================================
  // VALIDAÇÕES
  // Expostas publicamente porque são passadas como `validator:` nas Views.
  // Ficarem no Controller (e não na View) mantém a regra de validação em um
  // único lugar, mesmo que o layout da tela mude.
  // =========================================================================
  String? validarEmailLogin(String? v) => Validadores.email(v);

  String? validarSenhaLogin(String? v) => Validadores.senha(v);

  String? validarNome(String? v) => Validadores.obrigatorio(v, 'o nome');

  String? validarEmailCadastro(String? v) => Validadores.email(v);

  String? validarSenhaCadastro(String? v) => Validadores.senha(v, minimo: 6);

  String? validarConfirmacao(String? v) =>
      Validadores.confirmaSenha(cadastroSenhaCtrl.text, v);

  String? validarCpf(String? v) => Validadores.cpf(v);

  String? validarTelefone(String? v) => Validadores.telefone(v);

  String? validarCodigo(String? v) {
    final valor = v?.trim() ?? '';
    if (valor.isEmpty) return 'Informe o código.';
    if (valor.length != 6) return 'O código tem 6 dígitos.';
    return null;
  }

  String? validarNovaSenha(String? v) => Validadores.senha(v, minimo: 6);

  String? validarConfirmacaoNovaSenha(String? v) =>
      Validadores.confirmaSenha(novaSenhaCtrl.text, v);
}
