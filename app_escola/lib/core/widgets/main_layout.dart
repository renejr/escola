import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_drawer.dart';
import '../storage/secure_storage.dart';

import '../../features/home_screen.dart';
import '../../features/secretaria/alunos_screen.dart';
import '../../features/secretaria/responsaveis_screen.dart';
import '../../features/secretaria/professores_screen.dart';
import '../../features/academico/materias_screen.dart';
import '../../features/academico/agenda_screen.dart';
import '../../features/escolar/turmas_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/auditoria/audit_screen.dart';
import '../../features/seguranca/usuarios_screen.dart';
import '../../features/seguranca/whatsapp_screen.dart';
import '../../features/seguranca/escola_config_screen.dart';
import '../../features/super_admin/super_admin_screen.dart';

final GlobalKey<NavigatorState> nestedNavKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String userName = '';
  String userEmail = '';
  String userRole = '';
  DateTime? loginTime;
  DateTime currentTime = DateTime.now();
  Timer? clockTimer;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    loginTime = DateTime.now();
    clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          currentTime = DateTime.now();
        });
      }
    });

    final email = await SecureStorage.getEmail();
    final name = await SecureStorage.getName();
    final role = await SecureStorage.getRole();
    
    if (mounted) {
      setState(() {
        userEmail = email ?? 'email@exemplo.com';
        userName = name ?? 'Usuário não identificado';
        userRole = role != null ? role[0].toUpperCase() + role.substring(1) : 'Usuário';
      });
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/dashboard':
        page = const HomeScreen();
        break;
      case '/alunos':
        page = const AlunosScreen();
        break;
      case '/responsaveis':
        page = const ResponsaveisScreen();
        break;
      case '/professores':
        page = const ProfessoresScreen();
        break;
      case '/materias':
        page = const MateriasScreen();
        break;
      case '/agenda':
        page = const AgendaScreen();
        break;
      case '/turmas':
        page = const TurmasScreen();
        break;
      case '/chat':
        page = const ChatScreen();
        break;
      case '/memory':
        page = const MemoryScreen();
        break;
      case '/audit':
        page = const AuditScreen();
        break;
      case '/whatsapp':
        page = const WhatsappScreen();
        break;
      case '/escola_config':
        page = const EscolaConfigScreen();
        break;
      case '/usuarios':
        page = const UsuariosScreen();
        break;
      case '/superadmin':
        page = const SuperAdminScreen();
        break;
      default:
        page = const HomeScreen();
    }
    
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: mainScaffoldKey,
      drawer: const AppDrawer(),
      body: Navigator(
        key: nestedNavKey,
        initialRoute: '/dashboard',
        onGenerateRoute: _onGenerateRoute,
      ),
      bottomNavigationBar: BottomAppBar(
        height: 40,
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '[ $userRole ] $userName ($userEmail)',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (loginTime != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Entrada: ${DateFormat('dd/MM/yyyy').format(loginTime!)} às ${DateFormat('HH:mm').format(loginTime!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm:ss').format(currentTime),
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
