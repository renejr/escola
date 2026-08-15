import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/widgets/main_layout.dart';
import 'models/escola.dart';
import 'repositories/escola_repository.dart';

class EscolaConfigScreen extends StatefulWidget {
  const EscolaConfigScreen({super.key});

  @override
  State<EscolaConfigScreen> createState() => _EscolaConfigScreenState();
}

class _EscolaConfigScreenState extends State<EscolaConfigScreen> {
  final EscolaRepository _repository = EscolaRepository();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  Escola? _escola;

  final _nomeFantasiaController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  String? _logoUrl;
  
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final escola = await _repository.getMinhaInstituicao();
      if (mounted) {
        setState(() {
          _escola = escola;
          _nomeFantasiaController.text = escola.nomeFantasia;
          _razaoSocialController.text = escola.razaoSocial;
          _cnpjController.text = _cnpjMask.maskText(escola.cnpj);
          _emailController.text = escola.emailContato ?? '';
          _telefoneController.text = _phoneMask.maskText(escola.telefone ?? '');
          _logoUrl = escola.logoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_escola == null) return;

    setState(() => _isLoading = true);
    
    final updatedEscola = Escola(
      id: _escola!.id,
      razaoSocial: _razaoSocialController.text,
      cnpj: _cnpjMask.getUnmaskedText(),
      nomeFantasia: _nomeFantasiaController.text,
      emailContato: _emailController.text,
      telefone: _phoneMask.getUnmaskedText(),
      logoUrl: _logoUrl,
      corPrimaria: _escola!.corPrimaria,
    );

    try {
      await _repository.updateMinhaInstituicao(updatedEscola);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _simularAlteracaoLogo() {
    // Simulação para o futuro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Em breve: Upload de imagem!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Dados da Instituição'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seção Identidade Visual
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _logoUrl != null && _logoUrl!.isNotEmpty
                                    ? NetworkImage(_logoUrl!)
                                    : null,
                                child: _logoUrl == null || _logoUrl!.isEmpty
                                    ? const Icon(Icons.apartment, size: 50, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _simularAlteracaoLogo,
                                icon: const Icon(Icons.upload),
                                label: const Text('Alterar Logomarca'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Campos de Texto
                        Text(
                          'Informações Cadastrais',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nomeFantasiaController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Fantasia',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _razaoSocialController,
                          decoration: const InputDecoration(
                            labelText: 'Razão Social',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.gavel),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cnpjController,
                          inputFormatters: [_cnpjMask],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CNPJ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail de Contato',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [_phoneMask],
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar Alterações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
