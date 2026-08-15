class Turma {
  final String id;
  final String nome;
  final String escolaId;
  final String? turno;
  final String? anoLetivo;
  final String? sala;
  final bool ativo;
  final int totalAlunos;

  Turma({
    required this.id,
    required this.nome,
    required this.escolaId,
    this.turno,
    this.anoLetivo,
    this.sala,
    this.ativo = true,
    this.totalAlunos = 0,
  });

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'],
      nome: json['nome'],
      escolaId: json['escola_id'],
      turno: json['turno'],
      anoLetivo: json['ano_letivo'],
      sala: json['sala'],
      ativo: json['ativo'] ?? true,
      totalAlunos: json['total_alunos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'turno': turno,
      'ano_letivo': anoLetivo,
      'sala': sala,
    };
  }
}

class TurmaAluno {
  final String id;
  final String nome;
  final String? matriculaRa;
  final bool ativo;

  TurmaAluno({
    required this.id,
    required this.nome,
    this.matriculaRa,
    this.ativo = true,
  });

  factory TurmaAluno.fromJson(Map<String, dynamic> json) {
    return TurmaAluno(
      id: json['id'],
      nome: json['nome'],
      matriculaRa: json['matricula_ra'],
      ativo: json['ativo'] ?? true,
    );
  }
}

class TurmaGrade {
  final String id;
  final String materiaNome;
  final String? professorNome;
  final int cargaHoraria;

  TurmaGrade({
    required this.id,
    required this.materiaNome,
    this.professorNome,
    required this.cargaHoraria,
  });

  factory TurmaGrade.fromJson(Map<String, dynamic> json) {
    return TurmaGrade(
      id: json['id'],
      materiaNome: json['materia_nome'],
      professorNome: json['professor_nome'],
      cargaHoraria: json['carga_horaria'],
    );
  }
}