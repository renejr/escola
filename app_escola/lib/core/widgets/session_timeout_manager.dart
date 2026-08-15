import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../main.dart'; // Para acessar a navigatorKey global

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;

  const SessionTimeoutManager({super.key, required this.child});

  static SessionTimeoutManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<SessionTimeoutManagerState>();
  }

  @override
  State<SessionTimeoutManager> createState() => SessionTimeoutManagerState();
}

class SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;
  final int _timeoutMinutes = 15;
  bool _isActive = false;

  void startListening() {
    setState(() {
      _isActive = true;
    });
    _resetTimer();
  }

  void stopListening() {
    setState(() {
      _isActive = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    if (!_isActive) return;
    
    _timer?.cancel();
    _timer = Timer(Duration(minutes: _timeoutMinutes), _logOutUser);
  }

  Future<void> _logOutUser() async {
    if (!_isActive) return;
    stopListening();
    
    await AuthRepository().logout();
    
    final globalContext = navigatorKey.currentContext;
    if (globalContext != null && globalContext.mounted) {
      ScaffoldMessenger.of(globalContext).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada por inatividade.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      Navigator.pushAndRemoveUntil(
        globalContext,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
