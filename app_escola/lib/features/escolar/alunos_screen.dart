import 'package:flutter/material.dart';
import 'escolar_repository.dart';
import 'notas_screen.dart';
import 'frequencia_screen.dart';
import '../../core/widgets/role_guard.dart';

class AlunosScreen extends StatefulWidget {
  final String turmaId;
  final String turmaNome;

  const AlunosScreen({
    super.key,
    required this.turmaId,
    required this.turmaNome,
  });

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  final EscolarRepository _repository = EscolarRepository();
  List<Map<String, dynamic>> _alunos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    setState(() => _isLoading = true);
    try {
      final alunos = await _repository.getAlunos(widget.turmaId);
      if (mounted) {
        setState(() {
          _alunos = alunos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    }
  }

  void _abrirDialogCriarAluno() {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Aluno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(labelText: 'Matrícula'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                final matricula = matriculaController.text.trim();
                
                if (nome.isNotEmpty && matricula.isNotEmpty) {
                  Navigator.pop(context);
                  await _repository.createAluno(nome, matricula, widget.turmaId);
                  _carregarAlunos();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos: ${widget.turmaNome}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Frequência (Chamada)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrequenciaScreen(
                    turmaId: widget.turmaId,
                    turmaNome: widget.turmaNome,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alunos.isEmpty
              ? const Center(child: Text('Nenhum aluno nesta turma.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = _alunos[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(aluno['nome'] ?? ''),
                        subtitle: Text('Matrícula: ${aluno['matricula']}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotasScreen(
                                alunoId: aluno['id'],
                                alunoNome: aluno['nome'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: RoleGuard(
        allowedRoles: const ['admin', 'diretor', 'secretario', 'professor'],
        child: FloatingActionButton(
          onPressed: _abrirDialogCriarAluno,
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
