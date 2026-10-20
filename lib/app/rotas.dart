import 'package:get/get.dart';

import 'bindings.dart';
import 'middleware.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/cadastro_admin_view.dart';
import '../views/auth/recuperar_senha_view.dart';
import '../views/admin/admin_home_view.dart';
import '../views/admin/dashboard_view.dart';
import '../views/admin/professores/professores_lista_view.dart';
import '../views/admin/professores/professor_cadastro_view.dart';
import '../views/admin/professores/professor_detalhe_view.dart';
import '../views/perfil/perfil_view.dart';
import '../views/patrimonio/rotas_patrimonio.dart';
import '../views/professor/meus_patrimonios_view.dart';
import '../views/professor/professor_home_view.dart';
import '../views/professor/rotas_professor.dart';

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

  // --- Módulo 2: dashboard de indicadores (RF05) -------------------------
  /// Exclusivo do Coordenador: `GET /admin/patrimonios/stats` responde
  /// `403` para qualquer outro papel.
  static const dashboard = '/admin/dashboard';

  // --- Módulo 2: gestão de professores (RF06) --------------------------
  static const professores = '/admin/professores';
  static const professorNovo = '/admin/professores/novo';

  /// Rota com parâmetro: use `'$professorDetalhe/$id'`. O `:id` é lido
  /// pelo Controller via `Get.parameters`.
  static const professorDetalhe = '/admin/professores/detalhe/:id';

  /// Monta a rota do detalhe de um professor.
  static String detalheDeProfessor(int id) => '/admin/professores/detalhe/$id';

  // --- Módulo 3: meus patrimônios (RF08) --------------------------------
  /// Tela de leitura do docente.
  static const meusPatrimonios = '/professor/meus-patrimonios';

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

    // Módulo 2 — dashboard de indicadores (RF05).
    // Exclusivo do Coordenador: o backend exige papel de admin.
    GetPage(
      name: Rotas.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AutenticadoMiddleware(), AdminMiddleware()],
      transition: Transition.rightToLeftWithFade,
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

    // Módulo 3 — "Meus Patrimônios" (RF08).
    // Aberta para os dois papéis: o|Coordenador não tem bens
    // vinculados, então a tela mostra o estado vazio — mas a rota fica
    // disponível para o docente (RN03, leitura estrita).
    GetPage(
      name: Rotas.meusPatrimonios,
      page: () => const MeusPatrimoniosView(),
      binding: MeusPatrimoniosBinding(),
      middlewares: [AutenticadoMiddleware()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _transicao,
    ),

    // Módulo 3 — ficha do bem em modo leitura (RF08).
    // O card de "Meus Patrimônios" navega para cá; nenhuma ação de
    // escrita existe na tela seguinte (RN03).
    ...paginasProfessor,

    // Módulo 2 — Patrimônios (RF07a/RF07b).
    //
    // As páginas do módulo vêm prontas do seu próprio arquivo
    // (`views/patrimonio/rotas_patrimonio.dart`), para que o módulo
    // entre no app sem mexer em código de terceiros.
    ...paginasPatrimonio,
  ];
}
