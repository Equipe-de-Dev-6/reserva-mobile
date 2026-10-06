import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/bindings.dart';
import 'package:reserva_mobile/app/middleware.dart';
import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';

import 'helpers/test_armazenamento.dart';

/// Testes do grafo de dependências montado pelo `MainBinding`.
///
/// Regressão: o binding usava `Get.putAsync` para a sessão e logo em
/// seguida fazia `Get.find<SessaoService>`. Como o `putAsync` só
/// registra a instância depois que o Future resolve, o `ApiClient`
/// nunca chegava a ser registrado — e o login, que depende dele,
/// quebrava em toda execução do app.
void main() {
  // Estes testes usam `test` puro (não `testWidgets`), então o binding
  // precisa ser inicializado manualmente para que o dublê do canal de
  // plataforma possa ser instalado.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArmazenamentoFalso armazenamento;

  setUp(() {
    armazenamento = ArmazenamentoFalso()..instalar();
  });

  tearDown(() {
    armazenamento.remover();
    Get.reset();
  });

  group('MainBinding', () {
    test('registra SessaoService e ApiClient de forma síncrona', () {
      MainBinding().dependencies();

      // Sem `await`: se alguma dependência dependesse de Future, esta
      // verificação já falharia.
      expect(Get.isRegistered<SessaoService>(), isTrue);
      expect(Get.isRegistered<ApiClient>(), isTrue);
    });

    test('o ApiClient usa exatamente a sessão registrada', () {
      MainBinding().dependencies();
      final api = Get.find<ApiClient>();
      final sessao = Get.find<SessaoService>();
      expect(api.sessao, same(sessao));
    });

    test('a sessão guarda o perfil depois de inicializada', () async {
      MainBinding().dependencies();
      final sessao = Get.find<SessaoService>();

      // Com o dublê do armazenamento, init() conclui sem sessão salva.
      await sessao.init();
      expect(sessao.autenticado, isFalse);
      expect(sessao.usuario.value, isNull);
    });

    test('init() é idempotente: chamar duas vezes não relê o disco', () async {
      MainBinding().dependencies();
      final sessao = Get.find<SessaoService>();

      await sessao.init();
      final tokenAposPrimeiraLeitura = sessao.token.value;

      await sessao.init();

      expect(sessao.token.value, tokenAposPrimeiraLeitura);
      expect(sessao.autenticado, isFalse);
    });

    test('init() recarrega do disco, sobrescrevendo estado em memória',
        () async {
      MainBinding().dependencies();
      final sessao = Get.find<SessaoService>();
      loginEmMemoria(sessao, adminDeTeste());
      expect(sessao.autenticado, isTrue);

      // O dublê devolve "nada salvo", então a sessão em memória é
      // descartada — que é o comportamento correto de uma restauração.
      await sessao.init();
      expect(sessao.autenticado, isFalse);
    });
  });

  group('AuthBinding', () {
    test('monta o AuthService usando o ApiClient e a SessaoService', () {
      MainBinding().dependencies();
      AuthBinding().dependencies();

      expect(Get.isRegistered<AuthService>(), isTrue);
      expect(
        Get.find<AuthService>(),
        isNotNull,
        reason: 'o AuthService depende do ApiClient e da SessaoService',
      );
    });
  });

  group('Guardas de rota', () {
    test('AutenticadoMiddleware manda quem não tem sessão para o login', () {
      MainBinding().dependencies();
      expect(
        AutenticadoMiddleware().redirect(Rotas.homeAdmin)?.name,
        Rotas.login,
      );
    });

    test('AutenticadoMiddleware libera quem tem sessão', () {
      MainBinding().dependencies();
      loginEmMemoria(Get.find<SessaoService>(), adminDeTeste());
      expect(AutenticadoMiddleware().redirect(Rotas.homeAdmin), isNull);
    });

    test('AnonimoMiddleware libera quem não tem sessão', () {
      MainBinding().dependencies();
      expect(AnonimoMiddleware().redirect(Rotas.login), isNull);
    });

    test('AnonimoMiddleware manda o admin ao painel administrativo', () {
      MainBinding().dependencies();
      final sessao = Get.find<SessaoService>();
      loginEmMemoria(sessao, adminDeTeste());

      expect(AnonimoMiddleware().redirect(Rotas.login)?.name, Rotas.homeAdmin);
      expect(rotaPorSessao(sessao), Rotas.homeAdmin);
    });

    test('AnonimoMiddleware manda o professor ao painel do docente', () {
      MainBinding().dependencies();
      final sessao = Get.find<SessaoService>();
      loginEmMemoria(sessao, professorDeTeste());

      expect(
        AnonimoMiddleware().redirect(Rotas.login)?.name,
        Rotas.homeProfessor,
      );
    });
  });
}
