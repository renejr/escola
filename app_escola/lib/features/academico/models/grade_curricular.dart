class GradeCurricular {
  final String id;
  final String materiaId;
  final String materiaNome;
  final String turmaId;
  final String professorId;
  final int cargaHoraria;
  final bool ativo;

  GradeCurricular({
    required this.id,
    required this.materiaId,
    required this.materiaNome,
    required this.turmaId,
    required this.professorId,
    required this.cargaHoraria,
    required this.ativo,
  });

  factory GradeCurricular.fromJson(Map<String, dynamic> json) {
    return GradeCurricular(
      id: json['id'],
      materiaId: json['materia_id'],
      materiaNome: json['materia_nome'],
      turmaId: json['turma_id'],
      professorId: json['professor_id'],
      cargaHoraria: json['carga_horaria'],
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia_id': materiaId,
      'materia_nome': materiaNome,
      'turma_id': turmaId,
      'professor_id': professorId,
      'carga_horaria': cargaHoraria,
      'ativo': ativo,
    };
  }
}
