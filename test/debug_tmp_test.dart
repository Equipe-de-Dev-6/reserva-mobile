import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/patrimonio_form_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/models/patrimonio_criacao_model.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_form_view.dart';

class Fake extends PatrimonioService {
  Fake() : super(ApiClient(SessaoService()));
  Map<String, dynamic>? corpo;
  @override
  Future<PatrimonioCriacaoModel> criar(PatrimonioModel p) async {
    corpo = p.toJson();
    return PatrimonioCriacaoModel(
        mensagem: 'ok', id: 7, codigo: p.codigo,
        status: StatusPatrimonio.disponivel);
  }
}

void main() {
  testWidgets('debug', (tester) async {
    Get.put<SessaoService>(SessaoService()).usuario.value = UsuarioModel(
        nome: 'C', email: 'c@c.com', role: 'admin');
    Get.put<PatrimonioService>(Fake());
    Get.put<PatrimonioFormController>(
        PatrimonioFormController(Get.find<PatrimonioService>()));

    await tester.pumpWidget(
      GetMaterialApp(theme: Tema.claro, home: const PatrimonioFormView()),
    );
    await tester.pumpAndSettle();

    final botao = find.text('Cadastrar bem');
    await tester.scrollUntilVisible(
        botao, 120, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('H corpo enviado: ${Get.find<PatrimonioService>() is Fake ? (Get.find<PatrimonioService>() as Fake).corpo : '?'}');

    // Volta ao topo para os campos (e seus erros) serem reconstruídos.
    final lista = find.byType(Scrollable).first;
    await tester.drag(lista, const Offset(0, 2000));
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('H erro1: ${find.text('Informe o código de tombamento.').evaluate().length}');
    // ignore: avoid_print
    print('H erro2: ${find.text('Informe o nome do bem.').evaluate().length}');
    // ignore: avoid_print
    print('H exception: ${tester.takeException()}');
  });
}