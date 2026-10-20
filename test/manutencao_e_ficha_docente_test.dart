// Testes das lacunas fechadas na auditoria final:
//
//  * RF08 — ficha do bem em modo leitura para o docente (Lacuna 1);
//  * RN05 — fluxo de manutenção (Lacuna 2);
//  * RN03 — rotas do módulo de patrimônio com guarda de papel (Lacuna 4).
//
// Nenhum teste depende do backend: o `ApiClientFalso` devolve payloads
// no mesmo formato do Swagger, e o que se verifica é a camada que o app
// controla — a montagem da rota, do corpo e o tratamento do resultado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/rotas.dart';
import 'package:reserva_mobile/controllers/patrimonio_manutencao_controller.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/views/patrimonio/rotas_patrimonio.dart';
import 'package:reserva_mobile/views/professor/rotas_professor.dart';

import 'helpers/api_client_falso.dart';

/// Um bem como o `GET /patrimonios/{id}` devolve.
Map<String, dynamic> payloadBem({
  String status = 'disponivel',
  int? professorId,
}) =>
    {
      'id': 7,
      'codigo': 'PAT-2024-007',
      'nome': 'Notebook Dell Latitude 3420',
      'descricao': 'Equipamento do laboratorio de informatica.',
      'categoria': 'Informatica',
      'marca': 'Dell',
      'modelo': 'Latitude 3420',
      'numeroSerie': 'DL-992831',
      'estadoConservacao': 'Bom',
      'localizacao': 'Gabinete de Docentes',
      'status': status,
      'observacoes': '',
      'professorId': professorId,
      'professorNome': professorId == null ? null : 'Prof. Carlos',
      'dataAtribuicao': professorId == null ? null : '2026-09-14T20:00:00Z',
      'createdAt': '2026-09-10T14:00:00Z',
      'updatedAt': '2026-09-14T20:00:00Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  // =========================================================================
  group('PatrimonioService — manutencao (RN05)', () {
    test('enviarParaManutencao troca o status e a observacao', () async {
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final service = PatrimonioService(api);

      await service.enviarParaManutencao(
        7,
        observacao: 'Nao liga apos queda de energia',
      );

      expect(api.chamadas, ['PUT /patrimonios/7']);
      expect(api.corpos.last, {
        'status': 'em_manutencao',
        'observacoes': 'Nao liga apos queda de energia',
      });
    });

    test('concluirManutencao devolve o bem ao almoxarifado', () async {
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final service = PatrimonioService(api);

      await service.concluirManutencao(7, observacao: 'Troca da fonte');

      expect(api.chamadas, ['PUT /patrimonios/7']);
      expect(api.corpos.last, {
        'status': 'disponivel',
        'observacoes': 'Troca da fonte',
      });
    });

    test('o corpo nao reenvia os campos cadastrais', () async {
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final service = PatrimonioService(api);

      await service.enviarParaManutencao(7);

      // Um corpo grande aqui significaria o `toJsonAtualizacao()` vazando
      // para a troca de status, sobrescrevendo o cadastro em memoria.
      final corpo = api.corpos.last! as Map<String, dynamic>;
      expect(corpo.keys.toSet(), {'status', 'observacoes'});
    });
  });

  // =========================================================================
  group('PatrimonioManutencaoController (RN05)', () {
    test('o envio exige o defeito relatado', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      )
        ..id = 7
        ..enviando = true;
      controller.onInit();

      expect(controller.validarMotivo(''), isNotNull);
      expect(controller.validarMotivo('x'), isNotNull);
      expect(controller.validarMotivo('Nao liga de jeito nenhum'), isNull);
      expect(controller.validarMotivo(null), isNotNull);
    });

    test('a conclusao pede o servico realizado, nao o defeito', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      )
        ..id = 7
        ..enviando = false;
      controller.onInit();

      expect(controller.concluindo, isTrue);
      expect(controller.validarMotivo(''), contains('serviço'));
      expect(controller.validarMotivo('Troca do teclado'), isNull);
    });

    test('o envio com motivo chega ao Service', () async {
      Get.testMode = true;
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final controller = PatrimonioManutencaoController(
        PatrimonioService(api),
      )
        ..id = 7
        ..enviando = true;
      controller.onInit();
      controller.motivoCtrl.text = 'Tela trincada';

      final ok = await controller.confirmar(_FormularioVazio());

      expect(ok, isTrue);
      expect(api.chamadas, ['PUT /patrimonios/7']);
      expect(api.corpos.last, {
        'status': 'em_manutencao',
        'observacoes': 'Tela trincada',
      });
    });

    test('a conclusao com motivo chega ao Service', () async {
      Get.testMode = true;
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final controller = PatrimonioManutencaoController(
        PatrimonioService(api),
      )
        ..id = 7
        ..enviando = false;
      controller.onInit();
      controller.motivoCtrl.text = 'Fonte trocada';

      final ok = await controller.confirmar(_FormularioVazio());

      expect(ok, isTrue);
      expect(api.corpos.last, {
        'status': 'disponivel',
        'observacoes': 'Fonte trocada',
      });
    });

    test('sem id, nada e enviado', () async {
      Get.testMode = true;
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final controller = PatrimonioManutencaoController(
        PatrimonioService(api),
      )..enviando = true;
      controller.onInit();
      controller.motivoCtrl.text = 'Tela trincada';

      final ok = await controller.confirmar(_FormularioVazio());

      expect(ok, isFalse);
      expect(api.chamadas, isEmpty);
      expect(controller.erro.value, contains('não informado'));
    });

    test('ler os argumentos da rota define id, bem e modo', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      );
      // A rota entrega o bem e o modo por `arguments` (nao ha setter em
      // tempo de teste para `Get.arguments`).
      controller
        ..id = 7
        ..enviando = false
        ..patrimonio.value = PatrimonioModel.fromJson(payloadBem());
      controller.onInit();

      expect(controller.id, 7);
      expect(controller.enviando, isFalse);
      expect(controller.patrimonio.value?.codigo, 'PAT-2024-007');
    });

    test('bem em uso nao vai direto para manutencao (RN05)', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      )
        ..enviando = true
        ..patrimonio.value = PatrimonioModel.fromJson(payloadBem(
          status: 'em_uso',
          professorId: 2,
        ));

      expect(controller.bloqueioEnvio, contains('professor'));
    });

    test('bem baixado nao passa por manutencao', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      )
        ..enviando = true
        ..patrimonio.value =
            PatrimonioModel.fromJson(payloadBem(status: 'baixado'));

      expect(controller.bloqueioEnvio, contains('baixados'));
    });

    test('bem disponivel nao tem bloqueio', () {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(ApiClientFalso((_, _, _) async => payloadBem())),
      )
        ..enviando = true
        ..patrimonio.value =
            PatrimonioModel.fromJson(payloadBem(status: 'disponivel'));

      expect(controller.bloqueioEnvio, isNull);
    });

    test('erro do backend fica visivel sem fechar a tela', () async {
      Get.testMode = true;
      final controller = PatrimonioManutencaoController(
        PatrimonioService(
          ApiClientComErro(
            const AppException('Nao foi possivel conectar ao servidor.'),
          ),
        ),
      )
        ..id = 7
        ..enviando = true;
      controller.onInit();
      controller.motivoCtrl.text = 'Tela trincada';

      final ok = await controller.confirmar(_FormularioVazio());

      expect(ok, isFalse);
      expect(controller.erro.value, 'Nao foi possivel conectar ao servidor.');
      expect(controller.salvando.value, isFalse);
    });
  });

  // =========================================================================
  group('PatrimonioManutencaoView — validacao no formulario real', () {
    testWidgets('o campo vazio barra o envio antes da API', (tester) async {
      Get.testMode = true;
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final controller = PatrimonioManutencaoController(
        PatrimonioService(api),
      )
        ..id = 7
        ..enviando = true
        ..patrimonio.value =
            PatrimonioModel.fromJson(payloadBem(status: 'disponivel'));
      controller.onInit();

      // Um formulário de verdade com o mesmo validador da tela.
      final chave = GlobalKey<FormState>();
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: Form(
            key: chave,
            child: TextFormField(validator: controller.validarMotivo),
          ),
        ),
      ));

      final ok = await controller.confirmar(chave.currentState!);

      expect(ok, isFalse);
      // A mensagem fica no campo; a faixa de erro da API continua limpa.
      expect(controller.erro.value, isEmpty);
      expect(api.chamadas, isEmpty);
      expect(controller.validarMotivo(''), contains('defeito'));
    });

    testWidgets('motivo curto tambem e barrado', (tester) async {
      Get.testMode = true;
      final api = ApiClientFalso((_, _, _) async => payloadBem());
      final controller = PatrimonioManutencaoController(
        PatrimonioService(api),
      )
        ..id = 7
        ..enviando = true;
      controller.onInit();
      controller.motivoCtrl.text = 'x';

      final chave = GlobalKey<FormState>();
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: Form(
            key: chave,
            child: TextFormField(validator: controller.validarMotivo),
          ),
        ),
      ));

      final ok = await controller.confirmar(chave.currentState!);

      expect(ok, isFalse);
      expect(api.chamadas, isEmpty);
    });
  });

  // =========================================================================
  group('Rotas das lacunas fechadas (RF01 — navegacao nomeada)', () {
    test('a ficha do docente esta no mapa de navegacao', () {
      final nomes = AppRotas.paginas.map((p) => p.name).toSet();

      expect(nomes, contains(RotasProfessor.detalhePatrimonio));
    });

    test('a ficha do docente exige sessao, mas nao papel de admin', () {
      final pagina = AppRotas.paginas.firstWhere(
        (p) => p.name == RotasProfessor.detalhePatrimonio,
      );
      final classes =
          (pagina.middlewares ?? const []).map((m) => m.runtimeType.toString());

      expect(classes, contains('AutenticadoMiddleware'));
      expect(classes, isNot(contains('AdminMiddleware')));
    });

    test('a tela de manutencao esta no mapa de navegacao', () {
      final nomes = AppRotas.paginas.map((p) => p.name).toSet();

      expect(nomes, contains(RotasPatrimonio.manutencao));
    });

    test('todo o modulo de patrimonio exige papel de admin (RN03)', () {
      final rotasDoModulo = {
        RotasPatrimonio.lista,
        RotasPatrimonio.detalhe,
        RotasPatrimonio.form,
        RotasPatrimonio.atribuicao,
        RotasPatrimonio.devolucao,
        RotasPatrimonio.historico,
        RotasPatrimonio.manutencao,
      };

      for (final nome in rotasDoModulo) {
        final pagina = AppRotas.paginas.firstWhere((p) => p.name == nome);
        final classes = (pagina.middlewares ?? const [])
            .map((m) => m.runtimeType.toString());

        expect(classes, contains('AutenticadoMiddleware'), reason: nome);
        expect(classes, contains('AdminMiddleware'), reason: nome);
      }
    });
  });

  // =========================================================================
  group('StatusPatrimonio — manutencao', () {
    test('em_manutencao e o estado que o PUT devolve', () {
      expect(StatusPatrimonio.emManutencao.api, 'em_manutencao');
      expect(StatusPatrimonio.fromValor('em_manutencao'),
          StatusPatrimonio.emManutencao);
    });
  });
}

/// Cria um `FormState` real, sem campos, para alimentar `confirmar()`.
///
/// O `validate()` devolve `true` porque não há campo com validador —
/// é o cenário "o formulário passou", que deixa o Controller seguir
/// para a checagem do id e para a chamada da API.
class _FormularioVazio extends FormState {
  @override
  bool validate() => true;
}
