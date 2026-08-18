import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
    }
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
            title: const Text('Nova Fatura (Checkout Pro)'),
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
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  if (selectedAlunoId != null && valorController.text.isNotEmpty) {
                    final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
                    if (valor == null) return;
                    
                    // Salvar o scaffoldMessenger antes de fechar o dialog
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    Navigator.pop(context);
                    
                    if (!mounted) return;
                    setState(() => _isLoading = true);
                    
                    try {
                      final response = await _repository.createConta({
                        'aluno_id': selectedAlunoId,
                        'valor': valor,
                        'data_vencimento': DateFormat('yyyy-MM-dd').format(dataVencimento)
                      });
                      
                      if (!mounted) return;
                      await _loadData();
                      
                      if (response['checkout_url'] != null) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Link de pagamento gerado com sucesso!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Gerar Fatura'),
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
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: _contas.map((c) {
                                final status = c['status'];
                                final dtVenc = c['data_vencimento'];
                                final color = _getStatusColor(status, dtVenc);
                                final dtFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(dtVenc));
                                final checkoutUrl = c['checkout_url'];
                                return DataRow(
                                  cells: [
                                    DataCell(Text(dtFormatada)),
                                    DataCell(Text(_getAlunoNome(c['aluno_id']))),
                                    DataCell(Text(_currencyFormat.format(c['valor'] ?? 0.0))),
                                    DataCell(
                                      Chip(
                                        label: Text(_getStatusText(status, dtVenc), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: color,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    DataCell(
                                      checkoutUrl != null 
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.link, color: Colors.blue),
                                              tooltip: 'Abrir Link de Pagamento',
                                              onPressed: () => _launchUrl(checkoutUrl),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, color: Colors.grey),
                                              tooltip: 'Copiar Link',
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: checkoutUrl));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Link copiado!')),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : const Text('-'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Cobrança'),
      ),
    );
  }
}