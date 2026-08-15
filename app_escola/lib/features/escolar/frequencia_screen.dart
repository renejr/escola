import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'escolar_repository.dart';
import '../../core/widgets/role_guard.dart';

class FrequenciaScreen extends StatefulWidget {
  final String turmaId;
  final String turmaNome;

  const FrequenciaScreen({
    super.key,
    required this.turmaId,
    required this.turmaNome,
  });

  @override
  State<FrequenciaScreen> createState() => _FrequenciaScreenState();
}

class _FrequenciaScreenState extends State<FrequenciaScreen> {
  final EscolarRepository _repository = EscolarRepository();
  List<Map<String, dynamic>> _alunos = [];
  Map<String, String> _frequenciaStatus = {}; // alunoId -> status ('presente', 'ausente', 'justificada')
  DateTime _dataSelecionada = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  String _formatarDataParaApi(DateTime data) {
    return DateFormat('yyyy-MM-dd').format(data);
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      // Carrega os alunos da turma
      final alunos = await _repository.getAlunos(widget.turmaId);
      
      // Carrega a frequência para a data selecionada
      final dataStr = _formatarDataParaApi(_dataSelecionada);
      final frequenciasAnteriores = await _repository.getFrequencia(widget.turmaId, dataStr);

      final Map<String, String> novoStatus = {};
      
      // Inicializa todos como 'presente' por padrão
      for (var aluno in alunos) {
        novoStatus[aluno['id']] = 'presente';
      }

      // Sobrescreve com os dados do banco se já existirem
      for (var freq in frequenciasAnteriores) {
        if (freq['aluno_id'] != null && freq['status'] != null) {
          novoStatus[freq['aluno_id']] = freq['status'];
        }
      }

      if (mounted) {
        setState(() {
          _alunos = alunos;
          _frequenciaStatus = novoStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
      _carregarDados(); // Recarrega os dados para a nova data
    }
  }

  Future<void> _salvarChamada() async {
    setState(() => _isSaving = true);
    
    final List<Map<String, dynamic>> frequenciasPayload = _frequenciaStatus.entries.map((e) {
      return {
        'aluno_id': e.key,
        'status': e.value,
      };
    }).toList();

    try {
      final dataStr = _formatarDataParaApi(_dataSelecionada);
      await _repository.registrarFrequencia(widget.turmaId, dataStr, frequenciasPayload);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamada salva com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar chamada: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frequência: ${widget.turmaNome}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          // Cabeçalho com o Seletor de Data
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selecionarData(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Alterar'),
                ),
              ],
            ),
          ),
          
          // Lista de Alunos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alunos.isEmpty
                    ? const Center(child: Text('Nenhum aluno cadastrado nesta turma.'))
                    : ListView.builder(
                        itemCount: _alunos.length,
                        itemBuilder: (context, index) {
                          final aluno = _alunos[index];
                          final alunoId = aluno['id'];
                          final status = _frequenciaStatus[alunoId] ?? 'presente';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aluno['nome'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment<String>(
                                        value: 'presente',
                                        label: Text('Presente'),
                                        icon: Icon(Icons.check_circle_outline),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'ausente',
                                        label: Text('Ausente'),
                                        icon: Icon(Icons.cancel_outlined),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'justificada',
                                        label: Text('Justificada'),
                                        icon: Icon(Icons.info_outline),
                                      ),
                                    ],
                                    selected: {status},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      setState(() {
                                        _frequenciaStatus[alunoId] = newSelection.first;
                                      });
                                    },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: RoleGuard(
        allowedRoles: const ['admin', 'diretor', 'secretario', 'professor'],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: _isSaving || _alunos.isEmpty ? null : _salvarChamada,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Salvar Chamada', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}