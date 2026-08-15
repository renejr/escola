import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../seguranca/models/escola.dart';
import 'repositories/super_admin_repository.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final SuperAdminRepository _repository = SuperAdminRepository();
  bool _isLoading = true;
  int _totalAtivas = 0;
  int _totalInativas = 0;
  List<Escola> _escolas = [];

  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
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
      final kpis = await _repository.getKpis();
      final escolas = await _repository.getEscolas();
      if (mounted) {
        setState(() {
          _totalAtivas = kpis['ativas'] ?? 0;
          _totalInativas = kpis['inativas'] ?? 0;
          _escolas = escolas;
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

  void _showFormModal({Escola? escola}) {
    final isEditing = escola != null;
    final formKey = GlobalKey<FormState>();
    final razaoController = TextEditingController(text: escola?.razaoSocial);
    final fantasiaController = TextEditingController(text: escola?.nomeFantasia);
    final cnpjController = TextEditingController(text: isEditing ? _cnpjMask.maskText(escola.cnpj) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Editar Tenant (Escola)' : 'Provisionar Nova Escola',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: razaoController,
                  decoration: const InputDecoration(labelText: 'Razão Social', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: fantasiaController,
                  decoration: const InputDecoration(labelText: 'Nome Fantasia', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cnpjController,
                  inputFormatters: [_cnpjMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final unmaskedCnpj = _cnpjMask.getUnmaskedText();
                      final novaEscola = Escola(
                        id: escola?.id ?? '',
                        razaoSocial: razaoController.text,
                        nomeFantasia: fantasiaController.text,
                        cnpj: unmaskedCnpj,
                      );
                      
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      
                      try {
                        if (isEditing) {
                          await _repository.updateEscola(escola.id, novaEscola);
                        } else {
                          await _repository.createEscola(novaEscola);
                        }
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? 'Escola atualizada' : 'Escola provisionada')),
                          );
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: $e')),
                          );
                        }
                      }
                    },
                    child: Text(isEditing ? 'Salvar Alterações' : 'Provisionar Escola'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleStatus(Escola escola) async {
    setState(() => _isLoading = true);
    try {
      await _repository.toggleStatus(escola.id);
      await _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alterar status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormModal(),
        icon: const Icon(Icons.add),
        label: const Text('Provisionar Nova Escola'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visão Global de Escolas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Atualizar Dados',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Escolas Ativas', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('$_totalAtivas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Escolas Inativas', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('$_totalInativas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Razão Social')),
                          DataColumn(label: Text('CNPJ')),
                          DataColumn(label: Text('Data de Cadastro')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _escolas.map((escola) {
                          return DataRow(
                            cells: [
                              DataCell(Text(escola.razaoSocial)),
                              DataCell(Text(_cnpjMask.maskText(escola.cnpj))),
                              DataCell(Text(escola.criadoEm != null ? DateFormat('dd/MM/yyyy').format(escola.criadoEm!) : '-')),
                              DataCell(
                                Chip(
                                  label: Text(escola.ativo ? 'Ativo' : 'Inativo'),
                                  backgroundColor: escola.ativo ? Colors.green.shade100 : Colors.red.shade100,
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showFormModal(escola: escola),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        escola.ativo ? Icons.block : Icons.check_circle,
                                        color: escola.ativo ? Colors.red : Colors.green,
                                      ),
                                      onPressed: () => _toggleStatus(escola),
                                      tooltip: escola.ativo ? 'Bloquear/Inativar' : 'Reativar',
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
              ],
            ),
    );
  }
}
