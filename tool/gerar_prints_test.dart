// Gerador de **prints do app em funcionamento**.
//
// Este arquivo NAO faz parte da suite de testes: ele mora em `tool/`
// (e nao em `test/`) porque `flutter test` so coleta o que esta em
// `test/`. Ele e executado sob demanda:
//
//   flutter test tool/gerar_prints_test.dart
//
// O que ele faz: monta cada tela real do aplicativo dentro de um
// `RepaintBoundary` com o tamanho do iPhone 13 (390 x 844), com as
// dependencias de verdade substituidas por um `ApiClient` falso que
// devolve os mesmos payloads do backend, e grava o PNG resultante em
// `docs/prints/`.
//
// Os prints do README sao gerados por aqui - e nao por um mock em HTML -
// para que mostrem o app de verdade, com os widgets, as fontes e os
// espacamentos reais.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
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
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/perfil_service.dart';
import 'package:reserva_mobile/core/servicos/professor_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/admin/admin_home_view.dart';
import 'package:reserva_mobile/views/admin/dashboard_view.dart';
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

import '../test/helpers/api_client_falso.dart';

/// Tamanho do iPhone 13 - a referencia de design do time.
const Size tamanhoDoAparelho = Size(390, 844);

/// Onde os PNGs sao gravados.
final Directory pastaDosPrints = Directory('docs/prints');

/// Usuario admin na sessao (para as telas que exigem Coordenador).
final UsuarioModel admin = UsuarioModel(
  id: 1,
  nome: 'Coordenador Geral',
  email: 'admin@escola.com',
  role: 'admin',
  matricula: 'COORD-001',
  departamento: 'Coordenacao Pedagogica e Patrimonial',
);

/// Usuario docente na sessao.
final UsuarioModel docente = UsuarioModel(
  id: 2,
  nome: 'Prof. Carlos Drummond',
  email: 'professor@escola.com',
  role: 'professor',
  matricula: 'PROF-2024-01',
  departamento: 'Lingua Portuguesa e Literatura',
  telefone: '(11) 98765-1001',
  totalPatrimonios: 3,
);

/// Payload de `GET /patrimonios`.
Map<String, dynamic> payloadPatrimonios() => {
      'total': 3,
      'role': 'admin',
      'items': [
        {
          'id': 1,
          'codigo': 'PAT-2024-001',
          'nome': 'Notebook Dell Latitude 3420',
          'descricao': 'Intel Core i5 11a Ger, 16GB RAM, SSD 512GB',
          'categoria': 'Informatica',
          'marca': 'Dell',
          'modelo': 'Latitude 3420',
          'numeroSerie': 'DL-992831',
          'estadoConservacao': 'Excelente',
          'localizacao': 'Gabinete dos Professores - Mesa 04',
          'status': 'em_uso',
          'professorId': 2,
          'professorNome': 'Prof. Carlos Drummond',
          'dataAtribuicao': '2026-09-14T20:00:00Z',
          'observacoes': 'Entregue com bolsa e carregador original',
          'createdAt': '2026-09-14T19:00:00Z',
          'updatedAt': '2026-09-14T19:00:00Z',
        },
        {
          'id': 2,
          'codigo': 'PAT-2024-002',
          'nome': 'Projetor Epson PowerLite E20',
          'descricao': 'Projetor 3LCD 3400 lumens',
          'categoria': 'Audiovisual',
          'marca': 'Epson',
          'modelo': 'PowerLite E20',
          'numeroSerie': 'EP-44120',
          'estadoConservacao': 'Bom',
          'localizacao': 'Sala de Aula 102 - Bloco A',
          'status': 'disponivel',
          'observacoes': '',
          'createdAt': '2026-09-12T19:00:00Z',
          'updatedAt': '2026-09-12T19:00:00Z',
        },
        {
          'id': 3,
          'codigo': 'PAT-2024-003',
          'nome': 'Microscopio binocular Zeiss Axio 2',
          'descricao': 'Amplificacao 1000x, com camera',
          'categoria': 'Laboratorio',
          'marca': 'Zeiss',
          'modelo': 'Axio 2',
          'numeroSerie': 'ZS-77812',
          'estadoConservacao': 'Regular',
          'localizacao': 'Laboratorio de Biologia',
          'status': 'em_manutencao',
          'observacoes': 'Aguardando peca do fabricante',
          'createdAt': '2026-08-30T19:00:00Z',
          'updatedAt': '2026-10-02T19:00:00Z',
        },
      ],
    };

/// Payload de `GET /admin/patrimonios/stats`.
Map<String, dynamic> payloadStats() => {
      'totalPatrimonios': 12,
      'patrimoniosEmUso': 7,
      'patrimoniosDisponiveis': 4,
      'patrimoniosEmManutencao': 1,
      'totalProfessores': 4,
      'totalProfessoresComPatrimonios': 3,
      'porCategoria': {
        'Informatica': 5,
        'Audiovisual': 3,
        'Laboratorio': 2,
        'Eletronicos': 2,
      },
    };

