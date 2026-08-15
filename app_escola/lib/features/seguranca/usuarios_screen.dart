import 'package:flutter/material.dart';
import '../../core/widgets/main_layout.dart';
import 'models/usuario.dart';
import 'repositories/usuarios_repository.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosRepository _repository = UsuariosRepository();
  bool _isLoading = true;
  List<Usuario> _usuarios = [];
  List<Usuario> _filteredUsuarios = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = data;
          _filterData(_searchQuery);
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

  void _filterData(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsuarios = _usuarios;
      } else {
        _filteredUsuarios = _usuarios.where((u) {
          return u.nome.toLowerCase().contains(query.toLowerCase()) ||
                 u.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showFormDialog([Usuario? usuario]) {
    showDialog(
      context: context,
      builder: (ctx) => _UsuarioFormDialog(
        usuario: usuario,
        onSave: (data) async {
          setState(() => _isLoading = true);
          try {
            if (usuario == null) {
              await _repository.createUsuario(data);
            } else {
              await _repository.updateUsuario(usuario.id, data);
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
      ),
    );
  }

  Future<void> _toggleStatus(Usuario usuario) async {
    setState(() => _isLoading = true);
    try {
      await _repository.toggleStatus(usuario.id);
      _loadData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Controle de Usuários'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Novo Usuário'),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Pesquisar usuário...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterData,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsuarios.isEmpty
                    ? const Center(child: Text('Nenhum usuário encontrado.'))
                    : isDesktop
                        ? _buildDesktopView()
                        : _buildMobileView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('E-mail')),
              DataColumn(label: Text('Nível de Acesso')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _filteredUsuarios.map((u) {
              return DataRow(
                cells: [
                  DataCell(Text(u.nome)),
                  DataCell(Text(u.email)),
                  DataCell(Text(u.papel.toUpperCase())),
                  DataCell(
                    Chip(
                      label: Text(u.ativo ? 'Ativo' : 'Inativo'),
                      backgroundColor: u.ativo ? Colors.green.shade100 : Colors.red.shade100,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showFormDialog(u),
                        ),
                        IconButton(
                          icon: Icon(
                            u.ativo ? Icons.block : Icons.check_circle,
                            color: u.ativo ? Colors.red : Colors.green,
                          ),
                          onPressed: () => _toggleStatus(u),
                          tooltip: u.ativo ? 'Inativar' : 'Ativar',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      itemCount: _filteredUsuarios.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final u = _filteredUsuarios[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: u.ativo ? Colors.blue : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.email),
                Text('Nível: ${u.papel.toUpperCase()}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showFormDialog(u);
                if (val == 'toggle') _toggleStatus(u);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(u.ativo ? 'Inativar' : 'Ativar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsuarioFormDialog extends StatefulWidget {
  final Usuario? usuario;
  final Function(Map<String, dynamic>) onSave;

  const _UsuarioFormDialog({this.usuario, required this.onSave});

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  String _papel = 'professor';

  final List<String> _papeis = ['admin', 'diretor', 'secretario', 'professor'];

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nomeController.text = widget.usuario!.nome;
      _emailController.text = widget.usuario!.email;
      _papel = widget.usuario!.papel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.usuario == null ? 'Novo Usuário' : 'Editar Usuário'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo *'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail (Login) *'),
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _papel,
                decoration: const InputDecoration(labelText: 'Nível de Acesso *'),
                items: _papeis.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.toUpperCase()));
                }).toList(),
                onChanged: (v) => setState(() => _papel = v!),
              ),
              if (widget.usuario == null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Uma senha provisória será gerada e o usuário deverá redefini-la no primeiro acesso.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onSave({
                'nome': _nomeController.text.trim(),
                'email': _emailController.text.trim(),
                'papel': _papel,
              });
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}