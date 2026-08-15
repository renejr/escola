class Professor {
  final String id;
  final String nome;
  final String email;
  final String? celular;
  final bool? ativo;

  Professor({
    required this.id,
    required this.nome,
    required this.email,
    this.celular,
    this.ativo,
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      celular: json['celular'],
      ativo: json['ativo'] ?? true,
    );
  }
}
