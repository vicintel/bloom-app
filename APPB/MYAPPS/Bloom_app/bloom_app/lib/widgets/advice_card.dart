import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';
import 'glass_container.dart';

class AdviceCard extends StatefulWidget {
  const AdviceCard({super.key});

  @override
  State<AdviceCard> createState() => _AdviceCardState();
}

class _AdviceCardState extends State<AdviceCard> {
  bool _loading = false;
  String? _error;

  Future<void> fetchAdvice(BuildContext context, String type) async {
    final state = Provider.of<CycleState>(context, listen: false);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() => _error = 'No API key configured.');
        return;
      }
      final prompt = type == 'Nutrition'
          ? 'Give 3 specific foods that are especially beneficial during the ${state.currentPhase} phase of the menstrual cycle. Be concise, one food per line.'
          : 'Recommend a specific workout type and intensity level for the ${state.currentPhase} phase of the menstrual cycle. Be concise.';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a concise women\'s health coach. Answer in 2-3 lines max.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 100,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null) {
          state.updateAdvice({'text': content.trim(), 'type': type});
        }
      } else {
        setState(() => _error = 'Could not load advice. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          const Text('Personalized Advice',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Nutrition'),
                selected: state.adviceType == 'Nutrition',
                onSelected: (selected) {
                  if (selected) {
                    state.updateAdviceType('Nutrition');
                    fetchAdvice(context, 'Nutrition');
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fitness'),
                selected: state.adviceType == 'Fitness',
                onSelected: (selected) {
                  if (selected) {
                    state.updateAdviceType('Fitness');
                    fetchAdvice(context, 'Fitness');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red))
          else if (state.advice.isNotEmpty &&
              state.advice['type'] == state.adviceType)
            Text(
              state.advice['text'] ?? '',
              style: const TextStyle(height: 1.5),
            )
          else
            Text(
              'Tap Nutrition or Fitness to get phase-specific advice.',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}
