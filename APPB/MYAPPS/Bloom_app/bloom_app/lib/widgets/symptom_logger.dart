import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';
import 'glass_container.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SymptomLogger extends StatefulWidget {
  const SymptomLogger({super.key});

  @override
  State<SymptomLogger> createState() => _SymptomLoggerState();
}

class _SymptomLoggerState extends State<SymptomLogger> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> analyzeLogs(BuildContext context) async {
    final state = Provider.of<CycleState>(context, listen: false);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/v1/analyze'), // Replace with actual Groq endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'phase': state.currentPhase,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state.updateTags(List<String>.from(data['tags'] ?? []));
        state.updateLog(text);
      } else {
        setState(() { _error = 'AI analysis failed.'; });
      }
    } catch (e) {
      setState(() { _error = 'Network error.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CycleState>(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Symptom Log', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Describe your symptoms, mood, or energy...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _loading ? null : () => analyzeLogs(context),
                child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Analyze'),
              ),
              if (_error != null) ...[
                const SizedBox(width: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
          const SizedBox(height: 8),
          if (state.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: state.tags.map((t) => Chip(label: Text('#$t'))).toList(),
            ),
        ],
      ),
    );
  }
}
