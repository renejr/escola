import 'package:flutter/material.dart';
import 'main_layout.dart';
import 'role_guard.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, String routeName) {
    Navigator.pop(context); // Close the drawer
    nestedNavKey.currentState?.pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.school, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'SaaS Escolar',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              'PRINCIPAL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard (Visão Geral)'),
            onTap: () => _navigate(context, '/dashboard'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'SECRETARIA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Gestão de Alunos'),
            onTap: () => _navigate(context, '/alunos'),
          ),
          RoleGuard(
            allowedRoles: const ['admin', 'diretor', 'secretaria'],
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Gestão Financeira'),
              onTap: () => _navigate(context, '/financeiro'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Gestão de Responsáveis'),
            onTap: () => _navigate(context, '/responsaveis'),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Gestão de Professores'),
            onTap: () => _navigate(context, '/professores'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'ACADÊMICO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          RoleGuard(
            allowedRoles: const ['admin', 'diretor'],
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Períodos Letivos'),
              onTap: () => _navigate(context, '/periodos'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Grade de Matérias'),
            onTap: () => _navigate(context, '/materias'),
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Gestão de Turmas'),
            onTap: () => _navigate(context, '/turmas'),
          ),
          RoleGuard(
            allowedRoles: const ['admin', 'diretor', 'professor'],
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Diário de Classe'),
              onTap: () => _navigate(context, '/diario'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Agenda Escolar'),
            onTap: () => _navigate(context, '/agenda'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'INTELIGÊNCIA ARTIFICIAL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('Chat IA Assistente'),
            onTap: () => _navigate(context, '/chat'),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Alimentar IA (Memória)'),
            onTap: () => _navigate(context, '/memory'),
          ),
          RoleGuard(
            allowedRoles: const ['admin', 'diretor'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    'SEGURANÇA & SISTEMA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: const Text('Dados da Instituição'),
                  onTap: () => _navigate(context, '/escola_config'),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: Colors.blue),
                  title: const Text('Controle de Usuários'),
                  onTap: () => _navigate(context, '/usuarios'),
                ),
                ListTile(
                  leading: const Icon(Icons.smartphone),
                  title: const Text('Integração WhatsApp'),
                  onTap: () => _navigate(context, '/whatsapp'),
                ),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.orange),
                  title: const Text('Trilha de Auditoria'),
                  onTap: () => _navigate(context, '/audit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
