/// Corpo de `POST /api/admin/patrimonios/{id}/atribuir` (RF07b / RN05).
///
/// A atribuição **associa o bem ao professor** e muda o status para
/// `em_uso`. O backend também registra a movimentação no histórico.
///
/// A `observacoes` é opcional e serve para o termo de responsabilidade
/// ("Termo de responsabilidade assinado").
class AtribuirPatrimonioRequestModel {
  final int professorId;
  final String observacoes;

  AtribuirPatrimonioRequestModel({
    required this.professorId,
    this.observacoes = '',
  });

  Map<String, dynamic> toJson() => {
        'professorId': professorId,
        'observacoes': observacoes.trim(),
      };
}

/// Corpo de `POST /api/admin/patrimonios/{id}/desatribuir` (RF07b / RN05).
///
/// A devolução **desvincula o docente** e devolve o bem ao almoxarifado
/// (status `disponivel`). O `motivo` é o texto que o Coordenador registra
/// para explicar a devolução — é ele que aparece na linha do tempo.
class DesatribuirPatrimonioRequestModel {
  final String motivo;

  DesatribuirPatrimonioRequestModel({this.motivo = ''});

  Map<String, dynamic> toJson() => {'motivo': motivo.trim()};
}
