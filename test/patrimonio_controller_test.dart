import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/controllers/patrimonio_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';

/// `ApiClient` falso: registra as queries e devolve um acervo fixo.
class ApiClientDeTeste extends ApiClient {
  ApiClientDeTeste() : super(SessaoService());

  final List<Map<String, dynamic>?> queries = [];

  @override
  Future<Map<String, dynamic>> get(
    String caminho, {
    Map<String, dynamic>? query,
  }) async {
    queries.add(query);
    return {
      'items': [
        {
          'id': 1,
          'codigo': 'PAT-2024-001',
          'nome': 'Notebook',
          'status': 'em_uso',
        },
      ],
      'role': 'admin',
      'total': 1,
    };
  }
}

/// Controller de mentira que só registra o que foi pedido.
class PatrimonioServiceFalso extends PatrimonioService {
  PatrimonioServiceFalso() : super(ApiClientDeTeste());

  int listagens = 0;
  String? ultimaBusca;
  StatusPatrimonio? ultimoStatus;
  String? ultimaCategoria;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    listagens++;
    ultimaBusca = busca;
    ultimoStatus = status;
    ultimaCategoria = categoria;
    return const [
      PatrimonioModel(
        id: 1,
        codigo: 'PAT-2024-001',
        nome: 'Notebook',
        status: StatusPatrimonio.emUso,
      ),
    ];
  }
}

/// Devolve um item na primeira carga e passa a falhar depois.
class ServicoQueFalhaDepois extends PatrimonioService {
  ServicoQueFalhaDepois() : super(ApiClientDeTeste());

  bool falhar = false;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    if (falhar) throw const AppException('Falha ao filtrar', statusCode: 500);
    return const [
      PatrimonioModel(
        id: 1,
        codigo: 'PAT-2024-001',
        nome: 'Notebook',
        status: StatusPatrimonio.emUso,
      ),
    ];
  }
}

/// Sempre falha.
class ServicoQueFalha extends PatrimonioService {
  ServicoQueFalha(this.erro) : super(ApiClientDeTeste());

  final AppException erro;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    throw erro;
  }
}

/// Sessão de Coordenador, montada em memória.
void sessaoDeAdmin() => trocarSessao(
      UsuarioModel(
        nome: 'Coordenador',
        email: 'admin@admin.com',
        role: 'admin',
      ),
    );

/// Troca o usuário da sessão em teste.
///
/// Precisa remover o registro anterior: `Get.put` de um tipo já
/// registrado devolve a instância antiga, e o teste passaria a ver o
/// usuário do caso anterior em vez do novo.
void trocarSessao(UsuarioModel? usuario) {
  Get.delete<SessaoService>(force: true);
  final sessao = Get.put<SessaoService>(SessaoService());
  sessao.usuario.value = usuario;
}

