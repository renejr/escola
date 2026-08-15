import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'audit_repository.dart';

import '../../core/widgets/main_layout.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final AuditRepository _repository = AuditRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _repository.getAuditLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar auditoria: $e')),
        );
      }
    }
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
        title: const Text('Trilha de Auditoria (Logs)'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Atualizar Logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitThreeBounce(
                color: theme.colorScheme.primary,
                size: 30.0,
              ),
            )
          : _logs.isEmpty
              ? const Center(child: Text('Nenhum registro de auditoria encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final acao = log['acao'] ?? 'DESCONHECIDO';
                    final dataStr = log['criado_em'];
                    final ip = log['ip_address'] ?? 'N/A';
                    final usuario = log['usuario_id'] ?? 'Sistema';
                    
                    DateTime? data;
                    if (dataStr != null) {
                      data = DateTime.tryParse(dataStr)?.toLocal();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorPorAcao(acao),
                          child: const Icon(Icons.security, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          acao,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data != null
                              ? DateFormat('dd/MM/yyyy HH:mm:ss').format(data)
                              : 'Data Desconhecida',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('ID Usuário:', usuario),
                                _buildDetailRow('Endereço IP:', ip),
                                _buildDetailRow('ID do Log:', log['id'] ?? ''),
                                const SizedBox(height: 8),
                                const Text(
                                  'Detalhes Técnicos (JSON):',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: SelectableText(
                                    log['detalhes']?.toString() ?? '{}',
                                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getColorPorAcao(String acao) {
    if (acao == 'LOGIN') return Colors.green;
    if (acao == 'LOGOUT') return Colors.orange;
    if (acao.startsWith('CREATE')) return Colors.blue;
    if (acao.startsWith('DELETE')) return Colors.red;
    return Colors.grey;
  }
}