/// Payload de `GET /admin/patrimonios/{id}/historico`.
Map<String, dynamic> payloadHistorico() => {
      'patrimonioId': 1,
      'total': 3,
      'historico': [
        {
          'id': 3,
          'patrimonioId': 1,
          'professorId': 2,
          'professorNome': 'Prof. Carlos Drummond',
          'adminId': 1,
          'adminNome': 'Coordenador Geral (Admin)',
          'acao': 'atribuicao',
          'motivo': 'Termo de responsabilidade assinado',
          'dataRegistro': '2026-09-14T20:00:00Z',
        },
        {
          'id': 2,
          'patrimonioId': 1,
          'professorId': null,
          'professorNome': null,
          'adminId': 1,
          'adminNome': 'Coordenador Geral (Admin)',
          'acao': 'edicao',
          'motivo': 'Atualizacao da localizacao fisica',
          'dataRegistro': '2026-09-14T19:30:00Z',
        },
        {
          'id': 1,
          'patrimonioId': 1,
          'professorId': null,
          'professorNome': null,
          'adminId': 1,
          'adminNome': 'Coordenador Geral (Admin)',
          'acao': 'criacao',
          'motivo': 'Cadastro inicial do bem',
          'dataRegistro': '2026-09-14T19:00:00Z',
        },
      ],
    };

/// `ApiClient` falso que serve todos os endpoints usados pelas telas.
ApiClient apiFalsa() {
  return ApiClientFalso((metodo, caminho, _) async {
    if (caminho == '/admin/patrimonios/stats') return payloadStats();
    if (caminho == '/patrimonios/meus') {
      return {
        'total': 2,
        'role': 'professor',
        'items': (payloadPatrimonios()['items'] as List).take(2).toList(),
      };
    }
    if (caminho == '/patrimonios') return payloadPatrimonios();
    if (caminho.startsWith('/patrimonios/')) {
      final id = int.tryParse(caminho.split('/').last) ?? 1;
      final itens = payloadPatrimonios()['items'] as List;
      final item = itens.firstWhere(
        (e) => (e as Map)['id'] == id,
        orElse: () => itens.first,
      );
      return Map<String, dynamic>.from(item as Map);
    }
    if (caminho.endsWith('/historico')) return payloadHistorico();
    if (caminho == '/admin/professores') return payloadListaProfessores();
    if (caminho.startsWith('/admin/professores/')) {
      return payloadDetalheProfessor();
    }
    if (caminho == '/profile') return payloadPerfil();
    return <String, dynamic>{};
  });
}

/// Registra a sessao e as dependencias globais.
void registrarSessao(UsuarioModel usuario) {
  final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
  sessao.usuario.value = usuario;
  Get.put<ApiClient>(apiFalsa(), permanent: true);
  Get.put<AuthService>(AuthService(Get.find<ApiClient>(), sessao));
  Get.put<AuthController>(AuthController(Get.find<AuthService>()));
}

