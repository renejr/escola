import 'package:flutter/material.dart';
import 'escolar_repository.dart';
import 'pdf_service.dart';
import '../../core/widgets/role_guard.dart';

class NotasScreen extends StatefulWidget {
  final String alunoId;
  final String alunoNome;

  const NotasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final EscolarRepository _repository = EscolarRepository();
  List<Map<String, dynamic>> _notas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    setState(() => _isLoading = true);
    try {
      final notas = await _repository.getNotasAluno(widget.alunoId);
      if (mounted) {
        setState(() {
          _notas = notas;
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

  void _abrirDialogCriarNota() {
    final disciplinaController = TextEditingController();
    final notaController = TextEditingController();
    int bimestreSelecionado = 1;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lançar Nota'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: disciplinaController,
                    decoration: const InputDecoration(labelText: 'Disciplina'),
                  ),
                  TextField(
                    controller: notaController,
                    decoration: const InputDecoration(labelText: 'Nota (0 a 10)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: bimestreSelecionado,
                    decoration: const InputDecoration(labelText: 'Bimestre'),
                    items: [1, 2, 3, 4].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$valueº Bimestre'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          bimestreSelecionado = newValue;
                        });
                      }
                    },
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
                    final disciplina = disciplinaController.text.trim();
                    final nota = double.tryParse(notaController.text.replaceAll(',', '.')) ?? -1.0;
                    
                    if (disciplina.isNotEmpty && nota >= 0.0 && nota <= 10.0) {
                      Navigator.pop(context); // Fecha o dialog
                      setState(() => _isLoading = true);
                      
                      try {
                        await _repository.addNota(
                          widget.alunoId, 
                          disciplina, 
                          nota, 
                          bimestreSelecionado,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Nota salva com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _carregarNotas();
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar nota: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preencha os campos corretamente.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas: ${widget.alunoNome}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar Boletim',
            onPressed: () {
              if (_notas.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nenhuma nota para exportar.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              PdfService.gerarECompartilharBoletim(
                nomeAluno: widget.alunoNome,
                notas: _notas,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notas.isEmpty
              ? const Center(child: Text('Nenhuma nota lançada para este aluno.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _notas.length,
                  itemBuilder: (context, index) {
                    final notaInfo = _notas[index];
                    final double valor = notaInfo['valor_nota'] ?? 0.0;
                    final bool aprovado = valor >= 7.0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: aprovado ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            aprovado ? Icons.check : Icons.warning,
                            color: aprovado ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(notaInfo['disciplina'] ?? ''),
                        subtitle: Text('${notaInfo['bimestre']}º Bimestre'),
                        trailing: Text(
                          valor.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: aprovado ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: RoleGuard(
        allowedRoles: const ['admin', 'diretor', 'secretario', 'professor'],
        child: FloatingActionButton(
          onPressed: _abrirDialogCriarNota,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
