import 'package:flutter/material.dart';

class ThemeSettingsSheet extends StatelessWidget {
  final bool isDarkMode;
  final Color seedColor;
  final ValueChanged<bool> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;

  const ThemeSettingsSheet({
    super.key,
    required this.isDarkMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Light'),
              Switch(
                value: isDarkMode,
                onChanged: (val) => onThemeModeChanged(val),
              ),
              const Text('Dark'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Accent Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              ...[
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.teal,
                Colors.amber,
                Colors.red,
                Colors.brown,
              ].map((color) => GestureDetector(
                    onTap: () => onSeedColorChanged(color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 18,
                      child: seedColor.value == color.value
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
