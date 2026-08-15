class Responsavel {
  final String? id;
  final String nome;
  final String cpf;
  final String email;
  final String celular;
  final String? emergenciaNome;
  final String? emergenciaTelefone;
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? fotoUrl;
  final String? comprovanteUrl;
  final bool ativo;

  Responsavel({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.celular,
    this.emergenciaNome,
    this.emergenciaTelefone,
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.fotoUrl,
    this.comprovanteUrl,
    this.ativo = true,
  });

  factory Responsavel.fromJson(Map<String, dynamic> json) {
    return Responsavel(
      id: json['id'],
      nome: json['nome'] ?? '',
      cpf: json['cpf'] ?? '',
      email: json['email'] ?? '',
      celular: json['celular'] ?? '',
      emergenciaNome: json['emergencia_nome'],
      emergenciaTelefone: json['emergencia_telefone'],
      cep: json['cep'],
      logradouro: json['logradouro'],
      numero: json['numero'],
      complemento: json['complemento'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      fotoUrl: json['foto_url'],
      comprovanteUrl: json['comprovante_url'],
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'celular': celular,
      'emergencia_nome': emergenciaNome,
      'emergencia_telefone': emergenciaTelefone,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'foto_url': fotoUrl,
      'comprovante_url': comprovanteUrl,
      'ativo': ativo,
    };
  }
}
