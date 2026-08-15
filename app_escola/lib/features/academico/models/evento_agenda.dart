class EventoAgenda {
  final String id;
  final String escolaId;
  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String tipo;
  final String? turmaId;

  EventoAgenda({
    required this.id,
    required this.escolaId,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.tipo,
    this.turmaId,
  });

  factory EventoAgenda.fromJson(Map<String, dynamic> json) {
    return EventoAgenda(
      id: json['id'],
      escolaId: json['escola_id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: DateTime.parse(json['data_inicio']),
      dataFim: DateTime.parse(json['data_fim']),
      tipo: json['tipo'],
      turmaId: json['turma_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'tipo': tipo,
      'turma_id': turmaId,
    };
  }
}