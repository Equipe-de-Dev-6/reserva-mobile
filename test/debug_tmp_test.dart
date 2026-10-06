import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:reserva_mobile/app/tema.dart';
import 'package:reserva_mobile/controllers/patrimonio_controller.dart';
import 'package:reserva_mobile/core/servicos/api_client.dart';
import 'package:reserva_mobile/core/servicos/patrimonio_service.dart';
import 'package:reserva_mobile/core/servicos/sessao_service.dart';
import 'package:reserva_mobile/core/utils/app_exception.dart';
import 'package:reserva_mobile/models/patrimonio_model.dart';
import 'package:reserva_mobile/models/status_patrimonio.dart';
import 'package:reserva_mobile/models/usuario_model.dart';
import 'package:reserva_mobile/views/patrimonio/patrimonio_lista_view.dart';

class Fake extends PatrimonioService {
  Fake() : super(ApiClient(SessaoService()));
  AppException? erro;

  @override
  Future<List<PatrimonioModel>> listar({
    String? busca,
    StatusPatrimonio? status,
    String? categoria,
    int? professorId,
  }) async {
    if (erro != null) throw erro!;
    return const [
      PatrimonioModel(
          id: 1,
          codigo: 'PAT-2024-001',
          nome: 'Notebook',
          status: StatusPatrimonio.emUso),
    ];
  }
}

void registrar(UsuarioModel usuario, Fake service) {
  Get.delete<SessaoService>(force: true);
  Get.delete<PatrimonioService>(force: true);
  Get.delete<PatrimonioController>(force: true);
  Get.put<SessaoService>(SessaoService()).usuario.value = usuario;
  Get.put<PatrimonioService>(service);
  Get.lazyPut<PatrimonioController>(
      () => PatrimonioController(Get.find<PatrimonioService>()));
}

void main() {
  testWidgets('debug', (tester) async {
    registrar(
      UsuarioModel(nome: 'C', email: 'c@c.com', role: 'admin'),
      Fake(),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(theme: Tema.claro, home: const PatrimonioListaView()),
    );
    await tester.pump();

    // ignore: avoid_print
    print('D skeleton: ${find.byType(ListaSkeletonPatrimonio).evaluate().length}');
    // ignore: avoid_print
    print('D controller carregando: '
        '${Get.find<PatrimonioController>().carregando.value}');
    // ignore: avoid_print
    print('D itens: ${Get.find<PatrimonioController>().patrimonios.length}');
  });
}
