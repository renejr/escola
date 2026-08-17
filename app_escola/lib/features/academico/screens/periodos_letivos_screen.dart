import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/periodos_repository.dart';

class PeriodosLetivosScreen extends StatefulWidget {
  const PeriodosLetivosScreen({super.key});

  @override
  State<PeriodosLetivosScreen> createState() => _PeriodosLetivosScreenState();
}

class _PeriodosLetivosScreenState extends State<PeriodosLetivosScreen> with SingleTickerProviderStateMixin {
  final PeriodosRepository _repository = PeriodosRepository();
  late TabController _tabController;

  bool _isLoading = false;
  List<dynamic> _anos = [];
  List<dynamic> _periodos = [];
  String? _selectedAnoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnos() async {
    setState(() => _isLoading = true);
    try {
      _anos = await _repository.getAnosLetivos();
      if (_anos.isNotEmpty && _selectedAnoId == null) {
        // Seleciona o ativo ou o primeiro
        final ativo = _anos.firstWhere((a) => a['ativo'] == true, orElse: () => _anos.first);
        _selectedAnoId = ativo['id'];
      }
      if (_selectedAnoId != null) {
        await _loadPeriodos(_selectedAnoId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPeriodos(String anoId) async {
    try {
      _periodos = await _repository.getPeriodos(anoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _ativarAno(String id) async {
    setState(() => _isLoading = true);
    try {
      await _repository.ativarAnoLetivo(id);
      await _loadAnos();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAddAnoDialog() {
    final TextEditingController anoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Ano Letivo'),
        content: TextField(
          controller: anoController,
          decoration: const InputDecoration(labelText: 'Ano (ex: 2026)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (anoController.text.length == 4) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _repository.createAnoLetivo(anoController.text);
                  await _loadAnos();
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAddPeriodoDialog() {
    if (_selectedAnoId == null) return;
    
    final TextEditingController nomeController = TextEditingController();
    DateTime? dataInicio;
    DateTime? dataFim;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Novo Período Letivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome (ex: 1º Bimestre)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dataInicio != null ? DateFormat('dd/MM/yyyy').format(dataInicio!) : 'Data Início'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setDialogState(() => dataInicio = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dataFim != null ? DateFormat('dd/MM/yyyy').format(dataFim!) : 'Data Fim'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dataInicio ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setDialogState(() => dataFim = date);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  if (nomeController.text.isNotEmpty && dataInicio != null && dataFim != null) {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      await _repository.createPeriodo(
                        _selectedAnoId!, 
                        nomeController.text, 
                        DateFormat('yyyy-MM-dd').format(dataInicio!), 
                        DateFormat('yyyy-MM-dd').format(dataFim!)
                      );
                      await _loadPeriodos(_selectedAnoId!);
                      setState(() => _isLoading = false);
                    } catch (e) {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildAnosTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _anos.length,
            itemBuilder: (context, index) {
              final ano = _anos[index];
              final isAtivo = ano['ativo'] == true;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAtivo ? Colors.green : Colors.grey,
                    child: Icon(isAtivo ? Icons.check : Icons.calendar_today, color: Colors.white),
                  ),
                  title: Text('Ano Letivo ${ano['ano']}'),
                  subtitle: Text(isAtivo ? 'Ano letivo corrente' : 'Inativo'),
                  trailing: isAtivo 
                    ? const Chip(label: Text('ATIVO', style: TextStyle(fontSize: 10)))
                    : OutlinedButton(
                        onPressed: () => _ativarAno(ano['id']),
                        child: const Text('Ativar este ano'),
                      ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Ano Letivo'),
            onPressed: _showAddAnoDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodosTab() {
    return Column(
      children: [
        if (_anos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Filtrar por Ano Letivo', border: OutlineInputBorder()),
              value: _selectedAnoId,
              items: _anos.map((a) => DropdownMenuItem<String>(
                value: a['id'],
                child: Text(a['ano']),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedAnoId = val;
                    _isLoading = true;
                  });
                  _loadPeriodos(val).then((_) => setState(() => _isLoading = false));
                }
              },
            ),
          ),
        Expanded(
          child: _periodos.isEmpty
            ? const Center(child: Text('Nenhum período cadastrado para este ano.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _periodos.length,
                itemBuilder: (context, index) {
                  final p = _periodos[index];
                  final dtIni = DateTime.parse(p['data_inicio']);
                  final dtFim = DateTime.parse(p['data_fim']);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(p['nome']),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(dtIni)} até ${DateFormat('dd/MM/yyyy').format(dtFim)}'),
                    ),
                  );
                },
              ),
        ),
        if (_selectedAnoId != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Período Letivo'),
              onPressed: _showAddPeriodoDialog,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anos e Períodos Letivos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Anos Letivos', icon: Icon(Icons.event)),
            Tab(text: 'Períodos', icon: Icon(Icons.view_week)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnosTab(),
                _buildPeriodosTab(),
              ],
            ),
    );
  }
}