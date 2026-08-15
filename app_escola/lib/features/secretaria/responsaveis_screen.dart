import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:dio/dio.dart';
import 'models/responsavel.dart';
import 'repositories/responsaveis_repository.dart';

import '../../core/widgets/main_layout.dart';

class ResponsaveisScreen extends StatefulWidget {
  const ResponsaveisScreen({super.key});

  @override
  State<ResponsaveisScreen> createState() => _ResponsaveisScreenState();
}

class _ResponsaveisScreenState extends State<ResponsaveisScreen> {
  final ResponsaveisRepository _repository = ResponsaveisRepository();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Responsavel> _responsaveis = [];
  List<Responsavel> _filteredResponsaveis = [];

  @override
  void initState() {
    super.initState();
    _loadResponsaveis();
    _searchController.addListener(_filterResponsaveis);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResponsaveis() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getResponsaveis();
      if (mounted) {
        setState(() {
          _responsaveis = data;
          _filteredResponsaveis = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar responsáveis: $e')),
        );
      }
    }
  }

  void _filterResponsaveis() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredResponsaveis = _responsaveis.where((r) {
        return r.nome.toLowerCase().contains(query) || 
               r.cpf.replaceAll(RegExp(r'[^0-9]'), '').contains(query.replaceAll(RegExp(r'[^0-9]'), ''));
      }).toList();
    });
  }

  Future<void> _deleteResponsavel(Responsavel responsavel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Responsável'),
        content: Text('Tem certeza que deseja excluir ${responsavel.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && responsavel.id != null) {
      try {
        await _repository.deleteResponsavel(responsavel.id!);
        _loadResponsaveis();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Responsável excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _showFormModal([Responsavel? responsavel]) {
    showDialog(
      context: context,
      builder: (context) => _ResponsavelFormModal(
        responsavel: responsavel,
        repository: _repository,
        onSaved: _loadResponsaveis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Gestão de Responsáveis'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por Nome ou CPF',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _showFormModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Responsável'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SpinKitThreeBounce(
                        color: theme.colorScheme.primary,
                        size: 30.0,
                      ),
                    )
                  : _filteredResponsaveis.isEmpty
                      ? const Center(child: Text('Nenhum responsável encontrado.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return ListView.builder(
                                itemCount: _filteredResponsaveis.length,
                                itemBuilder: (context, index) {
                                  final r = _filteredResponsaveis[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${r.cpf}\n${r.celular}\n${r.email}'),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showFormModal(r),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteResponsavel(r),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return Card(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Nome')),
                                    DataColumn(label: Text('CPF')),
                                    DataColumn(label: Text('Celular')),
                                    DataColumn(label: Text('E-mail')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Ações')),
                                  ],
                                  rows: _filteredResponsaveis.map((r) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(r.nome)),
                                        DataCell(Text(r.cpf)),
                                        DataCell(Text(r.celular)),
                                        DataCell(Text(r.email)),
                                        DataCell(
                                          Chip(
                                            label: Text(r.ativo ? 'Ativo' : 'Inativo', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                            backgroundColor: r.ativo ? Colors.green : Colors.grey,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _showFormModal(r),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () => _deleteResponsavel(r),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsavelFormModal extends StatefulWidget {
  final Responsavel? responsavel;
  final ResponsaveisRepository repository;
  final VoidCallback onSaved;

  const _ResponsavelFormModal({
    this.responsavel,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<_ResponsavelFormModal> createState() => _ResponsavelFormModalState();
}

class _ResponsavelFormModalState extends State<_ResponsavelFormModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _celularFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

  bool _isLoading = false;
  bool _isFetchingCep = false;
  String? _fotoUrl;
  String? _comprovanteUrl;

  @override
  void initState() {
    super.initState();
    if (widget.responsavel != null) {
      final r = widget.responsavel!;
      _nomeController.text = r.nome;
      _cpfController.text = _cpfFormatter.maskText(r.cpf);
      _emailController.text = r.email;
      _celularController.text = _celularFormatter.maskText(r.celular);
      _cepController.text = r.cep != null ? _cepFormatter.maskText(r.cep!) : '';
      _logradouroController.text = r.logradouro ?? '';
      _numeroController.text = r.numero ?? '';
      _complementoController.text = r.complemento ?? '';
      _bairroController.text = r.bairro ?? '';
      _cidadeController.text = r.cidade ?? '';
      _estadoController.text = r.estado ?? '';
      _fotoUrl = r.fotoUrl;
      _comprovanteUrl = r.comprovanteUrl;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _fetchCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isFetchingCep = true);
    try {
      final response = await Dio().get('https://viacep.com.br/ws/$cleanCep/json/');
      if (response.data != null && response.data['erro'] != true) {
        setState(() {
          _logradouroController.text = response.data['logradouro'] ?? '';
          _bairroController.text = response.data['bairro'] ?? '';
          _cidadeController.text = response.data['localidade'] ?? '';
          _estadoController.text = response.data['uf'] ?? '';
        });
      }
    } catch (e) {
      // Ignorar erros de rede silenciosamente como solicitado
    } finally {
      if (mounted) setState(() => _isFetchingCep = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final responsavel = Responsavel(
      id: widget.responsavel?.id,
      nome: _nomeController.text.trim(),
      cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      email: _emailController.text.trim(),
      celular: _celularController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      cep: _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      fotoUrl: _fotoUrl,
      comprovanteUrl: _comprovanteUrl,
    );

    try {
      if (widget.responsavel == null) {
        await widget.repository.createResponsavel(responsavel);
      } else {
        await widget.repository.updateResponsavel(responsavel);
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Responsável salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.responsavel == null ? 'Novo Responsável' : 'Editar Responsável',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('Dados Pessoais', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cpfController,
                            inputFormatters: [_cpfFormatter],
                            decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _celularController,
                            inputFormatters: [_celularFormatter],
                            decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty || !v.contains('@') ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _cepController,
                            inputFormatters: [_cepFormatter],
                            decoration: InputDecoration(
                              labelText: 'CEP', 
                              border: const OutlineInputBorder(),
                              suffixIcon: _isFetchingCep ? const SizedBox(width: 16, height: 16, child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )) : null,
                            ),
                            onChanged: (val) {
                              if (val.length == 9) _fetchCep(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _logradouroController,
                            decoration: const InputDecoration(labelText: 'Logradouro', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _numeroController,
                            decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _complementoController,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Complemento', 
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _bairroController,
                            decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cidadeController,
                            decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _estadoController,
                            decoration: const InputDecoration(labelText: 'Estado (UF)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Anexos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _fotoUrl = 'mock_url_foto.jpg');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto anexada (Simulação)')));
                          },
                          icon: Icon(_fotoUrl != null ? Icons.check_circle : Icons.camera_alt, 
                                   color: _fotoUrl != null ? Colors.green : null),
                          label: const Text('Anexar Foto'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _comprovanteUrl = 'mock_url_comprovante.pdf');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprovante anexado (Simulação)')));
                          },
                          icon: Icon(_comprovanteUrl != null ? Icons.check_circle : Icons.file_upload,
                                   color: _comprovanteUrl != null ? Colors.green : null),
                          label: const Text('Comprovante'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
