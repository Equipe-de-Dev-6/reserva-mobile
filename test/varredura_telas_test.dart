// Varredura de **todas** as telas do aplicativo.
//
// Cada tela é montada com as widgets reais, nas dependências reais e
// em três tamanhos (iPhone 13, iPhone SE e a janela larga do Chrome),
// e a varredura exige que **nenhuma** delas estoure layout nem dispare
// exceção.
//
// É o queturned o bug do "A TextEditingController was used after being
// disposed" e o overflow da lista de professores em luz: os dois só
// apareciam em condições específicas de navegação e de tamanho de tela.
//
// Este arquivo não depende do backend: o `ApiClient` é substituído pelo
// dublê de `test/helpers/api_client_falso.dart`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/admin_usuarios_controller.dart';
import 'package:reserva_mobile/controllers/auth_controller.dart';
import 'package:reserva_mobile/controllers/dashboard_controller.dart';
import 'package:reserva_mobile/controllers/meus_patrimonios_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_ciclo_vida_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_detalhe_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_form_controller.dart';
import 'package:reserva_mobile/controllers/patrimonio_historico_controller.dart';
import 'package:reserva_mobile/controllers/perfil_controller.dart';
import 'package:reserva_mobile/controllers/professor_cadastro_controller.dart';
import 'package:reserva_mobile/controllers/professor_detalhe_controller.dart';
import 'package:reserva_mobile/controllers/professor_lista_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/admin_service.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/perfil_service.dart';
import 'package:reserva_mobile/core/servicos/professor_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/admin/admin_home_view.dart';
import 'package:reserva_mobile/views/admin/dashboard_view.dart';
import 'package:reserva_mobile/views/admin/usuarios/usuarios_lista_view.dart';
import 'package:reserva_mobile/views/admin/professores/professor_cadastro_view.dart';
import 'package:reserva_mobile/views/admin/professores/professor_detalhe_view.dart';
import 'package:reserva_mobile/views/admin/professores/professores_lista_view.dart';
import 'package:reserva_mobile/views/auth/cadastro_admin_view.dart';
import 'package:reserva_mobile/views/auth/login_view.dart';
import 'package:reserva_mobile/views/auth/recuperar_senha_view.dart';
import 'package:reserva_mobile/views/perfil/perfil_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_atribuicao_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_detalhe_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_devolucao_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_form_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_historico_view.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_lista_view.dart';
import 'package:reserva_mobile/views/professor/meus_patrimonios_view.dart';
import 'package:reserva_mobile/views/professor/professor_home_view.dart';
import 'package:reserva_mobile/widgets/estado_vazio.dart';

import 'helpers/api_client_falso.dart';
import 'helpers/test_armazenamento.dart';

/// Usuário do Coordenador.
final UsuarioModel admin = UsuarioModel(
  id: 1,
  nome: 'Coordenador Geral',
  email: 'admin@admin.com',
  role: 'admin',
);

/// Usuário docente.
final UsuarioModel docente = UsuarioModel(
  id: 2,
  nome: 'Prof. Carlos Drummond',
  email: 'professor@escola.com',
  role: 'professor',
);

/// Os três tamanhos usados na varredura.
const List<({String nome, Size tamanho})> tamanhos = [
  (nome: 'iPhone 13', tamanho: Size(390, 844)),
  (nome: 'iPhone SE', tamanho: Size(375, 667)),
  (nome: 'Chrome (1180x866)', tamanho: Size(1180, 866)),
];

