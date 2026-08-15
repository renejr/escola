import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/widgets/main_layout.dart';
import '../academico/models/professor.dart';
import '../academico/repositories/professor_repository.dart';

class ProfessoresScreen extends StatefulWidget {
  const ProfessoresScreen({super.key});

  @override
  State<ProfessoresScreen> createState() => _ProfessoresScreenState();
}

class _ProfessoresScreenState extends State<ProfessoresScreen> {
  final ProfessorRepository _repository = ProfessorRepository();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Professor> _professores = [];
  List<Professor> _filteredProfessores = [];

  @override
  void initState() {
    super.initState();
    _loadProfessores();
    _searchController.addListener(_filterProfessores);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessores() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getProfessores();
      if (mounted) {
        setState(() {
          _professores = data;
          _filteredProfessores = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterProfessores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProfessores = _professores.where((p) {
        return p.nome.toLowerCase().contains(query) || 
               p.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showFormDialog({Professor? professor}) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ProfessorFormModal(
        professor: professor,
        onSaved: (Map<String, dynamic> data) async {
          setState(() => _isLoading = true);
          try {
            if (professor == null) {
              await _repository.createProfessor(data);
            } else {
              await _repository.updateProfessor(professor.id, data);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Professor salvo com sucesso!'), backgroundColor: Colors.green),
              );
            }
            _loadProfessores();
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmAtivar(Professor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ativar Professor'),
        content: Text('Deseja realmente ativar o professor ${p.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repository.ativarProfessor(p.id);
                _loadProfessores();
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }

  void _confirmInativar(Professor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inativar Professor'),
        content: Text('Deseja realmente inativar o professor ${p.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repository.inativarProfessor(p.id);
                _loadProfessores();
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Inativar'),
          ),
        ],
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
        title: const Text('Gestão de Professores'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por Nome ou E-mail...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Professor'),
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
                  : _filteredProfessores.isEmpty
                      ? const Center(child: Text('Nenhum professor encontrado.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return ListView.builder(
                                itemCount: _filteredProfessores.length,
                                itemBuilder: (context, index) {
                                  final p = _filteredProfessores[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('E-mail: ${p.email}'),
                                          Text('Celular: ${p.celular ?? "-"}'),
                                          Text('Status: ${p.ativo == true ? "Ativo" : "Inativo"}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showFormDialog(professor: p),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              p.ativo == true ? Icons.block : Icons.check_circle, 
                                              color: p.ativo == true ? Colors.red : Colors.green
                                            ),
                                            onPressed: () => p.ativo == true ? _confirmInativar(p) : _confirmAtivar(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            return SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
                                  columns: const [
                                    DataColumn(label: Text('Nome')),
                                    DataColumn(label: Text('E-mail')),
                                    DataColumn(label: Text('Celular')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Ações')),
                                  ],
                                  rows: _filteredProfessores.map((p) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(p.email)),
                                        DataCell(Text(p.celular ?? '-')),
                                        DataCell(
                                          Chip(
                                            label: Text(p.ativo == true ? 'Ativo' : 'Inativo', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                            backgroundColor: p.ativo == true ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _showFormDialog(professor: p),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  p.ativo == true ? Icons.block : Icons.check_circle,
                                                  color: p.ativo == true ? Colors.red : Colors.green,
                                                  size: 20
                                                ),
                                                onPressed: () => p.ativo == true ? _confirmInativar(p) : _confirmAtivar(p),
                                                tooltip: p.ativo == true ? 'Inativar' : 'Ativar',
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

class _ProfessorFormModal extends StatefulWidget {
  final Professor? professor;
  final Function(Map<String, dynamic>) onSaved;

  const _ProfessorFormModal({this.professor, required this.onSaved});

  @override
  State<_ProfessorFormModal> createState() => _ProfessorFormModalState();
}

class _ProfessorFormModalState extends State<_ProfessorFormModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _celularFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    if (widget.professor != null) {
      final p = widget.professor!;
      _nomeController.text = p.nome;
      _emailController.text = p.email;
      if (p.celular != null) {
        _celularController.text = _celularFormatter.maskText(p.celular!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.professor == null ? 'Novo Professor' : 'Editar Professor'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.professor == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Uma senha provisória será enviada para o e-mail cadastrado.',
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpfController,
                  inputFormatters: [_cpfFormatter],
                  decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                  validator: (v) {
                    if (widget.professor == null && (v == null || v.isEmpty)) {
                      return 'Obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail (Login)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _celularController,
                  inputFormatters: [_celularFormatter],
                  decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onSaved({
                'nome': _nomeController.text.trim(),
                'cpf': _cpfFormatter.getUnmaskedText(),
                'email': _emailController.text.trim(),
                'celular': _celularFormatter.getUnmaskedText(),
              });
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}