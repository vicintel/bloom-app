import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/haptics.dart';
import '../state/cycle_state.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage>
    with SingleTickerProviderStateMixin {
  final _moodController = TextEditingController();
  final _symptomsController = TextEditingController();
  String? _selectedMood;
  bool _isAnalyzing = false;

  // Parsed AI response sections
  String _insight = '';
  String _nutritionTip = '';
  String _fitnessTip = '';

  static const _moods = [
    '😊 Happy',
    '😔 Sad',
    '😤 Frustrated',
    '😌 Calm',
    '😴 Tired',
    '⚡ Energetic',
    '😰 Anxious',
    '🤒 Unwell',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _moodController.dispose();
    _symptomsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWellbeing() async {
    if (_selectedMood == null || _moodController.text.trim().isEmpty) {
      Haptics.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a mood and describe how you feel')),
      );
      return;
    }
    Haptics.lightImpact();
    setState(() {
      _isAnalyzing = true;
      _insight = '';
      _nutritionTip = '';
      _fitnessTip = '';
    });

    final state = Provider.of<CycleState>(context, listen: false);
    final phase = state.currentPhase;
    final cycleDay = state.cycleDay;

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        _applyFallback();
        return;
      }

      final symptoms = _symptomsController.text.trim();
      final prompt = '''
The user is on day $cycleDay of their menstrual cycle (${phase == 'Unknown' ? 'phase unknown' : '$phase phase'}).
Mood: $_selectedMood
How they feel: ${_moodController.text.trim()}
Symptoms: ${symptoms.isEmpty ? 'None reported' : symptoms}

Based on their mood, how they feel, symptoms, and cycle phase, provide THREE short personalised recommendations. Return ONLY valid JSON (no markdown, no extra text) in this exact format:
{
  "insight": "A warm 2-sentence wellness observation based on their mood and symptoms.",
  "nutrition": "One specific food or meal suggestion that supports their current mood and cycle phase.",
  "fitness": "One specific movement or exercise suggestion that matches their energy level and cycle phase."
}''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are Bloom, a compassionate women\'s wellness companion. Always respond with valid JSON only — no markdown fences, no extra text.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && mounted) {
          try {
            final parsed = jsonDecode(content) as Map<String, dynamic>;
            setState(() {
              _insight = (parsed['insight'] as String?)?.trim() ?? '';
              _nutritionTip = (parsed['nutrition'] as String?)?.trim() ?? '';
              _fitnessTip = (parsed['fitness'] as String?)?.trim() ?? '';
            });
          } catch (_) {
            // If JSON parse fails, show raw content as insight
            setState(() => _insight = content.trim());
          }
        }
      } else {
        if (mounted) _applyFallback();
      }
    } catch (_) {
      if (mounted) _applyFallback();
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _applyFallback() {
    setState(() {
      _insight =
          'Take a moment to breathe and check in with yourself. You\'re doing great by paying attention to how you feel.';
      _nutritionTip =
          'Drink a glass of water and choose a nourishing whole food meal that makes your body feel good.';
      _fitnessTip =
          'A gentle 15-minute walk or some light stretching can do wonders for your mood and energy.';
    });
  }

  bool get _hasResults =>
      _insight.isNotEmpty || _nutritionTip.isNotEmpty || _fitnessTip.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: Text(
            'Daily Check-in',
            style: GoogleFonts.philosopher(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Text(
                'How are you feeling today?',
                style: GoogleFonts.philosopher(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your answers help Bloom personalise your recommendations.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // ── Mood chips ───────────────────────────────────────────
              Text('Select your mood',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((mood) {
                  final selected = _selectedMood == mood;
                  return FilterChip(
                    label: Text(mood),
                    selected: selected,
                    onSelected: (val) {
                      if (val) Haptics.selectionClick();
                      setState(() => _selectedMood = val ? mood : null);
                    },
                    selectedColor:
                        scheme.primaryContainer,
                    checkmarkColor: scheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── How do you feel? ─────────────────────────────────────
              Text('Describe how you feel',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              TextField(
                controller: _moodController,
                decoration: InputDecoration(
                  hintText: 'e.g. I feel a bit sluggish and low on energy...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // ── Symptoms ─────────────────────────────────────────────
              Text('Any symptoms? (optional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              TextField(
                controller: _symptomsController,
                decoration: InputDecoration(
                  hintText: 'e.g. bloating, headache, cramps...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Analyze button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeWellbeing,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isAnalyzing
                        ? 'Analysing your check-in…'
                        : 'Get My Recommendations',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Results ──────────────────────────────────────────────
              if (_hasResults) ...[
                _RecommendationCard(
                  icon: Icons.favorite_rounded,
                  title: 'Wellness Insight',
                  content: _insight,
                  color: scheme.primary,
                ),
                const SizedBox(height: 14),
                _RecommendationCard(
                  icon: Icons.restaurant_rounded,
                  title: 'Eat This Today',
                  content: _nutritionTip,
                  color: const Color(0xFF43A047),
                  actionLabel: 'See All Phase Foods',
                  onAction: () => context.push('/nutrition'),
                ),
                const SizedBox(height: 14),
                _RecommendationCard(
                  icon: Icons.fitness_center_rounded,
                  title: 'Move Your Body',
                  content: _fitnessTip,
                  color: const Color(0xFF1E88E5),
                  actionLabel: 'See Workouts',
                  onAction: () => context.push('/fitness'),
                ),
                const SizedBox(height: 40),
              ] else if (!_isAnalyzing)
                _EmptyState(scheme: scheme),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.85),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyState({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite_border_rounded,
              color: scheme.primary.withValues(alpha: 0.4), size: 40),
          const SizedBox(height: 12),
          Text(
            'Your personalised recommendations\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
