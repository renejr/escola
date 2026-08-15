import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'models/aluno.dart';
import 'models/responsavel.dart';
import 'repositories/alunos_repository.dart';
import 'repositories/responsaveis_repository.dart';
import '../escolar/escolar_repository.dart';

import '../../core/widgets/main_layout.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  final AlunosRepository _repository = AlunosRepository();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Aluno> _alunos = [];
  List<Aluno> _filteredAlunos = [];

  @override
  void initState() {
    super.initState();
    _loadAlunos();
    _searchController.addListener(_filterAlunos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlunos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAlunos();
      if (mounted) {
        setState(() {
          _alunos = data;
          _filteredAlunos = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar alunos: $e')),
        );
      }
    }
  }

  void _filterAlunos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAlunos = _alunos.where((a) {
        return a.nome.toLowerCase().contains(query) || 
               a.matriculaRa.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteAluno(Aluno aluno) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Aluno'),
        content: Text('Tem certeza que deseja excluir ${aluno.nome}?'),
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

    if (confirm == true && aluno.id != null) {
      try {
        await _repository.deleteAluno(aluno.id!);
        _loadAlunos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aluno excluído com sucesso')),
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

  void _showFormModal([Aluno? aluno]) {
    showDialog(
      context: context,
      builder: (context) => _AlunoFormModal(
        aluno: aluno,
        repository: _repository,
        onSaved: _loadAlunos,
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
        title: const Text('Gestão de Alunos'),
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
                      hintText: 'Buscar por Nome ou Matrícula',
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
                  label: const Text('Novo Aluno'),
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
                  : _filteredAlunos.isEmpty
                      ? const Center(child: Text('Nenhum aluno encontrado.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return ListView.builder(
                                itemCount: _filteredAlunos.length,
                                itemBuilder: (context, index) {
                                  final a = _filteredAlunos[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Matrícula: ${a.matriculaRa}\nTurma: ${a.turmaNome ?? 'Não vinculada'}'),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showFormModal(a),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteAluno(a),
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
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Nome')),
                                    DataColumn(label: Text('Matrícula/RA')),
                                    DataColumn(label: Text('Turma')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Ações')),
                                  ],
                                  rows: _filteredAlunos.map((a) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(a.nome)),
                                        DataCell(Text(a.matriculaRa)),
                                        DataCell(Text(a.turmaNome ?? 'Não vinculada')),
                                        DataCell(
                                          Chip(
                                            label: Text(a.ativo ? 'Ativo' : 'Inativo', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                            backgroundColor: a.ativo ? Colors.green : Colors.grey,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _showFormModal(a),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () => _deleteAluno(a),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                                ),
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

class _AlunoFormModal extends StatefulWidget {
  final Aluno? aluno;
  final AlunosRepository repository;
  final VoidCallback onSaved;

  const _AlunoFormModal({
    this.aluno,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<_AlunoFormModal> createState() => _AlunoFormModalState();
}

class _AlunoFormModalState extends State<_AlunoFormModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _dataNascController = TextEditingController();
  final _cpfController = TextEditingController();
  final _matriculaController = TextEditingController();
  
  final _dataFormatter = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

  final EscolarRepository _turmasRepository = EscolarRepository();
  final ResponsaveisRepository _responsaveisRepository = ResponsaveisRepository();
  
  List<Map<String, dynamic>> _turmas = [];
  List<Responsavel> _todosResponsaveis = [];
  
  String? _selectedTurmaId;
  List<AlunoResponsavel> _responsaveisVinculados = [];

  bool _isLoading = false;
  bool _isLoadingDeps = true;

  @override
  void initState() {
    super.initState();
    _loadDependencies().then((_) {
      if (widget.aluno != null) {
        final a = widget.aluno!;
        _nomeController.text = a.nome;
        
        // Format YYYY-MM-DD to DD/MM/YYYY
        if (a.dataNascimento.isNotEmpty) {
          try {
            final parts = a.dataNascimento.split('-');
            if (parts.length == 3) {
              _dataNascController.text = '${parts[2]}/${parts[1]}/${parts[0]}';
            }
          } catch (_) {}
        }
        
        _cpfController.text = a.cpf != null ? _cpfFormatter.maskText(a.cpf!) : '';
        _matriculaController.text = a.matriculaRa;
        
        if (a.turmaId != null && _turmas.any((t) => t['id'] == a.turmaId)) {
          _selectedTurmaId = a.turmaId;
        }
        
        _responsaveisVinculados = List.from(a.responsaveis);
      }
    });
  }

  Future<void> _loadDependencies() async {
    try {
      final results = await Future.wait([
        _turmasRepository.getTurmas(),
        _responsaveisRepository.getResponsaveis(),
      ]);
      
      if (mounted) {
        setState(() {
          _turmas = results[0] as List<Map<String, dynamic>>;
          _todosResponsaveis = results[1] as List<Responsavel>;
          _isLoadingDeps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDeps = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascController.dispose();
    _cpfController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  void _addResponsavel() {
    String? selectedRespId;
    String parentesco = 'Mãe';
    bool financeiro = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Vincular Responsável'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<Responsavel>(
                    displayStringForOption: (Responsavel r) => '${r.nome} (${r.cpf})',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _todosResponsaveis;
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return _todosResponsaveis.where((r) =>
                        r.nome.toLowerCase().contains(query) ||
                        (r.cpf.contains(query))
                      );
                    },
                    onSelected: (Responsavel data) {
                      setStateModal(() {
                        selectedRespId = data.id;
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Buscar Responsável (Nome ou CPF)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Parentesco', border: OutlineInputBorder()),
                    initialValue: parentesco,
                    items: ['Mãe', 'Pai', 'Avó', 'Avô', 'Tio(a)', 'Responsável Legal', 'Outro']
                        .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) => setStateModal(() => parentesco = val!),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Responsável Financeiro?'),
                    value: financeiro,
                    onChanged: (val) => setStateModal(() => financeiro = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (selectedRespId == null) return;
                    // Verifica se já está vinculado
                    if (_responsaveisVinculados.any((r) => r.responsavelId == selectedRespId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Este responsável já está vinculado!'))
                      );
                      return;
                    }
                    
                    final respModel = _todosResponsaveis.firstWhere((r) => r.id == selectedRespId);
                    
                    setState(() {
                      _responsaveisVinculados.add(AlunoResponsavel(
                        responsavelId: selectedRespId!,
                        parentesco: parentesco,
                        financeiro: financeiro,
                        responsavelNome: respModel.nome,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Parse Date DD/MM/YYYY to YYYY-MM-DD
    String parsedDate = '';
    try {
      final parts = _dataNascController.text.split('/');
      parsedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de nascimento inválida'))
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final aluno = Aluno(
      id: widget.aluno?.id,
      nome: _nomeController.text.trim(),
      dataNascimento: parsedDate,
      cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      matriculaRa: _matriculaController.text.trim(),
      turmaId: _selectedTurmaId,
      responsaveis: _responsaveisVinculados,
    );

    try {
      if (widget.aluno == null) {
        await widget.repository.createAluno(aluno);
      } else {
        await widget.repository.updateAluno(aluno);
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno salvo com sucesso!')),
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
    if (_isLoadingDeps) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados...'),
            ],
          ),
        ),
      );
    }

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
                    widget.aluno == null ? 'Novo Aluno' : 'Editar Aluno',
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
                    const Text('Dados do Aluno', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                            controller: _dataNascController,
                            inputFormatters: [_dataFormatter],
                            decoration: const InputDecoration(labelText: 'Data de Nascimento', hintText: 'DD/MM/AAAA', border: OutlineInputBorder()),
                            validator: (v) => v!.length != 10 ? 'Data inválida' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cpfController,
                            inputFormatters: [_cpfFormatter],
                            decoration: const InputDecoration(labelText: 'CPF (Opcional)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _matriculaController,
                            decoration: const InputDecoration(labelText: 'Matrícula / RA', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Turma', border: OutlineInputBorder()),
                    initialValue: _selectedTurmaId,
                    items: [
                              const DropdownMenuItem<String>(value: null, child: Text('Sem turma vinculada')),
                              ..._turmas.map((t) => DropdownMenuItem<String>(
                                value: t['id'] as String?,
                                child: Text(t['nome'].toString()),
                              ))
                            ],
                            onChanged: (val) => setState(() => _selectedTurmaId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Responsáveis Vinculados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        TextButton.icon(
                          onPressed: _addResponsavel,
                          icon: const Icon(Icons.add_link),
                          label: const Text('Vincular'),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    _responsaveisVinculados.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhum responsável vinculado a este aluno.', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _responsaveisVinculados.length,
                          itemBuilder: (context, index) {
                            final resp = _responsaveisVinculados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(resp.financeiro ? Icons.monetization_on : Icons.person, color: resp.financeiro ? Colors.green : Colors.grey),
                                title: Text(resp.responsavelNome ?? 'Responsável ID: ${resp.responsavelId}'),
                                subtitle: Text('${resp.parentesco}${resp.financeiro ? ' (Financeiro)' : ''}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _responsaveisVinculados.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
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
