import 'package:flutter/material.dart';
import '../../core/widgets/main_layout.dart';
import 'models/materia.dart';
import 'models/grade_curricular.dart';
import 'models/professor.dart';
import 'repositories/materias_repository.dart';
import 'repositories/grade_repository.dart';
import 'repositories/professor_repository.dart';
import '../escolar/escolar_repository.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final MateriasRepository _materiasRepo = MateriasRepository();
  final GradeRepository _gradeRepo = GradeRepository();
  final EscolarRepository _turmasRepo = EscolarRepository();
  final ProfessorRepository _professorRepo = ProfessorRepository();

  bool _isLoading = true;

  List<Materia> _materias = [];
  List<Materia> _materiasFiltradas = [];
  final TextEditingController _buscaController = TextEditingController();

  List<Map<String, dynamic>> _turmas = [];
  String? _selectedTurmaId;
  List<GradeCurricular> _grade = [];

  List<Professor> _professores = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _materiasRepo.getMaterias(),
        _turmasRepo.getTurmas(),
        _professorRepo.getProfessores(),
      ]);

      if (mounted) {
        setState(() {
          _materias = results[0] as List<Materia>;
          _materiasFiltradas = _materias;
          _turmas = results[1] as List<Map<String, dynamic>>;
          _professores = results[2] as List<Professor>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _carregarGrade() async {
    if (_selectedTurmaId == null) return;
    setState(() => _isLoading = true);
    try {
      final grade = await _gradeRepo.getGradePorTurma(_selectedTurmaId!);
      if (mounted) {
        setState(() {
          _grade = grade;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filtrarMaterias(String query) {
    setState(() {
      _materiasFiltradas = _materias
          .where((m) => m.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showModalMateria() async {
    final formKey = GlobalKey<FormState>();
    String nome = '';
    String? area;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova Matéria'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nome da Matéria', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  onSaved: (v) => nome = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Área de Conhecimento (Opcional)', border: OutlineInputBorder()),
                  onSaved: (v) => area = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(dialogContext);
                  setState(() => _isLoading = true);
                  try {
                    await _materiasRepo.createMateria(nome, area);
                    await _carregarDadosIniciais();
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showModalGrade() async {
    if (_selectedTurmaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma turma primeiro.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? materiaId;
    String? professorId;
    int carga = 0;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar à Grade'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Matéria', border: OutlineInputBorder()),
                  items: _materias.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome))).toList(),
                  validator: (v) => v == null ? 'Selecione uma matéria' : null,
                  onChanged: (v) => materiaId = v,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Professor', border: OutlineInputBorder()),
                  items: _professores.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome))).toList(),
                  validator: (v) => v == null ? 'Selecione um professor' : null,
                  onChanged: (v) => professorId = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Carga Horária', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    if (int.tryParse(v) == null) return 'Apenas números';
                    return null;
                  },
                  onSaved: (v) => carga = int.parse(v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(dialogContext);
                  setState(() => _isLoading = true);
                  try {
                    await _gradeRepo.adicionarMateriaNaGrade(_selectedTurmaId!, materiaId!, professorId!, carga);
                    await _carregarGrade();
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          title: const Text('Grade de Matérias'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Catálogo de Matérias'),
              Tab(text: 'Grade Curricular'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAbaMaterias(),
                  _buildAbaGrade(),
                ],
              ),
      ),
    );
  }

  Widget _buildAbaMaterias() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar Matéria',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filtrarMaterias,
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _showModalMateria,
                icon: const Icon(Icons.add),
                label: const Text('Nova Matéria'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _materiasFiltradas.length,
              itemBuilder: (listContext, index) {
                final mat = _materiasFiltradas[index];
                return Card(
                  child: ListTile(
                    title: Text(mat.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Área: ${mat.areaConhecimento ?? "Não informada"}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          await _materiasRepo.deleteMateria(mat.id);
                          await _carregarDadosIniciais();
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaGrade() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Selecione uma Turma'),
                  value: _selectedTurmaId,
                  items: _turmas.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['nome'] as String))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTurmaId = val;
                    });
                    _carregarGrade();
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _selectedTurmaId == null ? null : _showModalGrade,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar à Grade'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedTurmaId == null)
            const Expanded(
              child: Center(child: Text('Selecione uma turma para ver sua grade curricular.')),
            )
          else if (_grade.isEmpty)
            const Expanded(
              child: Center(child: Text('Nenhuma matéria cadastrada na grade desta turma.')),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32), // -32 for padding
                    child: DataTable(
                      columns: const [
                    DataColumn(label: Text('Matéria')),
                    DataColumn(label: Text('Carga Horária')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: _grade.map((g) {
                    return DataRow(
                      cells: [
                        DataCell(Text(g.materiaNome)),
                        DataCell(Text('${g.cargaHoraria}h')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              try {
                                await _gradeRepo.removerMateriaDaGrade(g.id);
                                await _carregarGrade();
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
