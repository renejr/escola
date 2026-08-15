import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'models/turma.dart';
import 'repositories/turmas_repository.dart';
import 'turma_detalhes_screen.dart';
import '../../core/widgets/main_layout.dart';

class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  final TurmasRepository _repository = TurmasRepository();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Turma> _turmas = [];
  List<Turma> _filteredTurmas = [];

  @override
  void initState() {
    super.initState();
    _loadTurmas();
    _searchController.addListener(_filterTurmas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTurmas() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getTurmas();
      if (mounted) {
        setState(() {
          _turmas = data;
          _filteredTurmas = data;
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

  void _filterTurmas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTurmas = _turmas.where((t) {
        return t.nome.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToDetails(Turma? turma) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TurmaDetalhesScreen(turma: turma),
      ),
    );
    if (result == true) {
      _loadTurmas();
    }
  }

  void _toggleStatus(Turma t) async {
    setState(() => _isLoading = true);
    try {
      await _repository.toggleStatus(t.id, !t.ativo);
      _loadTurmas();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        title: const Text('Gestão de Turmas'),
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
                      hintText: 'Buscar por Nome da Turma...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _navigateToDetails(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova Turma'),
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
                  : _filteredTurmas.isEmpty
                      ? const Center(child: Text('Nenhuma turma encontrada.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return ListView.builder(
                                itemCount: _filteredTurmas.length,
                                itemBuilder: (context, index) {
                                  final t = _filteredTurmas[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Turno: ${t.turno ?? "-"} | Ano: ${t.anoLetivo ?? "-"}'),
                                          Text('Alunos: ${t.totalAlunos}'),
                                          Text('Status: ${t.ativo ? "Ativa" : "Inativa"}'),
                                        ],
                                      ),
                                      onTap: () => _navigateToDetails(t),
                                      trailing: IconButton(
                                        icon: Icon(
                                          t.ativo ? Icons.block : Icons.check_circle,
                                          color: t.ativo ? Colors.red : Colors.green,
                                        ),
                                        onPressed: () => _toggleStatus(t),
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
                                      DataColumn(label: Text('Nome da Turma')),
                                      DataColumn(label: Text('Turno')),
                                      DataColumn(label: Text('Ano Letivo')),
                                      DataColumn(label: Text('Total de Alunos')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Ações')),
                                    ],
                                    rows: _filteredTurmas.map((t) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(t.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          DataCell(Text(t.turno ?? '-')),
                                          DataCell(Text(t.anoLetivo ?? '-')),
                                          DataCell(Text('${t.totalAlunos}')),
                                          DataCell(
                                            Chip(
                                              label: Text(t.ativo ? 'Ativa' : 'Inativa', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                              backgroundColor: t.ativo ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                  onPressed: () => _navigateToDetails(t),
                                                  tooltip: 'Editar/Detalhes',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    t.ativo ? Icons.block : Icons.check_circle,
                                                    color: t.ativo ? Colors.red : Colors.green,
                                                    size: 20
                                                  ),
                                                  onPressed: () => _toggleStatus(t),
                                                  tooltip: t.ativo ? 'Inativar' : 'Ativar',
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