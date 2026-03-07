import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/security_service.dart';

class LockedPage extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockedPage({super.key, required this.onUnlocked});

  @override
  State<LockedPage> createState() => _LockedPageState();
}

class _LockedPageState extends State<LockedPage> {
  bool _isAuthenticating = false;
  String _message = 'Bloom Locked';

  Future<void> _tryAuthenticate() async {
    setState(() => _isAuthenticating = true);
    final sec = SecurityService();
    final ok = await sec.authenticate();
    setState(() => _isAuthenticating = false);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() => _message = 'Authentication failed. Try again.');
    }
  }

  @override
  void initState() {
    super.initState();
    // Attempt biometric automatically
    Future.microtask(() => _tryAuthenticate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bloom',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade200,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _isAuthenticating ? null : _tryAuthenticate,
                child: _isAuthenticating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator.adaptive())
                    : const Text('Unlock with Biometrics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
