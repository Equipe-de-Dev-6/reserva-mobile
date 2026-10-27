import 'package:get/get.dart';

import '../app/rotas.dart';
import '../core/servicos/admin_service.dart';
import '../core/utils/app_exception.dart';
import '../models/usuario_admin_model.dart';

/// Controller da tela de usuários do sistema (Parte 6).
///
/// Ele concentra o estado da tela (carregando, erro, termo de busca) e
/// as duas regras de negócio: o recorte por busca sobre a lista de
/// usuários e a alteração de papel — que é uma operação de elevação de
/// privilégio e por isso exige confirmação explícita na View.
class AdminUsuariosController extends GetxController {
  AdminUsuariosController(this._service);

  final AdminService _service;

  // --- Estado reativo ---------------------------------------------------

  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  /// Corpo completo devolvido por `GET /admin/users`.
  final RxList<UsuarioAdminModel> usuarios = <UsuarioAdminModel>[].obs;

  /// Texto digitado na busca.
  final RxString busca = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  // ========================================================================
  // CARREGAMENTO
  // ========================================================================
  Future<void> carregar() async {
    carregando.value = true;
    erro.value = '';

    try {
      usuarios.assignAll(await _service.listarUsuarios());
    } on AppException catch (e) {
      erro.value = e.mensagem;
    } finally {
      carregando.value = false;
    }
  }

  /// Recarrega mantendo o termo de busca.
  Future<void> recarregar() => carregar();

  // ========================================================================
  // BUSCA LOCAL (o endpoint não aceita filtro)
  // ========================================================================
  void filtrar(String termo) {
    busca.value = termo;
  }

  /// Resultado da busca sobre a lista completa.
  ///
  /// É um getter, não um estado: derivar é mais seguro que duplicar.
  List<UsuarioAdminModel> get resultados {
    final termo = busca.value;
    if (termo.trim().isEmpty) return List.unmodifiable(usuarios);

    return List.unmodifiable(
      usuarios.where((u) => u.correspondeAoTermo(termo)),
    );
  }

  // ========================================================================
  // ALTERAÇÃO DE PAPEL (elevação de privilégio)
  // ========================================================================
  /// `true` apenas quando a requisição deu certo. Em caso de erro, a
  /// mensagem fica em [erro] e a tela **não** fecha — o usuário decide o
  /// que fazer depois de ler.
  Future<bool> alterarPapel(int id, String novoPapel) async {
    carregando.value = true;
    erro.value = '';

    try {
      await _service.alterarPapel(id, novoPapel);
      carregando.value = false;
      return true;
    } on AppException catch (e) {
      carregando.value = false;
      erro.value = e.mensagem;
      return false;
    }
  }

  // ========================================================================
  // INDICADORES
  // ========================================================================
  int get totalUsuarios => usuarios.length;

  int get totalAdmins => usuarios.where((u) => u.isAdmin).length;

  int get totalProfessores => usuarios.where((u) => u.isProfessor).length;

  bool get buscaSemResultado =>
      usuarios.isNotEmpty && resultados.isEmpty;
}

extension _UsuarioAdminBusca on UsuarioAdminModel {
  /// Filtro de busca da listagem (Parte 6).
  ///
  /// O endpoint `GET /admin/users` não aceita parâmetro de busca, então
  /// o recorte é feito no aparelho. A regra fica no Model — e não na
  /// View — para poder ser testada sem montar widget.
  bool correspondeAoTermo(String termo) {
    final alvo = termo.trim().toLowerCase();
    if (alvo.isEmpty) return true;

    return nome.toLowerCase().contains(alvo) ||
        email.toLowerCase().contains(alvo) ||
        matricula.toLowerCase().contains(alvo) ||
        departamento.toLowerCase().contains(alvo) ||
        telefone.toLowerCase().contains(alvo);
  }
}
