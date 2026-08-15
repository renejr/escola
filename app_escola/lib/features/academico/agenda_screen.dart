import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/main_layout.dart';
import 'models/evento_agenda.dart';
import 'repositories/agenda_repository.dart';
import '../escolar/models/turma.dart';
import '../escolar/repositories/turmas_repository.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final AgendaRepository _repository = AgendaRepository();
  final TurmasRepository _turmasRepository = TurmasRepository();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;
  List<EventoAgenda> _todosEventos = [];
  List<Turma> _turmas = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final eventos = await _repository.getEventos();
      final turmas = await _turmasRepository.getTurmas();
      if (mounted) {
        setState(() {
          _todosEventos = eventos;
          _turmas = turmas;
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

  List<EventoAgenda> _getEventosForDay(DateTime day) {
    return _todosEventos.where((e) {
      return isSameDay(e.dataInicio, day) || 
             isSameDay(e.dataFim, day) || 
             (day.isAfter(e.dataInicio) && day.isBefore(e.dataFim));
    }).toList();
  }

  void _showEventoForm([EventoAgenda? evento]) {
    showDialog(
      context: context,
      builder: (ctx) => _EventoFormDialog(
        evento: evento,
        turmas: _turmas,
        selectedDate: _selectedDay ?? DateTime.now(),
        onSave: (data) async {
          setState(() => _isLoading = true);
          try {
            if (evento == null) {
              await _repository.createEvento(data);
            } else {
              await _repository.updateEvento(evento.id, data);
            }
            _loadData();
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
        onDelete: evento != null ? () async {
          setState(() => _isLoading = true);
          try {
            await _repository.deleteEvento(evento.id);
            _loadData();
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
              );
            }
          }
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventosDoDia = _getEventosForDay(_selectedDay ?? _focusedDay);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget calendarWidget = Card(
      margin: const EdgeInsets.all(8.0),
      child: TableCalendar<EventoAgenda>(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        eventLoader: _getEventosForDay,
        calendarStyle: CalendarStyle(
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    Widget listWidget = Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.surfaceContainerHighest,
            width: double.infinity,
            child: Text(
              'Eventos em ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: eventosDoDia.isEmpty
                ? const Center(child: Text('Nenhum evento neste dia.'))
                : ListView.builder(
                    itemCount: eventosDoDia.length,
                    itemBuilder: (context, index) {
                      final e = eventosDoDia[index];
                      final isGlobal = e.turmaId == null;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isGlobal ? Colors.blue : Colors.orange,
                          child: Icon(isGlobal ? Icons.public : Icons.class_, color: Colors.white),
                        ),
                        title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.tipo} | ${DateFormat('HH:mm').format(e.dataInicio)} - ${DateFormat('HH:mm').format(e.dataFim)}'),
                            if (e.descricao != null && e.descricao!.isNotEmpty) Text(e.descricao!),
                            Text(isGlobal ? 'Evento Global (Escola Toda)' : 'Evento de Turma Específica', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                          ],
                        ),
                        onTap: () => _showEventoForm(e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Agenda Escolar'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: () => _showEventoForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo Evento'),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: calendarWidget),
                    Expanded(flex: 3, child: listWidget),
                  ],
                )
              : Column(
                  children: [
                    calendarWidget,
                    Expanded(child: listWidget),
                  ],
                ),
    );
  }
}

class _EventoFormDialog extends StatefulWidget {
  final EventoAgenda? evento;
  final List<Turma> turmas;
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete;

  const _EventoFormDialog({
    this.evento,
    required this.turmas,
    required this.selectedDate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_EventoFormDialog> createState() => _EventoFormDialogState();
}

class _EventoFormDialogState extends State<_EventoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  
  String _tipo = 'Evento Escolar';
  String? _turmaId;
  late DateTime _dataInicio;
  late DateTime _dataFim;
  bool _gerarNotificacao = false;

  final List<String> _tipos = ['Feriado', 'Prova', 'Reunião', 'Evento Escolar'];

  @override
  void initState() {
    super.initState();
    if (widget.evento != null) {
      _tituloController.text = widget.evento!.titulo;
      _descController.text = widget.evento!.descricao ?? '';
      _tipo = widget.evento!.tipo;
      _turmaId = widget.evento!.turmaId;
      _dataInicio = widget.evento!.dataInicio;
      _dataFim = widget.evento!.dataFim;
    } else {
      _dataInicio = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 8, 0);
      _dataFim = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 9, 0);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = TimeOfDay.fromDateTime(isStart ? _dataInicio : _dataFim);
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dataInicio = DateTime(_dataInicio.year, _dataInicio.month, _dataInicio.day, picked.hour, picked.minute);
        } else {
          _dataFim = DateTime(_dataFim.year, _dataFim.month, _dataFim.day, picked.hour, picked.minute);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.evento == null ? 'Novo Evento' : 'Editar Evento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Evento *'),
                items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _turmaId,
                decoration: const InputDecoration(labelText: 'Turma (Opcional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Escola Toda (Global)')),
                  ...widget.turmas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                ],
                onChanged: (v) => setState(() => _turmaId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('Início: ${DateFormat('HH:mm').format(_dataInicio)}'),
                      onPressed: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('Fim: ${DateFormat('HH:mm').format(_dataFim)}'),
                      onPressed: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Gerar notificação imediata para a equipe'),
                value: _gerarNotificacao,
                onChanged: (val) => setState(() => _gerarNotificacao = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onSave({
                'titulo': _tituloController.text.trim(),
                'descricao': _descController.text.trim(),
                'tipo': _tipo,
                'turma_id': _turmaId,
                'data_inicio': _dataInicio.toIso8601String(),
                'data_fim': _dataFim.toIso8601String(),
                'gerar_notificacao': _gerarNotificacao,
              });
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}