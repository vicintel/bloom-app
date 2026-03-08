import '../services/api_keys.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  String _aiWorkoutPlan = '';
  bool _loadingPlan = false;

  // Phase → workout cards
  static const Map<String, List<Map<String, String>>> _phaseWorkouts = {
    'Menstrual': [
      {
        'name': 'Gentle Yoga',
        'intensity': 'Low',
        'duration': '20–30 min',
        'benefit': 'Eases cramps and calms the nervous system',
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Slow Walk',
        'intensity': 'Low',
        'duration': '20–40 min',
        'benefit': 'Boosts mood without depleting energy',
        'image': 'https://images.unsplash.com/photo-1487956382158-bb926046304a?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Full Body Stretch',
        'intensity': 'Very Low',
        'duration': '15–20 min',
        'benefit': 'Releases tension in the lower back and hips',
        'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Meditation',
        'intensity': 'Rest',
        'duration': '10–20 min',
        'benefit': 'Reduces cortisol and supports recovery',
        'image': 'https://images.unsplash.com/photo-1506126279646-a697353d3166?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Follicular': [
      {
        'name': 'HIIT Training',
        'intensity': 'High',
        'duration': '30–45 min',
        'benefit': 'Rising estrogen maximises strength gains',
        'image': 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Strength Training',
        'intensity': 'Moderate–High',
        'duration': '45–60 min',
        'benefit': 'Best time to build muscle and hit PRs',
        'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Running',
        'intensity': 'Moderate',
        'duration': '30–45 min',
        'benefit': 'Increased endurance and stamina this phase',
        'image': 'https://images.unsplash.com/photo-1461897104016-0b3b00cc81ee?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Dance Class',
        'intensity': 'Moderate',
        'duration': '45–60 min',
        'benefit': 'High social energy — great for group workouts',
        'image': 'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Ovulation': [
      {
        'name': 'Intense Cardio',
        'intensity': 'Very High',
        'duration': '30–45 min',
        'benefit': 'Peak energy — push your limits today',
        'image': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Cycling',
        'intensity': 'High',
        'duration': '45–60 min',
        'benefit': 'Leverage peak stamina for long sessions',
        'image': 'https://images.unsplash.com/photo-1534787238916-9ba6764efd4f?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Group Fitness',
        'intensity': 'Moderate–High',
        'duration': '45–60 min',
        'benefit': 'You\'re at peak sociability — feed off the energy',
        'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Swimming',
        'intensity': 'Moderate',
        'duration': '30–45 min',
        'benefit': 'Full-body training while staying cool',
        'image': 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Luteal': [
      {
        'name': 'Pilates',
        'intensity': 'Low–Moderate',
        'duration': '30–45 min',
        'benefit': 'Core strength without overtaxing adrenals',
        'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Dumbbell Workout',
        'intensity': 'Moderate',
        'duration': '30–40 min',
        'benefit': 'Maintain strength without overtraining',
        'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Yoga Flow',
        'intensity': 'Low',
        'duration': '30–45 min',
        'benefit': 'Balance hormones and ease PMS tension',
        'image': 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Nature Walk',
        'intensity': 'Low',
        'duration': '30–60 min',
        'benefit': 'Fresh air lowers cortisol and lifts mood',
        'image': 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=500&h=300&fit=crop&q=80',
      },
    ],
  };

  static const Map<String, Color> _intensityColors = {
    'Very Low': Color(0xFF78909C),
    'Rest': Color(0xFF78909C),
    'Low': Color(0xFF66BB6A),
    'Low–Moderate': Color(0xFF26A69A),
    'Moderate': Color(0xFF42A5F5),
    'Moderate–High': Color(0xFF7E57C2),
    'High': Color(0xFFEF5350),
    'Very High': Color(0xFFE53935),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAiPlan());
  }

  Future<void> _fetchAiPlan() async {
    final state = Provider.of<CycleState>(context, listen: false);
    setState(() {
      _loadingPlan = true;
      _aiWorkoutPlan = '';
    });
    try {
      final apiKey = groqApiKey;
      if (apiKey.isEmpty) {
        setState(() => _aiWorkoutPlan =
            'Move your body in a way that feels good to you today.');
        return;
      }
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
                  'You are an encouraging women\'s fitness coach who specializes in cycle-synced training. Be specific, motivating, and brief.',
            },
            {
              'role': 'user',
              'content':
                  'I am on day ${state.cycleDay} of my menstrual cycle, in my ${state.currentPhase} phase. Give me a specific workout plan or exercise tip for today. What should I do, for how long, and why? Keep it to 3 sentences.',
            },
          ],
          'max_tokens': 150,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && mounted) setState(() => _aiWorkoutPlan = content.trim());
      } else {
        if (mounted) {
          setState(() => _aiWorkoutPlan =
              'Listen to your body and choose movement that feels energising, not depleting.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _aiWorkoutPlan =
            'Listen to your body and choose movement that feels energising, not depleting.');
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  List<Color> _phaseGradient(String phase) {
    switch (phase) {
      case 'Menstrual':
        return [const Color(0xFFE57373), const Color(0xFFAD1457)];
      case 'Follicular':
        return [const Color(0xFF66BB6A), const Color(0xFF00897B)];
      case 'Ovulation':
        return [const Color(0xFFFFCA28), const Color(0xFFF57F17)];
      case 'Luteal':
        return [const Color(0xFFAB47BC), const Color(0xFF4527A0)];
      default:
        return [const Color(0xFF1E88E5), const Color(0xFF0D47A1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CycleState>(context);
    final phase = state.currentPhase;
    final workouts = _phaseWorkouts[phase] ?? _phaseWorkouts['Follicular']!;
    final gradient = _phaseGradient(phase);
    final phaseColor = state.phaseColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: gradient.first,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Fitness',
              style: GoogleFonts.philosopher(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 96, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        phase == 'Unknown'
                            ? 'Cycle-Synced Workouts'
                            : 'Move for your $phase Phase',
                        style: GoogleFonts.philosopher(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Workouts matched to your hormones',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI workout plan card
                  _buildAiCard(context, phaseColor),
                  const SizedBox(height: 28),

                  Text(
                    'Workouts for Right Now',
                    style: GoogleFonts.philosopher(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tailored to your ${phase == "Unknown" ? "cycle" : "$phase phase"}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workout cards (vertical list)
                  ...workouts.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WorkoutCard(
                          workout: w,
                          intensityColors: _intensityColors,
                        ),
                      )),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's AI Workout Plan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadingPlan ? null : _fetchAiPlan,
                child: Icon(Icons.refresh,
                    color: accentColor.withValues(alpha: 0.7), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingPlan)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text('Building your workout plan…',
                    style: TextStyle(color: accentColor.withValues(alpha: 0.7))),
              ],
            )
          else
            Text(
              _aiWorkoutPlan.isEmpty
                  ? 'Move in a way that feels good to your body today.'
                  : _aiWorkoutPlan,
              style: GoogleFonts.poppins(
                height: 1.6,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Map<String, String> workout;
  final Map<String, Color> intensityColors;

  const _WorkoutCard({required this.workout, required this.intensityColors});

  @override
  Widget build(BuildContext context) {
    final intensityColor =
        intensityColors[workout['intensity']] ?? const Color(0xFF42A5F5);

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            workout['image']!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: intensityColor.withValues(alpha: 0.2),
              child: Icon(Icons.fitness_center, color: intensityColor, size: 48),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: intensityColor.withValues(alpha: 0.1),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: intensityColor,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Intensity badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: intensityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    workout['intensity']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workout['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      workout['duration']!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.info_outline,
                        color: Colors.white60, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        workout['benefit']!,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
