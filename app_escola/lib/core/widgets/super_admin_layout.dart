import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../storage/secure_storage.dart';
import '../../features/super_admin/super_admin_screen.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/login_screen.dart';
import 'session_timeout_manager.dart';

final GlobalKey<NavigatorState> superAdminNavKey = GlobalKey<NavigatorState>();

class SuperAdminLayout extends StatefulWidget {
  const SuperAdminLayout({super.key});

  @override
  State<SuperAdminLayout> createState() => _SuperAdminLayoutState();
}

class _SuperAdminLayoutState extends State<SuperAdminLayout> {
  String userName = '';
  String userEmail = '';
  String userRole = 'Super Admin';
  DateTime currentTime = DateTime.now();
  Timer? clockTimer;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          currentTime = DateTime.now();
        });
      }
    });

    final email = await SecureStorage.getEmail();
    final name = await SecureStorage.getName();
    
    if (mounted) {
      setState(() {
        userEmail = email ?? 'email@mdxhq.com.br';
        userName = name ?? 'Rene Junior';
      });
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala Cofre - SaaS Escolar'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _fazerLogout,
            tooltip: 'Sair do Sistema',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gerenciar Escolas'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: const SuperAdminScreen(),
      bottomNavigationBar: BottomAppBar(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '[ $userRole ] $userName ($userEmail)',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy às HH:mm').format(currentTime),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}