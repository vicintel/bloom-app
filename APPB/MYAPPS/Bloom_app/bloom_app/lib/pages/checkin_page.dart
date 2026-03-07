import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/haptics.dart';
import 'dart:convert';


class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> with SingleTickerProviderStateMixin {
  final moodController = TextEditingController();
  final symptomsController = TextEditingController();
  String? selectedMood;
  bool isAnalyzing = false;
  String analysisResult = '';
  final moods = ['😊 Happy', '😔 Sad', '😤 Frustrated', '😌 Calm', '😴 Tired', '😍 Energetic'];
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    moodController.dispose();
    symptomsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyzeWellbeing() async {
    if (selectedMood == null || moodController.text.isEmpty) {
      Haptics.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood and describe how you feel')),
      );
      return;
    }
    Haptics.lightImpact();
    setState(() => isAnalyzing = true);
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        final fallback = _generateFallbackAnalysis();
        if (mounted) setState(() => analysisResult = fallback);
        return;
      }
      final prompt = 'User reported mood: $selectedMood. They said: ${moodController.text}. '
          'Symptoms: ${symptomsController.text.isEmpty ? "None reported" : symptomsController.text}. '
          'Provide brief wellness insights and recommendations (2-3 sentences).';
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful wellness assistant.'},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (mounted && content != null) setState(() => analysisResult = content.trim());
      } else {
        if (mounted) setState(() => analysisResult = _generateFallbackAnalysis());
      }
    } catch (e) {
      if (mounted) setState(() => analysisResult = _generateFallbackAnalysis());
    } finally {
      if (mounted) setState(() => isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Daily Check-in'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  label: 'How are you feeling today?',
                  child: Text(
                    'How are you feeling today?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF463E2D),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Mood selection',
                  child: Wrap(
                    spacing: 8,
                    children: moods.map((mood) => ChoiceChip(
                          label: Text(mood),
                          selected: selectedMood == mood,
                          onSelected: (selected) {
                            if (selected) Haptics.selectionClick();
                            setState(() => selectedMood = selected ? mood : null);
                          },
                        )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Describe your mood',
                  textField: true,
                  child: TextField(
                    controller: moodController,
                    decoration: const InputDecoration(
                      labelText: 'Describe your mood',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Symptoms (optional)',
                  textField: true,
                  child: TextField(
                    controller: symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms (optional)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: 'Analyze and get advice',
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isAnalyzing ? null : _analyzeWellbeing,
                      child: isAnalyzing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Analyze & Get Advice'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (analysisResult.isNotEmpty)
                  Semantics(
                    label: 'AI wellness analysis result',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A0BF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        analysisResult,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your check-in to get personalized wellness advice.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _generateFallbackAnalysis() {
    return 'Unable to connect to AI service. Remember to take care of yourself, stay hydrated, and rest if needed.';
  }
}



