import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../repositories/financeiro_repository.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final FinanceiroRepository _repository = FinanceiroRepository();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  
  bool _isLoading = false;
  List<dynamic> _contas = [];
  List<dynamic> _alunos = [];

  double _totalReceber = 0;
  double _totalRecebido = 0;
  double _totalAtrasado = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _repository.getContas(),
        _repository.getAlunos(),
      ]);
      
      _contas = futures[0];
      _alunos = futures[1];

      _calculateTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _totalReceber = 0;
    _totalRecebido = 0;
    _totalAtrasado = 0;
    
    final today = DateTime.now();

    for (var conta in _contas) {
      final valor = double.tryParse(conta['valor'].toString()) ?? 0;
      final status = conta['status'];
      final dtVenc = DateTime.parse(conta['data_vencimento']);

      if (status == 'Pago') {
        _totalRecebido += valor;
      } else if (status == 'Pendente') {
        if (dtVenc.isBefore(today) && !dtVenc.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
           _totalAtrasado += valor;
        } else {
           _totalReceber += valor;
        }
      } else if (status == 'Atrasado') {
        _totalAtrasado += valor;
      }
    }
  }

  Color _getStatusColor(String status, String dataVencimento) {
    if (status == 'Pago') return Colors.green;
    if (status == 'Cancelado') return Colors.grey;
    
    final dtVenc = DateTime.parse(dataVencimento);
    final today = DateTime.now();
    if (status == 'Pendente' && dtVenc.isBefore(today) && !dtVenc.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
      return Colors.red;
    }
    if (status == 'Atrasado') return Colors.red;
    return Colors.orange;
  }

  String _getStatusText(String status, String dataVencimento) {
    final dtVenc = DateTime.parse(dataVencimento);
    final today = DateTime.now();
    if (status == 'Pendente' && dtVenc.isBefore(today) && !dtVenc.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
      return 'ATRASADO';
    }
    return status.toUpperCase();
  }

  String _getAlunoNome(String? alunoId) {
    if (alunoId == null) return 'N/A';
    final aluno = _alunos.firstWhere((a) => a['id'] == alunoId, orElse: () => null);
    return aluno != null ? aluno['nome'] : 'Desconhecido';
  }

  void _showPixDialog(String qrCodeBase64, String ticketUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cobrança PIX Gerada', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: Image.memory(base64Decode(qrCodeBase64), fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar Código Pix (Copia e Cola)'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ticketUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código Pix copiado para a área de transferência!')),
                );
              },
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final TextEditingController valorController = TextEditingController();
    String? selectedAlunoId;
    DateTime dataVencimento = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova Cobrança'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Aluno', border: OutlineInputBorder()),
                  value: selectedAlunoId,
                  items: _alunos.map((a) => DropdownMenuItem<String>(
                    value: a['id'],
                    child: Text(a['nome']),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedAlunoId = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)', 
                    border: OutlineInputBorder(),
                    hintText: 'ex: 450.00'
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Vencimento: ${DateFormat('dd/MM/yyyy').format(dataVencimento)}'),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dataVencimento,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setDialogState(() => dataVencimento = date);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Método de Pagamento',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: 'PIX'),
                  enabled: false,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  if (selectedAlunoId != null && valorController.text.isNotEmpty) {
                    final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
                    if (valor == null) return;
                    
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    
                    try {
                      final response = await _repository.createConta({
                        'aluno_id': selectedAlunoId,
                        'valor': valor,
                        'data_vencimento': DateFormat('yyyy-MM-dd').format(dataVencimento),
                        'metodo_pagamento': 'pix'
                      });
                      
                      if (response['qr_code_base64'] != null) {
                        _showPixDialog(response['qr_code_base64'], response['qr_code_copia_cola']);
                      } else {
                        await _loadData();
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
                child: const Text('Gerar Cobrança'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildSummaryCard('A Receber', _totalReceber, Colors.blue, Icons.schedule),
                      const SizedBox(width: 16),
                      _buildSummaryCard('Recebido', _totalRecebido, Colors.green, Icons.check_circle),
                      const SizedBox(width: 16),
                      _buildSummaryCard('Inadimplência', _totalAtrasado, Colors.red, Icons.warning),
                    ],
                  ),
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    child: _contas.isEmpty
                      ? const Center(child: Text('Nenhuma cobrança registrada.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Vencimento')),
                                DataColumn(label: Text('Aluno/Responsável')),
                                DataColumn(label: Text('Valor')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Método')),
                              ],
                              rows: _contas.map((c) {
                                final status = c['status'];
                                final dtVenc = c['data_vencimento'];
                                final color = _getStatusColor(status, dtVenc);
                                final dtFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(dtVenc));
                                return DataRow(
                                  cells: [
                                    DataCell(Text(dtFormatada)),
                                    DataCell(Text(_getAlunoNome(c['aluno_id']))),
                                    DataCell(Text(_currencyFormat.format(c['valor']))),
                                    DataCell(
                                      Chip(
                                        label: Text(_getStatusText(status, dtVenc), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: color,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    DataCell(Text(c['metodo_pagamento']?.toString().toUpperCase() ?? 'PIX')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Cobrança'),
      ),
    );
  }
}