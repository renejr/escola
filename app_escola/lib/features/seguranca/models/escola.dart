class Escola {
  final String id;
  final String razaoSocial;
  final String cnpj;
  final String nomeFantasia;
  final String? logoUrl;
  final String? corPrimaria;
  final String? telefone;
  final String? emailContato;
  final bool ativo;
  final DateTime? criadoEm;

  Escola({
    required this.id,
    required this.razaoSocial,
    required this.cnpj,
    required this.nomeFantasia,
    this.logoUrl,
    this.corPrimaria,
    this.telefone,
    this.emailContato,
    this.ativo = true,
    this.criadoEm,
  });

  factory Escola.fromJson(Map<String, dynamic> json) {
    // Tratamento seguro para o campo ativo que pode vir como bool ou string
    bool isAtivo = true;
    if (json['ativo'] != null) {
      if (json['ativo'] is bool) {
        isAtivo = json['ativo'];
      } else if (json['ativo'] is String) {
        isAtivo = json['ativo'] == 'true' || json['ativo'] == '1';
      }
    }

    return Escola(
      id: json['id'],
      razaoSocial: json['razao_social'] ?? '',
      cnpj: json['cnpj'] ?? '',
      nomeFantasia: json['nome_fantasia'] ?? '',
      logoUrl: json['logo_url'],
      corPrimaria: json['cor_primaria'],
      telefone: json['telefone'],
      emailContato: json['email_contato'],
      ativo: isAtivo,
      criadoEm: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razao_social': razaoSocial,
      'cnpj': cnpj,
      'nome_fantasia': nomeFantasia,
      'logo_url': logoUrl,
      'cor_primaria': corPrimaria,
      'telefone': telefone,
      'email_contato': emailContato,
    };
  }
}
