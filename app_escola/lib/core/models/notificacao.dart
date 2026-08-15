class Notificacao {
  final String id;
  final String escolaId;
  final String titulo;
  final String mensagem;
  final bool lido;
  final String? turmaId;
  final DateTime criadoEm;

  Notificacao({
    required this.id,
    required this.escolaId,
    required this.titulo,
    required this.mensagem,
    required this.lido,
    this.turmaId,
    required this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      escolaId: json['escola_id'],
      titulo: json['titulo'],
      mensagem: json['mensagem'],
      lido: json['lido'] ?? false,
      turmaId: json['turma_id'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }
}