/// Deixa as Futures em andamento resolverem.
///
/// `carregar()` é `async` e não é aguardado por `onInit`; sem este
/// respiro, a lista ainda estaria vazia no `expect` seguinte.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late PatrimonioServiceFalso service;
  late PatrimonioController controller;

  setUp(() {
    sessaoDeAdmin();
    service = PatrimonioServiceFalso();
    Get.put<PatrimonioService>(service);
    controller = PatrimonioController(service);
  });

  tearDown(Get.reset);

  group('PatrimonioController — carga e filtros (RF07a)', () {
    test('abrir a tela já carrega o acervo', () async {
      // `onInit` dispara a primeira carga: é o que faz a tela abrir com
      // dados em vez de esperar um toque do usuário.
      controller.onInit();
      await _settle();

      expect(service.listagens, 1);
      expect(controller.patrimonios, hasLength(1));
      expect(controller.patrimonios.first.codigo, 'PAT-2024-001');
      expect(controller.carregando.value, isFalse);
      expect(controller.erro.value, isEmpty);
    });

    test('sem filtros a consulta não é restringida', () async {
      await controller.carregar();

      // O Controller repassa o texto da busca mesmo vazio; é o Service
      // que decide omitir o parâmetro da query.
      expect(service.ultimaBusca?.trim(), isEmpty);
      expect(service.ultimoStatus, isNull);
      expect(service.ultimaCategoria, isNull);
      expect(controller.temFiltroAtivo.value, isFalse);
    });

    test('selecionar status filtra e marca que há filtro ativo', () async {
      await controller.carregar();
      await controller.alternarStatus(StatusPatrimonio.emUso);

      expect(service.ultimoStatus, StatusPatrimonio.emUso);
      expect(controller.statusSelecionado.value, StatusPatrimonio.emUso);
      expect(controller.temFiltroAtivo.value, isTrue);
    });

    test('tocar no status já selecionado o desmarca', () async {
      // Voltar para "todos" não deveria exigir procurar o chip "Todos".
      await controller.carregar();
      await controller.alternarStatus(StatusPatrimonio.emUso);
      await controller.alternarStatus(StatusPatrimonio.emUso);

      expect(controller.statusSelecionado.value, isNull);
      expect(controller.temFiltroAtivo.value, isFalse);
    });

    test('selecionar categoria filtra a consulta', () async {
      await controller.carregar();
      await controller.escolherCategoria('Informática');

      expect(service.ultimaCategoria, 'Informática');
      expect(controller.categoriaSelecionada.value, 'Informática');
    });

    test('o texto digitado na busca vai para a consulta', () async {
      await controller.carregar();
      controller.buscaCtrl.text = 'PAT-2024';
      await controller.buscarAgora();

      expect(service.ultimaBusca, 'PAT-2024');
      expect(controller.temFiltroAtivo.value, isTrue);
    });

    test('busca em branco não conta como filtro ativo', () async {
      await controller.carregar();
      controller.aoDigitarBusca('   ');
      await controller.buscarAgora();

      expect(controller.temFiltroAtivo.value, isFalse);
    });

    test('limpar filtros apaga busca, status e categoria', () async {
      await controller.carregar();
      controller.buscaCtrl.text = 'PAT-2024';
      await controller.alternarStatus(StatusPatrimonio.emUso);
      await controller.escolherCategoria('Informática');
      expect(controller.temFiltroAtivo.value, isTrue);

      await controller.limparFiltros();

      expect(controller.buscaCtrl.text, isEmpty);
      expect(controller.busca.value, isEmpty);
      expect(controller.statusSelecionado.value, isNull);
      expect(controller.categoriaSelecionada.value, isNull);
      expect(controller.temFiltroAtivo.value, isFalse);
      expect(service.ultimaBusca?.trim(), isEmpty);
    });

    test('a busca só dispara após o intervalo de silêncio', () async {
      // Sem debounce, cada tecla geraria uma requisição e o backend
      // receberia "P", "PA", "PAT" em sequência.
      await controller.carregar();
      final antes = service.listagens;

      controller.aoDigitarBusca('P');
      controller.aoDigitarBusca('PA');
      controller.aoDigitarBusca('PAT');

      expect(service.listagens, antes, reason: 'ainda dentro da janela');

      await Future<void>.delayed(PatrimonioController.debounceBusca);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(service.listagens, antes + 1);
      expect(service.ultimaBusca, 'PAT');
    });

    test('buscarAgora ignora a espera e vai direto à API', () async {
      await controller.carregar();
      controller.buscaCtrl.text = 'note';
      await controller.buscarAgora();

      expect(service.ultimaBusca, 'note');
    });
  });

  group('PatrimonioController — estados de erro (RNF02)', () {
    test('falha na carga mostra a mensagem da API e some o spinner', () async {
      final falho = ServicoQueFalha(
        const AppException('Servidor fora do ar', statusCode: 500),
      );
      final c = PatrimonioController(falho);

      await c.carregar();

      expect(c.erro.value, 'Servidor fora do ar');
      expect(c.carregando.value, isFalse);
      expect(c.patrimonios, isEmpty);
    });

    test('falha ao filtrar não apaga a lista que já estava na tela', () async {
      final falho = ServicoQueFalhaDepois();
      final c = PatrimonioController(falho);

      await c.carregar();
      expect(c.patrimonios, hasLength(1));

      falho.falhar = true;
      await c.alternarStatus(StatusPatrimonio.emUso);

      // O Coordinator ainda consegue ler o acervo anterior e limpar o
      // filtro; sumir com a lista deixaria a tela sem saída.
      expect(c.erro.value, isNotEmpty);
      expect(c.patrimonios, hasLength(1));
    });

    test('carregar de novo limpa o erro anterior', () async {
      final falho = ServicoQueFalhaDepois();
      final c = PatrimonioController(falho);

      falho.falhar = true;
      await c.carregar();
      expect(c.erro.value, isNotEmpty);

      falho.falhar = false;
      await c.carregar();
      expect(c.erro.value, isEmpty);
    });
  });

  group('PatrimonioController — texto do estado vazio', () {
    test('sem filtro, fala em acervo vazio', () async {
      await controller.carregar();

      expect(controller.tituloEstadoVazio, 'Nenhum bem cadastrado');
      expect(controller.descricaoEstadoVazio, contains('Cadastre'));
    });

    test('com filtro, fala em busca sem resultado', () async {
      await controller.carregar();
      await controller.alternarStatus(StatusPatrimonio.emUso);

      expect(controller.tituloEstadoVazio, 'Nenhum bem encontrado');
      expect(controller.descricaoEstadoVazio, contains('filtros'));
    });
  });

  group('RN03 — visibilidade das ações de escrita', () {
    test('Coordenador pode cadastrar bem', () {
      expect(controller.podeCadastrar, isTrue);
    });

    test('Professor não pode cadastrar bem', () {
      // O botão nem aparece para o docente: RN03 é de visibilidade, não
      // só de permissão no servidor.
      trocarSessao(UsuarioModel(
        nome: 'Prof. Carlos',
        email: 'professor@escola.com',
        role: 'professor',
      ));

      final c = PatrimonioController(service);
      expect(c.podeCadastrar, isFalse);
    });

    test('sem sessão definida, a resposta é "não pode"', () {
      // Falhar fechado: sem perfil conhecido, nada de botão de escrita.
      trocarSessao(null);

      final c = PatrimonioController(service);
      expect(c.podeCadastrar, isFalse);
    });
  });
}