/// Monta uma tela com todas as dependências registradas.
Future<void> montar(
  WidgetTester tester,
  Widget Function() tela, {
  required UsuarioModel usuario,
}) async {
  final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
  sessao.usuario.value = usuario;

  final api = Get.put<ApiClient>(apiFalsaDoTeste(), permanent: true);

  // O grafo inteiro de dependências, para que toda tela possa ser
  // montada isoladamente — é o mesmo grafo que os `Bindings` montam em
  // produção.
  final patrimonio = PatrimonioService(api);
  Get.put<PatrimonioService>(patrimonio, permanent: true);
  Get.put<AuthService>(AuthService(api, sessao), permanent: true);
  Get.put<AuthController>(AuthController(Get.find<AuthService>()));
  Get.put<DashboardController>(DashboardController(patrimonio));
  Get.put<PatrimonioController>(PatrimonioController(patrimonio));
  Get.put<PatrimonioDetalheController>(
    PatrimonioDetalheController(patrimonio),
  );
  Get.put<PatrimonioFormController>(
    PatrimonioFormController(patrimonio),
  );
  Get.put<PatrimonioHistoricoController>(
    PatrimonioHistoricoController(patrimonio),
  );
  Get.put<MeusPatrimoniosController>(
    MeusPatrimoniosController(patrimonio),
  );

  final professor = ProfessorService(api);
  Get.put<ProfessorService>(professor, permanent: true);
  Get.put<ProfessorListaController>(ProfessorListaController(professor));
  Get.put<ProfessorCadastroController>(
    ProfessorCadastroController(professor),
  );
  Get.put<ProfessorDetalheController>(
    ProfessorDetalheController(professor),
  );
  Get.put<PatrimonioCicloVidaController>(
    PatrimonioCicloVidaController(patrimonio, professor),
  );

  Get.put<PerfilService>(PerfilService(api, sessao), permanent: true);
  Get.put<PerfilController>(
    PerfilController(Get.find<PerfilService>(), sessao),
  );

  // Parte 6 — usuários do sistema.
  Get.put<AdminService>(AdminService(api), permanent: true);
  Get.put<AdminUsuariosController>(
    AdminUsuariosController(Get.find<AdminService>()),
  );

  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      debugShowCheckedModeBanner: false,
      home: tela(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// `ApiClient` falso que serve todos os endpoints usados pelas telas.
ApiClient apiFalsaDoTeste() {
  return ApiClientFalso((metodo, caminho, _) async {
    if (caminho == '/admin/patrimonios/stats') {
      return {
        'totalPatrimonios': 8,
        'patrimoniosEmUso': 5,
        'patrimoniosDisponiveis': 2,
        'patrimoniosEmManutencao': 1,
        'totalProfessores': 3,
        'totalProfessoresComPatrimonios': 2,
        'porCategoria': {'Informática': 3, 'Audiovisual': 2, 'Laboratório': 2},
      };
    }
    if (caminho == '/patrimonios/meus') {
      return {
        'total': 1,
        'role': 'professor',
        'items': [payloadBemDeTeste()],
      };
    }
    if (caminho == '/patrimonios') {
      return {
        'total': 1,
        'role': 'admin',
        'items': [payloadBemDeTeste()],
      };
    }
    if (caminho.startsWith('/patrimonios/')) {
      return payloadBemDeTeste();
    }
    if (caminho.endsWith('/historico')) {
      return {
        'patrimonioId': 1,
        'total': 1,
        'historico': [
          {
            'id': 1,
            'patrimonioId': 1,
            'professorId': 2,
            'professorNome': 'Prof. Carlos Drummond',
            'adminId': 1,
            'adminNome': 'Coordenador Geral (Admin)',
            'acao': 'atribuicao',
            'motivo': 'Termo de responsabilidade assinado',
            'dataRegistro': '2026-09-14T20:00:00Z',
          },
        ],
      };
    }
    if (caminho == '/admin/professores') return payloadListaProfessores();
    if (caminho.startsWith('/admin/professores/')) {
      return payloadDetalheProfessor();
    }
    if (caminho == '/profile') return payloadPerfil();
    if (caminho == '/admin/users') return payloadListaUsuarios();
    if (caminho.startsWith('/admin/users/')) {
      return payloadAlterarPapel(int.tryParse(caminho.split('/').elementAt(3) ?? '0') ?? 0, 'admin');
    }
    if (caminho == '/admin/stats') return payloadStatsAdmin();
    return <String, dynamic>{};
  });
}

/// Um bem do acervo, no formato do Swagger.
Map<String, dynamic> payloadBemDeTeste() => {
      'id': 1,
      'codigo': 'PAT-2024-001',
      'nome': 'Notebook Dell Latitude 3420',
      'descricao': 'i5, 16GB, SSD 512GB',
      'categoria': 'Informática',
      'marca': 'Dell',
      'modelo': 'Latitude 3420',
      'numeroSerie': 'DL-992831',
      'estadoConservacao': 'Excelente',
      'localizacao': 'Gabinete dos Professores - Mesa 04',
      'status': 'em_uso',
      'professorId': 2,
      'professorNome': 'Prof. Carlos Drummond',
      'dataAtribuicao': '2026-09-14T20:00:00Z',
      'observacoes': '',
      'createdAt': '2026-09-14T19:00:00Z',
      'updatedAt': '2026-09-14T20:00:00Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArmazenamentoFalso armazenamento;

  setUpAll(() async {
    // Carrega a Roboto empacotada em `assets/fonts/`.
    //
    // Sem isso, o `flutter test` desenha o texto com a fonte de teste —
    // cada caractere vira um quadrado do tamanho da fonte — e o texto
    // fica ~2x mais largo que na tela real. Isso gera falsos
    // positivos de overflow: o layout que estoura no teste cabe
    // tranquilamente no aparelho.
    for (final fonte in const [
      'assets/fonts/roboto-regular.ttf',
      'assets/fonts/roboto-medium.ttf',
      'assets/fonts/roboto-bold.ttf',
    ]) {
      final bytes = await rootBundle.load(fonte);
      final carregador = FontLoader('Roboto');
      carregador.addFont(Future<ByteData>.value(bytes));
      await carregador.load();
    }
  });

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  /// Cada tela é verificada nos três tamanhos.
  Future<void> semErroEmTodosOsTamanhos(
    WidgetTester tester,
    Widget Function() tela, {
    required UsuarioModel usuario,
    required String nome,
  }) async {
    for (final tamanho in tamanhos) {
      Get.reset();
      tester.view.physicalSize = tamanho.tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester, tela, usuario: usuario);

      expect(
        tester.takeException(),
        isNull,
        reason: '$nome não pode estourar em ${tamanho.nome}',
      );
    }
  }

  // =========================================================================
  group('Varredura de telas (RNF01/RNF02) — Módulo 1', () {
    testWidgets('Login', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const LoginView(),
        usuario: admin,
        nome: 'Login',
      );
    });

    testWidgets('Cadastro de Coordenador', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const CadastroAdminView(),
        usuario: admin,
        nome: 'Cadastro de Coordenador',
      );
    });

    testWidgets('Recuperação de senha', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const RecuperarSenhaView(),
        usuario: admin,
        nome: 'Recuperação de senha',
      );
    });
  });

  // =========================================================================
  group('Varredura de telas — Módulo 2 (Coordenador)', () {
    testWidgets('Painel do Coordenador', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const AdminHomeView(),
        usuario: admin,
        nome: 'Painel do Coordenador',
      );
    });

    testWidgets('Indicadores', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const DashboardView(),
        usuario: admin,
        nome: 'Indicadores',
      );
    });

    testWidgets('Lista de patrimônios', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioListaView(),
        usuario: admin,
        nome: 'Lista de patrimônios',
      );
    });

    testWidgets('Detalhe do bem', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioDetalheView(),
        usuario: admin,
        nome: 'Detalhe do bem',
      );
    });

    testWidgets('Formulário de patrimônio', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioFormView(),
        usuario: admin,
        nome: 'Formulário de patrimônio',
      );
    });

    testWidgets('Atribuição de bem', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioAtribuicaoView(),
        usuario: admin,
        nome: 'Atribuição de bem',
      );
    });

    testWidgets('Devolução de bem', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioDevolucaoView(),
        usuario: admin,
        nome: 'Devolução de bem',
      );
    });

    testWidgets('Histórico do bem', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PatrimonioHistoricoView(),
        usuario: admin,
        nome: 'Histórico do bem',
      );
    });

    testWidgets('Lista de professores', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const ProfessoresListaView(),
        usuario: admin,
        nome: 'Lista de professores',
      );
    });

    testWidgets('Cadastro de professor', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const ProfessorCadastroView(),
        usuario: admin,
        nome: 'Cadastro de professor',
      );
    });

    testWidgets('Detalhe do professor', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const ProfessorDetalheView(),
        usuario: admin,
        nome: 'Detalhe do professor',
      );
    });

    testWidgets('Usuários do sistema (Parte 6)', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const UsuariosListaView(),
        usuario: admin,
        nome: 'Usuários do sistema',
      );
    });
  });

  // =========================================================================
  group('Varredura de telas — Módulo 3 (Professor)', () {
    testWidgets('Painel do Professor', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const ProfessorHomeView(),
        usuario: docente,
        nome: 'Painel do Professor',
      );
    });

    testWidgets('Meus patrimônios', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const MeusPatrimoniosView(),
        usuario: docente,
        nome: 'Meus patrimônios',
      );
    });

    testWidgets('Perfil', (tester) async {
      await semErroEmTodosOsTamanhos(
        tester,
        () => const PerfilView(),
        usuario: docente,
        nome: 'Perfil',
      );
    });
  });

  // =========================================================================
  group('Varredura de telas — Perfil e navegação', () {
    testWidgets('o Perfil não deixa controller descartado no ar',
        (tester) async {
      // O `PerfilController` também tem `TextEditingController`. Ao sair
      // da tela, o Controller é destruído — e o `TextField` ainda está
      // montado durante a transição.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Sessão ativa: sem token, o `AutenticadoMiddleware` jogaria para
      // o Login e a tela nunca apareceria.
      final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      sessao.token.value = 'token-de-teste';
      sessao.refreshToken.value = 'refresh-de-teste';
      sessao.usuario.value = docente;
      Get.put<ApiClient>(apiFalsaDoTeste(), permanent: true);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: Tema.claro,
          initialBinding: MainBinding(),
          initialRoute: Rotas.homeProfessor,
          getPages: AppRotas.paginas,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Vai para o Perfil e volta: a saída da tela é o momento em que o
      // Controller é destruído.
      await tester.tap(find.byTooltip('Meu perfil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Meu Perfil'), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  group('Varredura — o EstadoVazio nunca estoura', () {
    testWidgets('com texto longo e ação, em tela baixa', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: Tema.claro,
          home: Scaffold(
            body: EstadoVazio(
              icone: Icons.inventory_2_outlined,
              titulo: 'Nenhum professor cadastrado',
              descricao:
                  'Cadastre o corpo docente. O professor não tem cadastro '
                  'próprio: o Coordenador registra e define a senha '
                  'provisória de acesso.',
              acao: FilledButton(
                onPressed: () {},
                child: const Text('Cadastrar professor'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });
}
