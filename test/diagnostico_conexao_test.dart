// Testes do **diagnóstico de conexão** da tela de Login.
//
// O "Não foi possível conectar ao servidor" é o problema mais comum de
// desenvolvimento com este projeto: cada pessoa precisa do `api.exe`
// rodando na própria máquina, e o endereço da API muda conforme o
// dispositivo. O botão "Verificar conexão" existe para dizer, na hora,
// **qual endereço** o app está usando e o que a API respondeu.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/auth_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/auth_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/api_erros.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/resultado_diagnostico.dart';
import 'package:reserva_mobile/views/auth/login_view.dart';

import 'helpers/api_client_falso.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  group('ResultadoDiagnostico — a sugestão muda com o endereço', () {
    test('emulador Android (10.0.2.2) tem uma sugestão própria', () {
      final r = ResultadoDiagnostico(
        endereco: 'http://10.0.2.2:8081/api',
        conseguiuConectar: false,
      );
      expect(r.sugestao, contains('10.0.2.2'));
      expect(r.sugestao, contains('api.exe'));
    });

    test('localhost avisa que localhost é o próprio aparelho', () {
      final r = ResultadoDiagnostico(
        endereco: 'http://localhost:8081/api',
        conseguiuConectar: false,
      );
      expect(r.sugestao, contains('localhost'));
    });

    test('conectado, não há sugestão', () {
      const r = ResultadoDiagnostico(
        endereco: 'http://localhost:8081/api',
        conseguiuConectar: true,
        duracao: Duration(milliseconds: 12),
      );
      expect(r.sugestao, isEmpty);
      expect(r.mensagem, contains('12 ms'));
    });
  });

  group('Mensagem de erro de conexão — mostra o endereço', () {
    test('a mensagem de conexão cita a URL tentada', () {
      // Constrói um DioException de conexão como o Dio faria.
      final erro = DioException(
        requestOptions: RequestOptions(
          path: '/auth/login',
          baseUrl: 'http://10.0.2.2:8081/api',
        ),
        type: DioExceptionType.connectionError,
      );

      final mensagem = mensagemDeErro(erro);
      expect(mensagem, contains('10.0.2.2:8081'));
      expect(mensagem, contains('Verificar conexão'));
    });
  });

  group('Tela de Login — botão de diagnóstico', () {
    testWidgets('mostra o endereço e o resultado da verificação',
        (tester) async {
      final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      final api = Get.put<ApiClient>(
        ApiClientFalso((_, caminho, _) async {
          if (caminho == '/health') {
            return {'status': 'ok', 'message': 'API operacional'};
          }
          return <String, dynamic>{};
        }),
        permanent: true,
      );
      Get.put<AuthService>(AuthService(api, sessao), permanent: true);
      final controller =
          Get.put<AuthController>(AuthController(Get.find<AuthService>()));

      await tester.pumpWidget(
        GetMaterialApp(theme: Tema.claro, home: const LoginView()),
      );
      await tester.pump();

      expect(find.text('Verificar conexão com a API'), findsOneWidget);

      await tester.tap(find.text('Verificar conexão com a API'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.diagnostico.value, isNotNull);
      expect(controller.diagnostico.value!.conseguiuConectar, isTrue);
      expect(find.text('API conectada'), findsOneWidget);
      // O endereço em uso aparece na tela.
      expect(find.textContaining('8081'), findsWidgets);
    });

    testWidgets('com a API fora do ar, mostra o endereço e a sugestão',
        (tester) async {
      // Este é o caso que o timetodo板上: o backend não está rodando
      // na máquina de quem está testando.
      final sessao = Get.put<SessaoService>(SessaoService(), permanent: true);
      final api = Get.put<ApiClient>(
        ApiClientFalso((_, caminho, _) async {
          if (caminho == '/health') {
            throw const AppException(
              'Não foi possível conectar ao servidor '
              '(http://localhost:8081/api).',
            );
          }
          return <String, dynamic>{};
        }),
        permanent: true,
      );
      Get.put<AuthService>(AuthService(api, sessao), permanent: true);
      final controller =
          Get.put<AuthController>(AuthController(Get.find<AuthService>()));

      await tester.pumpWidget(
        GetMaterialApp(theme: Tema.claro, home: const LoginView()),
      );
      await tester.pump();

      await tester.tap(find.text('Verificar conexão com a API'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.diagnostico.value, isNotNull);
      expect(controller.diagnostico.value!.conseguiuConectar, isFalse);
      expect(find.text('API não respondeu'), findsOneWidget);
      // O endereço em uso aparece, para o usuário ver onde o app tentou.
      expect(find.textContaining('8081'), findsWidgets);
      // E a sugestão diz o que fazer.
      expect(find.textContaining('api.exe'), findsWidgets);
    });
  });
}
