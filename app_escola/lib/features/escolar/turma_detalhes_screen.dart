import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'models/turma.dart';
import 'repositories/turmas_repository.dart';

class TurmaDetalhesScreen extends StatefulWidget {
  final Turma? turma;

  const TurmaDetalhesScreen({super.key, this.turma});

  @override
  State<TurmaDetalhesScreen> createState() => _TurmaDetalhesScreenState();
}

class _TurmaDetalhesScreenState extends State<TurmaDetalhesScreen> {
  final TurmasRepository _repository = TurmasRepository();
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _turnoController = TextEditingController();
  final _anoController = TextEditingController();
  final _salaController = TextEditingController();

  bool _isLoading = false;
  List<TurmaAluno> _alunos = [];
  List<TurmaGrade> _grade = [];
  
  bool get _isEditing => widget.turma != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nomeController.text = widget.turma!.nome;
      _turnoController.text = widget.turma!.turno ?? '';
      _anoController.text = widget.turma!.anoLetivo ?? '';
      _salaController.text = widget.turma!.sala ?? '';
      _loadRelatedData();
    }
  }

  Future<void> _loadRelatedData() async {
    setState(() => _isLoading = true);
    try {
      final alunosData = await _repository.getAlunosDaTurma(widget.turma!.id);
      final gradeData = await _repository.getGradeDaTurma(widget.turma!.id);
      if (mounted) {
        setState(() {
          _alunos = alunosData;
          _grade = gradeData;
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

  Future<void> _saveTurma() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final data = {
        'nome': _nomeController.text.trim(),
        'turno': _turnoController.text.trim(),
        'ano_letivo': _anoController.text.trim(),
        'sala': _salaController.text.trim(),
      };
      
      if (_isEditing) {
        await _repository.updateTurma(widget.turma!.id, data);
      } else {
        await _repository.createTurma(data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma salva com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Detalhes da Turma' : 'Nova Turma'),
          backgroundColor: theme.colorScheme.primaryContainer,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Informações', icon: Icon(Icons.info)),
              Tab(text: 'Alunos', icon: Icon(Icons.people)),
              Tab(text: 'Grade Curricular', icon: Icon(Icons.menu_book)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildAlunosTab(),
            _buildGradeTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _anoController.text.isNotEmpty 
        ? DateTime(int.tryParse(_anoController.text) ?? now.year) 
        : now;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione o Ano Letivo'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
              selectedDate: initialDate,
              onChanged: (DateTime dateTime) {
                setState(() {
                  _anoController.text = dateTime.year.toString();
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Turma *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _turnoController,
                    decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _anoController,
                    readOnly: true,
                    onTap: () => _selectYear(context),
                    decoration: const InputDecoration(
                      labelText: 'Ano Letivo', 
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaController,
              decoration: const InputDecoration(labelText: 'Sala', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveTurma,
                child: _isLoading 
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20) 
                    : const Text('Salvar Informações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunosTab() {
    if (!_isEditing) {
      return const Center(child: Text('Salve a turma primeiro para gerenciar alunos.'));
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_alunos.isEmpty) return const Center(child: Text('Nenhum aluno vinculado a esta turma.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _alunos.length,
      itemBuilder: (context, index) {
        final a = _alunos[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: a.ativo ? Colors.green : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(a.nome),
            subtitle: Text('Matrícula: ${a.matriculaRa ?? "-"}'),
            trailing: Chip(
              label: Text(a.ativo ? 'Ativo' : 'Inativo', style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: a.ativo ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradeTab() {
    if (!_isEditing) {
      return const Center(child: Text('Salve a turma primeiro para gerenciar a grade.'));
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_grade.isEmpty) return const Center(child: Text('Grade curricular vazia.'));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Matéria')),
              DataColumn(label: Text('Professor')),
              DataColumn(label: Text('Carga Horária')),
            ],
            rows: _grade.map((g) {
              return DataRow(
                cells: [
                  DataCell(Text(g.materiaNome, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(g.professorNome ?? 'Não alocado')),
                  DataCell(Text('${g.cargaHoraria}h')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}