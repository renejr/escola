import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'auth/auth_repository.dart';
import 'auth/login_screen.dart';
import 'escolar/escolar_repository.dart';
import '../core/widgets/session_timeout_manager.dart';
import '../core/widgets/main_layout.dart';
import '../core/models/notificacao.dart';
import '../core/repositories/notificacoes_repository.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EscolarRepository _repository = EscolarRepository();
  final AuthRepository _authRepository = AuthRepository();
  final NotificacoesRepository _notificacoesRepository = NotificacoesRepository();
  bool _isLoading = true;
  int _totalTurmas = 0;
  int _totalAlunos = 0;
  List<Map<String, dynamic>> _turmasRecentes = [];
  List<Notificacao> _notificacoesNaoLidas = [];

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getDashboardSummary();
      final turmas = await _repository.getTurmas();
      final notificacoes = await _notificacoesRepository.getNotificacoesNaoLidas();
      if (mounted) {
        setState(() {
          _totalTurmas = data['total_turmas'] ?? 0;
          _totalAlunos = data['total_alunos'] ?? 0;
          _turmasRecentes = turmas.take(5).toList();
          _notificacoesNaoLidas = notificacoes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dashboard: $e')),
        );
      }
    }
  }

  Future<void> _fazerLogout() async {
    SessionTimeoutManager.of(context)?.stopListening();
    await _authRepository.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _abrirCentralNotificacoes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Central de Notificações',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _notificacoesNaoLidas.isEmpty
                        ? const Center(child: Text('Nenhuma notificação não lida.'))
                        : ListView.builder(
                            itemCount: _notificacoesNaoLidas.length,
                            itemBuilder: (context, index) {
                              final notif = _notificacoesNaoLidas[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.notifications, color: Colors.white),
                                  ),
                                  title: Text(notif.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notif.mensagem),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(notif.criadoEm),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      try {
                                        await _notificacoesRepository.marcarComoLida(notif.id);
                                        if (!context.mounted) return;
                                        setState(() {
                                          _notificacoesNaoLidas.removeWhere((n) => n.id == notif.id);
                                        });
                                        setModalState(() {});
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                    child: const Text('Marcar como lida'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildDashboardCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Badge(
                isLabelVisible: _notificacoesNaoLidas.isNotEmpty,
                label: Text('${_notificacoesNaoLidas.length}'),
                child: const Icon(Icons.notifications),
              ),
              onPressed: _abrirCentralNotificacoes,
              tooltip: 'Notificações',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDashboard,
            tooltip: 'Atualizar Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _fazerLogout,
            tooltip: 'Sair',
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
          : RefreshIndicator(
              onRefresh: _carregarDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'Visão Geral',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      _buildDashboardCard(
                        context,
                        'Total de Turmas',
                        _totalTurmas.toString(),
                        Icons.class_,
                        Colors.blue,
                      ),
                      _buildDashboardCard(
                        context,
                        'Alunos Matriculados',
                        _totalAlunos.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                      _buildDashboardCard(
                        context,
                        'Frequência Média',
                        '95%',
                        Icons.insights,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Turmas Recentes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _turmasRecentes.length,
                      itemBuilder: (context, index) {
                        final turma = _turmasRecentes[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.class_),
                          ),
                          title: Text(turma['nome'] ?? ''),
                          subtitle: const Text('Turno Matutino'), // Mock
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Poderíamos navegar para os detalhes da turma
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          nestedNavKey.currentState?.pushNamed('/chat');
        },
        icon: const Icon(Icons.smart_toy),
        label: const Text('IA Assistente'),
      ),
    );
  }
}
