class Materia {
  final String id;
  final String escolaId;
  final String nome;
  final String? areaConhecimento;
  final bool ativo;

  Materia({
    required this.id,
    required this.escolaId,
    required this.nome,
    this.areaConhecimento,
    required this.ativo,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'],
      escolaId: json['escola_id'],
      nome: json['nome'],
      areaConhecimento: json['area_conhecimento'],
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'escola_id': escolaId,
      'nome': nome,
      'area_conhecimento': areaConhecimento,
      'ativo': ativo,
    };
  }
}
