import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/theme_settings_sheet.dart';
import '../services/haptics.dart';
import '../services/auth_service.dart';
import '../state/theme_notifier.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Jane Doe';
  String email = 'jane.doe@email.com';
  String cyclePhase = 'Follicular';
  bool editing = false;
  final auth = AuthService();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        name = _nameController.text;
        email = _emailController.text;
        editing = false;
      });
      Haptics.lightImpact();
      CustomSnackbar.show(context, 'Profile updated!', success: true);
    } else {
      Haptics.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens_outlined),
            tooltip: 'Theme',
            onPressed: () {
              final themeNotifier =
                  Provider.of<ThemeNotifier>(context, listen: false);
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => ThemeSettingsSheet(
                  isDarkMode: themeNotifier.isDarkMode,
                  seedColor: themeNotifier.seedColor,
                  onThemeModeChanged: themeNotifier.setDarkMode,
                  onSeedColorChanged: themeNotifier.setSeedColor,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(editing ? Icons.check : Icons.edit),
            onPressed: () {
              if (editing) {
                _saveProfile();
              } else {
                Haptics.selectionClick();
                setState(() => editing = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                enabled: editing,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                enabled: editing,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: cyclePhase,
                decoration: const InputDecoration(
                  labelText: 'Cycle Phase',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Follicular', child: Text('Follicular')),
                  DropdownMenuItem(value: 'Ovulation', child: Text('Ovulation')),
                  DropdownMenuItem(value: 'Luteal', child: Text('Luteal')),
                  DropdownMenuItem(value: 'Menstrual', child: Text('Menstrual')),
                ],
                onChanged: editing
                    ? (val) => setState(() => cyclePhase = val ?? cyclePhase)
                    : null,
              ),
              const SizedBox(height: 32),
              if (editing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save'),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
