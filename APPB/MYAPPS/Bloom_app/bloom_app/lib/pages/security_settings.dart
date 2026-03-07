import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';


class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> with SingleTickerProviderStateMixin {
  bool _biometricEnabled = false;
  final _sec = SecurityService();
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final enabled = await _sec.isBiometricEnabled();
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool v) async {
    await _sec.setBiometricEnabled(v);
    setState(() => _biometricEnabled = v);
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('This will permanently delete all app data. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    final doubleConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This action is irreversible. Confirm delete all data?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes, delete')),
        ],
      ),
    );
    if (doubleConfirm != true) return;
    await _sec.clearAllAppData();
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        appBar: AppBar(title: const Text('Privacy & Security')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable Biometrics', style: TextStyle(fontWeight: FontWeight.bold)),
                        CupertinoSwitch(value: _biometricEnabled, onChanged: _toggleBiometric),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Use FaceID or Fingerprint to unlock the app.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Safety Wipe', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    const Text('Permanently erase all your data from this device.'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: _deleteAllData,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete All Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiometricSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _BiometricSection({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Enable Biometrics'),
        CupertinoSwitch(value: enabled, onChanged: onChanged),
      ],
    );
  }
}

class _DeleteSection extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteSection({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      onPressed: onDelete,
      icon: const Icon(Icons.delete),
      label: const Text('Delete All Data'),
    );
  }
}
