class AlunoResponsavel {
  final String responsavelId;
  final String parentesco;
  final bool financeiro;
  final String? responsavelNome;

  AlunoResponsavel({
    required this.responsavelId,
    required this.parentesco,
    this.financeiro = false,
    this.responsavelNome,
  });

  factory AlunoResponsavel.fromJson(Map<String, dynamic> json) {
    return AlunoResponsavel(
      responsavelId: json['responsavel_id'],
      parentesco: json['parentesco'] ?? '',
      financeiro: json['financeiro'] ?? false,
      responsavelNome: json['responsavel_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responsavel_id': responsavelId,
      'parentesco': parentesco,
      'financeiro': financeiro,
    };
  }
}

class Aluno {
  final String? id;
  final String nome;
  final String dataNascimento;
  final String? cpf;
  final String matriculaRa;
  final String? turmaId;
  final String? turmaNome;
  final String? fotoUrl;
  final bool ativo;
  final List<AlunoResponsavel> responsaveis;

  Aluno({
    this.id,
    required this.nome,
    required this.dataNascimento,
    this.cpf,
    required this.matriculaRa,
    this.turmaId,
    this.turmaNome,
    this.fotoUrl,
    this.ativo = true,
    this.responsaveis = const [],
  });

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'],
      nome: json['nome'] ?? '',
      dataNascimento: json['data_nascimento'] ?? '',
      cpf: json['cpf'],
      matriculaRa: json['matricula_ra'] ?? '',
      turmaId: json['turma_id'],
      turmaNome: json['turma_nome'],
      fotoUrl: json['foto_url'],
      ativo: json['ativo'] ?? true,
      responsaveis: json['responsaveis'] != null 
          ? (json['responsaveis'] as List).map((r) => AlunoResponsavel.fromJson(r)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'data_nascimento': dataNascimento,
      'cpf': cpf,
      'matricula_ra': matriculaRa,
      'turma_id': turmaId,
      'foto_url': fotoUrl,
      'ativo': ativo,
      'responsaveis': responsaveis.map((r) => r.toJson()).toList(),
    };
  }
}
