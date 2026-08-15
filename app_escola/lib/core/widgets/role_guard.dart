import 'package:flutter/material.dart';
import '../storage/secure_storage.dart';

class RoleGuard extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget replacement;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.replacement = const SizedBox.shrink(),
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _isAllowed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final userRole = await SecureStorage.getRole();
    if (mounted) {
      setState(() {
        _isAllowed = userRole != null && widget.allowedRoles.contains(userRole);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Pode retornar um loading pequeno se preferir
    }
    return _isAllowed ? widget.child : widget.replacement;
  }
}
