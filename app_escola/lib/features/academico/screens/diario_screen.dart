import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/diario_repository.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> with SingleTickerProviderStateMixin {
  final DiarioRepository _repository = DiarioRepository();
  late TabController _tabController;

  bool _isLoadingFilters = true;
  bool _isLoadingData = false;

  List<dynamic> _periodos = [];
  List<dynamic> _turmas = [];
  List<dynamic> _materias = [];
  List<dynamic> _alunos = [];

  String? _selectedPeriodoId;
  String? _selectedTurmaId;
  String? _selectedMateriaId;

  // Frequência state
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _frequenciaStatus = {}; // aluno_id -> presente
  Timer? _frequenciaDebounce;

  // Notas state
  final List<String> _tiposAvaliacao = ['Nota 1', 'Nota 2', 'Nota 3', 'Recuperação'];
  Map<String, Map<String, double>> _notasStatus = {}; // aluno_id -> {tipo -> nota}
  Timer? _notasDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _frequenciaDebounce?.cancel();
    _notasDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final futures = await Future.wait([
        _repository.getPeriodosLetivos(),
        _repository.getTurmas(),
        _repository.getMaterias(),
      ]);

      setState(() {
        _periodos = futures[0];
        _turmas = futures[1];
        _materias = futures[2];

        if (_periodos.isNotEmpty) _selectedPeriodoId = _periodos.first['id'];
        if (_turmas.isNotEmpty) _selectedTurmaId = _turmas.first['id'];
        if (_materias.isNotEmpty) _selectedMateriaId = _materias.first['id'];
        
        _isLoadingFilters = false;
      });

      if (_selectedTurmaId != null && _selectedMateriaId != null) {
        _loadData();
      }
    } catch (e) {
      setState(() => _isLoadingFilters = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar filtros: $e')));
      }
    }
  }

  Future<void> _loadData() async {
    if (_selectedTurmaId == null || _selectedMateriaId == null || _selectedPeriodoId == null) return;

    setState(() => _isLoadingData = true);
    
    try {
      // Load Alunos
      _alunos = await _repository.getAlunosPorTurma(_selectedTurmaId!);
      
      // Load Frequência
      final freqData = await _repository.getFrequencia(
        _selectedTurmaId!, 
        _selectedMateriaId!, 
        DateFormat('yyyy-MM-dd').format(_selectedDate)
      );
      
      _frequenciaStatus.clear();
      for (var aluno in _alunos) {
        _frequenciaStatus[aluno['id']] = true; // default present
      }
      for (var item in freqData) {
        _frequenciaStatus[item['aluno_id']] = item['presente'];
      }

      // Load Notas
      final notasData = await _repository.getNotas(
        _selectedTurmaId!, 
        _selectedMateriaId!, 
        _selectedPeriodoId!
      );
      
      _notasStatus.clear();
      for (var item in notasData) {
        final aId = item['aluno_id'];
        final tAv = item['tipo_avaliacao'];
        final val = double.parse(item['valor_nota'].toString());
        
        if (!_notasStatus.containsKey(aId)) {
          _notasStatus[aId] = {};
        }
        _notasStatus[aId]![tAv] = val;
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  void _onFrequenciaChanged(String alunoId, bool presente) {
    // Optimistic UI update
    setState(() {
      _frequenciaStatus[alunoId] = presente;
    });

    // Debounce to save bulk
    if (_frequenciaDebounce?.isActive ?? false) _frequenciaDebounce!.cancel();
    _frequenciaDebounce = Timer(const Duration(milliseconds: 1500), () {
      _saveFrequenciaBulk();
    });
  }

  Future<void> _saveFrequenciaBulk() async {
    if (_selectedTurmaId == null || _selectedMateriaId == null) return;
    
    final payload = {
      'turma_id': _selectedTurmaId,
      'materia_id': _selectedMateriaId,
      'data_aula': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'frequencias': _frequenciaStatus.entries.map((e) => {
        'aluno_id': e.key,
        'presente': e.value,
      }).toList(),
    };

    try {
      await _repository.saveFrequenciaBulk(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frequência salva com sucesso!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar frequência: $e')));
      }
    }
  }

  void _onNotaChanged(String alunoId, String tipoAvaliacao, String valueStr) {
    double? nota = double.tryParse(valueStr.replaceAll(',', '.'));
    if (nota == null) return;

    // Optimistic UI update
    if (!_notasStatus.containsKey(alunoId)) {
      _notasStatus[alunoId] = {};
    }
    _notasStatus[alunoId]![tipoAvaliacao] = nota;

    // Debounce to save bulk
    if (_notasDebounce?.isActive ?? false) _notasDebounce!.cancel();
    _notasDebounce = Timer(const Duration(milliseconds: 1500), () {
      _saveNotasBulk();
    });
  }

  Future<void> _saveNotasBulk() async {
    if (_selectedTurmaId == null || _selectedMateriaId == null || _selectedPeriodoId == null) return;
    
    List<Map<String, dynamic>> notasList = [];
    for (var entry in _notasStatus.entries) {
      String alunoId = entry.key;
      for (var avalEntry in entry.value.entries) {
        notasList.add({
          'aluno_id': alunoId,
          'tipo_avaliacao': avalEntry.key,
          'valor_nota': avalEntry.value,
        });
      }
    }

    if (notasList.isEmpty) return;

    final payload = {
      'turma_id': _selectedTurmaId,
      'materia_id': _selectedMateriaId,
      'periodo_letivo_id': _selectedPeriodoId,
      'notas': notasList,
    };

    try {
      await _repository.saveNotasBulk(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notas salvas com sucesso!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar notas: $e')));
      }
    }
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              hint: const Text('Período Letivo'),
              value: _selectedPeriodoId,
              items: _periodos.map((p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(p['nome']),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedPeriodoId = val);
                _loadData();
              },
            ),
            DropdownButton<String>(
              hint: const Text('Turma'),
              value: _selectedTurmaId,
              items: _turmas.map((t) => DropdownMenuItem<String>(
                value: t['id'],
                child: Text(t['nome']),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedTurmaId = val);
                _loadData();
              },
            ),
            DropdownButton<String>(
              hint: const Text('Matéria'),
              value: _selectedMateriaId,
              items: _materias.map((m) => DropdownMenuItem<String>(
                value: m['id'],
                child: Text(m['nome']),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedMateriaId = val);
                _loadData();
              },
            ),
            if (_tabController.index == 0) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    _loadData();
                  }
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFrequenciaTab() {
    if (_alunos.isEmpty) return const Center(child: Text('Nenhum aluno encontrado para esta turma.'));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alunos.length,
      itemBuilder: (context, index) {
        final aluno = _alunos[index];
        final isPresente = _frequenciaStatus[aluno['id']] ?? true;
        
        return Card(
          child: ListTile(
            title: Text(aluno['nome']),
            subtitle: Text(aluno['matricula_ra'] ?? 'Sem RA'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isPresente ? 'PRESENTE' : 'AUSENTE', 
                  style: TextStyle(
                    color: isPresente ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold
                  )
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isPresente,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (val) => _onFrequenciaChanged(aluno['id'], val),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotasTab() {
    if (_alunos.isEmpty) return const Center(child: Text('Nenhum aluno encontrado para esta turma.'));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Aluno')),
              ..._tiposAvaliacao.map((tipo) => DataColumn(label: Text(tipo))),
            ],
            rows: _alunos.map((aluno) {
              return DataRow(
                cells: [
                  DataCell(Text(aluno['nome'])),
                  ..._tiposAvaliacao.map((tipo) {
                    final notaAtual = _notasStatus[aluno['id']]?[tipo];
                    return DataCell(
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: notaAtual != null ? notaAtual.toString() : '',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                          onChanged: (val) => _onNotaChanged(aluno['id'], tipo, val),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Classe'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => setState(() {}), // refresh date picker visibility
          tabs: const [
            Tab(text: 'Frequência', icon: Icon(Icons.fact_check)),
            Tab(text: 'Notas', icon: Icon(Icons.grading)),
          ],
        ),
      ),
      body: _isLoadingFilters
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFiltros(),
                Expanded(
                  child: _isLoadingData
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFrequenciaTab(),
                            _buildNotasTab(),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}