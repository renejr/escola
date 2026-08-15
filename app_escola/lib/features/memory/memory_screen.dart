import 'package:flutter/material.dart';
import 'memory_repository.dart';

import '../../core/widgets/main_layout.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final MemoryRepository _repository = MemoryRepository();
  
  bool _isLoading = false;
  String _selectedContext = 'Regimento Escolar';

  final List<String> _contextTypes = [
    'Regimento Escolar',
    'Histórico de Aluno',
    'Plano de Aula',
    'Aviso Geral',
  ];

  void _saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _repository.saveMemory(
        _textController.text.trim(),
        _selectedContext,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memória salva com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _textController.clear();
        setState(() {
          _selectedContext = _contextTypes.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
        title: const Text('Alimentar IA (Memória)'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedContext,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Contexto',
                  border: OutlineInputBorder(),
                ),
                items: _contextTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedContext = newValue;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  enabled: !_isLoading,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    hintText: 'Cole aqui o texto, regras ou histórico que a IA deve aprender...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o texto a ser memorizado.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveMemory,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.memory),
                label: Text(
                  _isLoading ? 'Gerando Vetores...' : 'Salvar Conhecimento na IA',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
