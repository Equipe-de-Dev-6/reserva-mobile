// Testes de integração do módulo de Patrimônio (RF07a) contra a API real.
//
// Execução:
//   1) suba o backend:  .\api.exe
//   2) rode:            flutter test test\integracao_patrimonio_test.dart
//
// Os testes são ignorados automaticamente se a API não estiver no ar,
// para o `flutter test` padrão não quebrar em uma máquina sem backend.
//
// Nenhum teste deixa lixo no acervo: todo bem criado é excluído no fim.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reserva_mobile/core/config/api_config.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';

Future<bool> _apiNoAr() async {
  try {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..options.connectTimeout = const Duration(seconds: 2);
    final resposta = await dio.get<dynamic>('/health');
    return resposta.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool online;
  late SessaoService sessao;
  late ApiClient api;
  late PatrimonioService patrimonio;

  setUpAll(() async {
    online = await _apiNoAr();
    if (!online) {
      // ignore: avoid_print
      print('API offline em ${ApiConfig.baseUrl} — testes de integração '
          'ignorados.');
    }
  });

  setUp(() async {
    sessao = SessaoService();
    api = ApiClient(sessao);
    api.onInit();
    patrimonio = PatrimonioService(api);

    if (!online) return;

    // Usa o AuthService de verdade: o mesmo caminho do app, com o mesmo
    // interceptor de token. A autenticação em si é coberta por
    // `integracao_auth_test.dart`; aqui só interessa a sessão válida.
    final login = await AuthService(api, sessao).login(
      'admin@admin.com',
      'admin123',
    );
    await sessao.salvar(
      token: login.token,
      refreshToken: login.refreshToken,
      usuario: login.usuario,
    );
  });

  group('Integração — RF07a listagem e filtros', () {
    test('lista o acervo do Coordenador', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final lista = await patrimonio.listar();

      expect(lista, isNotEmpty);
      expect(lista.every((p) => p.id > 0), isTrue);
      expect(lista.every((p) => p.codigo.isNotEmpty), isTrue);
    });

    test('busca por tombamento devolve só o bem pedido', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final todos = await patrimonio.listar();
      final alvo = todos.first;
      final achados = await patrimonio.listar(busca: alvo.codigo);

      expect(achados, isNotEmpty);
      expect(achados.every((p) => p.codigo == alvo.codigo), isTrue);
    });

    test('busca sem resultado devolve lista vazia, sem erro', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      expect(await patrimonio.listar(busca: 'ZZZ-NAO-EXISTE-999'), isEmpty);
    });

    test('filtro por status restringe a listagem', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final disponiveis = await patrimonio.listar(
        status: StatusPatrimonio.disponivel,
      );

      expect(
        disponiveis.every((p) => p.status == StatusPatrimonio.disponivel),
        isTrue,
      );
    });

    test('filtro por categoria restringe a listagem', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final lista = await patrimonio.listar(categoria: 'Informática');

      expect(
        lista.every((p) => p.categoria == 'Informática'),
        isTrue,
      );
    });

    test('busca e status podem ser combinados', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final emUso = await patrimonio.listar(status: StatusPatrimonio.emUso);
      if (emUso.isEmpty) { markTestSkipped('acervo sem bens em uso'); return; }

      final alvo = emUso.first;
      final achados = await patrimonio.listar(
        busca: alvo.codigo,
        status: StatusPatrimonio.emUso,
      );

      expect(achados, hasLength(1));
      expect(achados.first.codigo, alvo.codigo);
    });
  });

  group('Integração — RF07a detalhe, cadastro, edição e exclusão', () {
    test('detalhe traz o bem completo, com especificações', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final lista = await patrimonio.listar();
      final alvo = lista.first;

      final detalhe = await patrimonio.detalhe(alvo.id);

      expect(detalhe.id, alvo.id);
      expect(detalhe.codigo, alvo.codigo);
      expect(detalhe.nome, isNotEmpty);
      expect(detalhe.status, isNot(StatusPatrimonio.indefinido));
    });

    test('detalhe de id inexistente devolve 404 com mensagem', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      try {
        await patrimonio.detalhe(999999);
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 404);
        expect(e.mensagem, isNotEmpty);
      }
    });

    test('cadastro → detalhe → edição → exclusão (ciclo completo)', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      final codigo = 'TST-GAB-${DateTime.now().millisecondsSinceEpoch}';

      // 1) Cadastro.
      final criado = await patrimonio.criar(PatrimonioModel(
        id: 0,
        codigo: codigo,
        nome: 'Notebook de teste',
        descricao: 'Item criado pelo teste de integração',
        categoria: 'Informática',
        marca: 'ACME',
        localizacao: 'Laboratório',
        estadoConservacao: 'Bom',
        status: StatusPatrimonio.disponivel,
      ));

      expect(criado.idValido, isTrue,
          reason: 'o backend precisa devolver o id do bem criado');
      expect(criado.codigo, codigo);
      expect(criado.status, StatusPatrimonio.disponivel);

      // 2) Detalhe.
      final detalhe = await patrimonio.detalhe(criado.id);
      expect(detalhe.codigo, codigo);
      expect(detalhe.professorId, isNull,
          reason: 'bem recém-criado nasce sem professor');

      try {
        // 3) Edição: muda localização e estado.
        await patrimonio.atualizar(
          criado.id,
          detalhe.copyWith(
            localizacao: 'Sala 101 - Bloco A',
            estadoConservacao: 'Excelente',
            status: StatusPatrimonio.emManutencao,
          ),
        );

        final depois = await patrimonio.detalhe(criado.id);
        expect(depois.localizacao, 'Sala 101 - Bloco A');
        expect(depois.estadoConservacao, 'Excelente');
        expect(depois.status, StatusPatrimonio.emManutencao);
        expect(depois.codigo, codigo,
            reason: 'a edição não pode alterar o tombamento');

        // 4) Exclusão.
        await patrimonio.excluir(criado.id);

        try {
          await patrimonio.detalhe(criado.id);
          fail('O bem deveria ter sido excluído');
        } on AppException catch (e) {
          expect(e.statusCode, 404);
        }
      } finally {
        // Garante a limpeza mesmo se uma asserção falhar no meio.
        try {
          await patrimonio.excluir(criado.id);
        } catch (_) {
          // Já excluído (ou id inexistente): nada a fazer.
        }
      }
    });

    test('cadastro sem tombamento é recusado com 400', () async {
      if (!online) { markTestSkipped('API offline'); return; }

      try {
        await patrimonio.criar(
            PatrimonioModel(id: 0, codigo: '', nome: 'Sem tombamento'));
        fail('Deveria ter lançado AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 400);
        expect(e.mensagem, isNotEmpty);
      }
    });
  });
}


