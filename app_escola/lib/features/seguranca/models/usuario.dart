class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? celular;
  final String papel;
  final bool ativo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.celular,
    required this.papel,
    required this.ativo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Sem Nome',
      email: json['email'] ?? '',
      celular: json['celular'],
      papel: json['papel'] ?? 'usuario',
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'celular': celular,
      'papel': papel,
      'ativo': ativo,
    };
  }
}