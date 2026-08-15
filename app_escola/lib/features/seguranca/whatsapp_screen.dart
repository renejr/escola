import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/widgets/main_layout.dart';
import 'repositories/whatsapp_repository.dart';

class WhatsappScreen extends StatefulWidget {
  const WhatsappScreen({super.key});

  @override
  State<WhatsappScreen> createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  final WhatsappRepository _repository = WhatsappRepository();
  bool _isLoading = true;
  String _status = 'Desconhecido';
  String? _qrCodeBase64;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getStatus();
      if (mounted) {
        setState(() {
          _status = data['instance']?['state'] ?? 'Desconhecido';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Erro de Conexão';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateQrCode() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.gerarQrCode();
      if (mounted) {
        setState(() {
          if (data['base64'] != null) {
            _qrCodeBase64 = data['base64'];
            _status = 'Aguardando Leitura do QR Code';
          } else if (data['instance']?['state'] != null) {
             _status = data['instance']['state'];
             _qrCodeBase64 = null;
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A instância já está conectada ou processando.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível gerar o QR Code.')),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar QR Code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Integração WhatsApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkStatus,
            tooltip: 'Atualizar Status',
          )
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'Status da Conexão',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _status.toLowerCase() == 'open' || _status.toLowerCase() == 'conectado'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_qrCodeBase64 != null && _status.toLowerCase() != 'open')
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.memory(
                                base64Decode(_qrCodeBase64!.split(',').last),
                                width: 250,
                                height: 250,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Escaneie o QR Code com seu WhatsApp'),
                          ],
                        ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _generateQrCode,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Gerar QR Code de Conexão'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