/// Monta a tela e grava o PNG.
Future<void> capturar(
  WidgetTester tester,
  String nome,
  Widget Function() tela,
) async {
  final chave = GlobalKey();
  await tester.pumpWidget(
    GetMaterialApp(
      theme: Tema.claro,
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(key: chave, child: tela()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));

  final boundary =
      chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late Uint8List bytes;
  await tester.runAsync(() async {
    final imagem = await boundary.toImage(pixelRatio: 2);
    final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
    bytes = dados!.buffer.asUint8List();
  });

  final arquivo = File('${pastaDosPrints.path}${Platform.pathSeparator}$nome.png');
  arquivo.parent.createSync(recursive: true);
  arquivo.writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('print gerado: ${arquivo.path}');
}

/// Prepara o viewport do aparelho e registra a sessao.
void preparar(WidgetTester tester, UsuarioModel usuario) {
  tester.view.physicalSize = tamanhoDoAparelho * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  registrarSessao(usuario);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!pastaDosPrints.existsSync()) {
      pastaDosPrints.createSync(recursive: true);
    }

    // Carrega a Roboto empacotada em `assets/fonts/`.
    //
    // Sem isso, o `flutter test` desenha o texto com a fonte de teste
    // (cada caractere vira um quadrado) e o PNG sairia ilegivel - alem
    // de "estourar" linhas que na tela real cabem.
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

    // A fonte dos icones do Material tambem precisa ser carregada: sem
    // ela, todo `Icon` sai como um quadrado vazio.
    try {
      final bytes = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
      final carregador = FontLoader('MaterialIcons');
      carregador.addFont(Future<ByteData>.value(bytes));
      await carregador.load();
    } catch (_) {
      // Se a fonte nao estiver no bundle, o app ainda abre - apenas os
      // icones saem como quadrados. Nao e um motivo para abortar.
    }
  });

  tearDown(Get.reset);

  testWidgets('print 01 - login', (tester) async {
    preparar(tester, admin);
    await capturar(tester, '01-login', () => const LoginView());
  });

  testWidgets('print 02 - cadastro de coordenador', (tester) async {
    preparar(tester, admin);
    await capturar(tester, '02-cadastro-coordenador',
        () => const CadastroAdminView());
  });

  testWidgets('print 03 - recuperar senha', (tester) async {
    preparar(tester, admin);
    await capturar(tester, '03-recuperar-senha',
        () => const RecuperarSenhaView());
  });

  testWidgets('print 04 - painel do Coordenador', (tester) async {
    preparar(tester, admin);
    await capturar(tester, '04-painel-coordenador', () => const AdminHomeView());
  });

  testWidgets('print 05 - indicadores', (tester) async {
    preparar(tester, admin);
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<DashboardController>(
      DashboardController(Get.find<PatrimonioService>()),
    );
    await capturar(tester, '05-indicadores', () => const DashboardView());
  });

  testWidgets('print 06 - lista de patrimonios', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<PatrimonioController>(PatrimonioController(service));
    await capturar(tester, '06-patrimonios-lista',
        () => const PatrimonioListaView());
  });

  testWidgets('print 07 - detalhe do bem', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<PatrimonioDetalheController>(
      PatrimonioDetalheController(service),
    );
    await capturar(tester, '07-patrimonio-detalhe',
        () => const PatrimonioDetalheView());
  });

  testWidgets('print 08 - formulario de patrimonio', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<PatrimonioFormController>(PatrimonioFormController(service));
    await capturar(tester, '08-patrimonio-form',
        () => const PatrimonioFormView());
  });

  testWidgets('print 09 - atribuicao de bem', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<ProfessorService>(ProfessorService(Get.find<ApiClient>()));
    Get.put<PatrimonioCicloVidaController>(
      PatrimonioCicloVidaController(
        Get.find<PatrimonioService>(),
        Get.find<ProfessorService>(),
      )..id = 1,
    );
    await capturar(tester, '09-atribuicao-bem',
        () => const PatrimonioAtribuicaoView());
  });

  testWidgets('print 10 - devolucao de bem', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<ProfessorService>(ProfessorService(Get.find<ApiClient>()));
    Get.put<PatrimonioCicloVidaController>(
      PatrimonioCicloVidaController(
        Get.find<PatrimonioService>(),
        Get.find<ProfessorService>(),
      )
        ..id = 1
        ..devolvendo = true,
    );
    await capturar(tester, '10-devolucao-bem',
        () => const PatrimonioDevolucaoView());
  });

  testWidgets('print 11 - historico do bem', (tester) async {
    preparar(tester, admin);
    final service = PatrimonioService(Get.find<ApiClient>());
    Get.put<PatrimonioService>(service, permanent: true);
    Get.put<PatrimonioHistoricoController>(
      PatrimonioHistoricoController(service)..id = 1,
    );
    await capturar(tester, '11-historico-bem',
        () => const PatrimonioHistoricoView());
  });

  testWidgets('print 12 - lista de professores', (tester) async {
    preparar(tester, admin);
    final service = ProfessorService(Get.find<ApiClient>());
    Get.put<ProfessorService>(service);
    Get.put<ProfessorListaController>(ProfessorListaController(service));
    await capturar(tester, '12-professores-lista',
        () => const ProfessoresListaView());
  });

  testWidgets('print 13 - cadastro de professor', (tester) async {
    preparar(tester, admin);
    final service = ProfessorService(Get.find<ApiClient>());
    Get.put<ProfessorService>(service);
    Get.put<ProfessorCadastroController>(ProfessorCadastroController(service));
    await capturar(tester, '13-professor-cadastro',
        () => const ProfessorCadastroView());
  });

  testWidgets('print 14 - detalhe do professor', (tester) async {
    preparar(tester, admin);
    final service = ProfessorService(Get.find<ApiClient>());
    Get.put<ProfessorService>(service);
    Get.put<ProfessorDetalheController>(ProfessorDetalheController(service));
    await capturar(tester, '14-professor-detalhe',
        () => const ProfessorDetalheView());
  });

  testWidgets('print 15 - painel do Professor', (tester) async {
    preparar(tester, docente);
    await capturar(tester, '15-painel-professor',
        () => const ProfessorHomeView());
  });

  testWidgets('print 16 - meus patrimonios', (tester) async {
    preparar(tester, docente);
    Get.put<PatrimonioService>(
      PatrimonioService(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<MeusPatrimoniosController>(
      MeusPatrimoniosController(Get.find<PatrimonioService>()),
    );
    await capturar(tester, '16-meus-patrimonios',
        () => const MeusPatrimoniosView());
  });

  testWidgets('print 17 - perfil', (tester) async {
    preparar(tester, docente);
    Get.put<PerfilService>(
      PerfilService(Get.find<ApiClient>(), Get.find<SessaoService>()),
    );
    Get.put<PerfilController>(
      PerfilController(
        Get.find<PerfilService>(),
        Get.find<SessaoService>(),
      ),
    );
    await capturar(tester, '17-perfil', () => const PerfilView());
  });
}
