import 'package:get/get.dart';

import 'bindings.dart';
import 'middleware.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/cadastro_admin_view.dart';
import '../views/auth/recuperar_senha_view.dart';
import '../views/admin/admin_home_view.dart';
import '../views/admin/professores/professores_lista_view.dart';
import '../views/admin/professores/professor_cadastro_view.dart';
import '../views/admin/professores/professor_detalhe_view.dart';
import '../views/perfil/perfil_view.dart';
import '../views/professor/professor_home_view.dart';

/// Nomes das rotas. Nunca use strings soltas no `Get.toNamed`:
/// um erro de digitação quebraria a navegação silenciosamente.
class Rotas {
  Rotas._();

  static const splash = '/';
  static const login = '/login';
  static const cadastroAdmin = '/cadastro-admin';
  static const recuperarSenha = '/recuperar-senha';
  static const homeAdmin = '/admin/home';
  static const homeProfessor = '/professor/home';

  // --- Módulo 2: gestão de professores (RF06) --------------------------
  static const professores = '/admin/professores';
  static const professorNovo = '/admin/professores/novo';

  /// Rota com parâmetro: use `'$professorDetalhe/$id'`. O `:id` é lido
  /// pelo Controller via `Get.parameters`.
  static const professorDetalhe = '/admin/professores/detalhe/:id';

  /// Monta a rota do detalhe de um professor.
  static String detalheDeProfessor(int id) => '/admin/professores/detalhe/$id';

  // --- Módulo 3: perfil (RF09) -----------------------------------------
  /// Liberada para admin e professor: o RN06 dá autonomia ao docente
  /// sobre os próprios dados.
  static const perfil = '/perfil';
}

/// Mapa de navegação nomeada da aplicação.
///
/// Cada `GetPage` reúne quatro responsabilidades:
///  * `name`        — identificador único da rota
///  * `page`        — a View (widget) correspondente
///  * `binding`     — injeção de dependências exclusiva daquela tela
///  * `middlewares` — guardas de acesso à rota
class AppRotas {
  AppRotas._();

  /// Duração padrão das transições entre telas (RNF01).
  static const Duration _transicao = Duration(milliseconds: 280);

  static final List<GetPage> paginas = [
    GetPage(
      name: Rotas.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),

    // Telas de autenticação: só para quem ainda NÃO tem sessão.
    GetPage(
      name: Rotas.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      middlewares: [AnonimoMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _transicao,
    ),
    GetPage(
      name: Rotas.cadastroAdmin,
      page: () => const CadastroAdminView(),
      binding: AuthBinding(),
      middlewares: [AnonimoMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),
    GetPage(
      name: Rotas.recuperarSenha,
      page: () => const RecuperarSenhaView(),
      binding: AuthBinding(),
      middlewares: [AnonimoMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),

    // Telas internas: exigem sessão válida.
    GetPage(
      name: Rotas.homeAdmin,
      page: () => const AdminHomeView(),
      binding: AuthBinding(),
      middlewares: [AutenticadoMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _transicao,
    ),
    GetPage(
      name: Rotas.homeProfessor,
      page: () => const ProfessorHomeView(),
      binding: AuthBinding(),
      middlewares: [AutenticadoMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _transicao,
    ),

    // Módulo 2 — gestão de professores (RF06).
    // Exclusivas do Coordenador: `AutenticadoMiddleware` garante a sessão
    // e `AdminMiddleware` o papel (RN03 — o docente não gerencia nada).
    GetPage(
      name: Rotas.professores,
      page: () => const ProfessoresListaView(),
      binding: ProfessorBinding(),
      middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),
    GetPage(
      name: Rotas.professorNovo,
      page: () => const ProfessorCadastroView(),
      binding: ProfessorBinding(),
      middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),
    GetPage(
      name: Rotas.professorDetalhe,
      page: () => const ProfessorDetalheView(),
      binding: ProfessorBinding(),
      middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),

    // Módulo 3 — Perfil (RF09). Aberta para os dois papéis.
    GetPage(
      name: Rotas.perfil,
      page: () => const PerfilView(),
      binding: PerfilBinding(),
      middlewares: [AutenticadoMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),
  ];
}
