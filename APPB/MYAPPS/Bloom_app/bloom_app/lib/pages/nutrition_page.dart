import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  String _aiMealIdea = '';
  bool _loadingTip = false;

  // Phase → list of food cards
  static const Map<String, List<Map<String, String>>> _phaseFoods = {
    'Menstrual': [
      {
        'name': 'Spinach & Kale',
        'benefit': 'Replenish iron lost during menstruation',
        'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Salmon',
        'benefit': 'Omega-3s reduce cramps and inflammation',
        'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Dark Chocolate',
        'benefit': 'Boosts mood with magnesium & endorphins',
        'image': 'https://images.unsplash.com/photo-1481391319762-47dff72954d9?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Ginger Tea',
        'benefit': 'Soothes cramps and reduces nausea',
        'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Follicular': [
      {
        'name': 'Fresh Berries',
        'benefit': 'Antioxidants support rising estrogen levels',
        'image': 'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Broccoli',
        'benefit': 'Cruciferous veggies balance hormones naturally',
        'image': 'https://images.unsplash.com/photo-1459411621453-8a13132d0221?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Flax & Pumpkin Seeds',
        'benefit': 'Seed cycling supports estrogen production',
        'image': 'https://images.unsplash.com/photo-1514995669114-6081e934b693?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Yogurt',
        'benefit': 'Probiotics support estrogen metabolism',
        'image': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Ovulation': [
      {
        'name': 'Colourful Salad',
        'benefit': 'Light, nutrient-dense meals for peak energy',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Bell Peppers',
        'benefit': 'High vitamin C supports egg health',
        'image': 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Lentil Soup',
        'benefit': 'Plant protein & iron for sustained energy',
        'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Mixed Berries',
        'benefit': 'Antioxidants support peak fertility window',
        'image': 'https://images.unsplash.com/photo-1425934398893-310a009a77f9?w=500&h=300&fit=crop&q=80',
      },
    ],
    'Luteal': [
      {
        'name': 'Avocado',
        'benefit': 'Healthy fats reduce bloating & cravings',
        'image': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Bananas',
        'benefit': 'Potassium & B6 ease PMS symptoms',
        'image': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Sweet Potato',
        'benefit': 'Complex carbs stabilize mood swings',
        'image': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&h=300&fit=crop&q=80',
      },
      {
        'name': 'Pumpkin Seeds',
        'benefit': 'Magnesium eases anxiety and muscle cramps',
        'image': 'https://images.unsplash.com/photo-1600360961894-df6ca0740e4d?w=500&h=300&fit=crop&q=80',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAiMeal());
  }

  Future<void> _fetchAiMeal() async {
    final state = Provider.of<CycleState>(context, listen: false);
    setState(() {
      _loadingTip = true;
      _aiMealIdea = '';
    });
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() =>
            _aiMealIdea = 'Eat warm, nourishing whole foods that make you feel your best.');
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
                  'You are a warm, knowledgeable women\'s nutrition coach specializing in cycle syncing. Be specific and encouraging.',
            },
            {
              'role': 'user',
              'content':
                  'I am on day ${state.cycleDay} of my menstrual cycle, currently in my ${state.currentPhase} phase. Suggest one specific, delicious meal or recipe idea I can make today that supports my hormones. Keep it to 3 sentences.',
            },
          ],
          'max_tokens': 150,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && mounted) setState(() => _aiMealIdea = content.trim());
      } else {
        if (mounted) setState(() => _aiMealIdea = 'Focus on whole foods and listen to your body\'s cravings.');
      }
    } catch (_) {
      if (mounted) setState(() => _aiMealIdea = 'Focus on whole foods and listen to your body\'s cravings.');
    } finally {
      if (mounted) setState(() => _loadingTip = false);
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
        return [const Color(0xFFE8A0BF), const Color(0xFFAD1457)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CycleState>(context);
    final phase = state.currentPhase;
    final foods = _phaseFoods[phase] ?? _phaseFoods['Follicular']!;
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
              'Nutrition',
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
                            ? 'Phase-Based Nutrition'
                            : 'Eat for your $phase Phase',
                        style: GoogleFonts.philosopher(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Foods that support your hormones right now',
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
                  // AI Meal Idea Card
                  _buildAiCard(context, phaseColor),
                  const SizedBox(height: 28),

                  // Foods to eat section
                  Text(
                    'Best Foods Right Now',
                    style: GoogleFonts.philosopher(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chosen for your ${phase == "Unknown" ? "cycle" : "$phase phase"}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Food cards grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: foods.length,
                    itemBuilder: (context, i) => _FoodCard(
                      food: foods[i],
                      accentColor: phaseColor,
                    ),
                  ),
                  const SizedBox(height: 48),
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
                "Today's AI Meal Idea",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadingTip ? null : _fetchAiMeal,
                child: Icon(Icons.refresh,
                    color: accentColor.withValues(alpha: 0.7), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingTip)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text('Generating meal idea…',
                    style: TextStyle(color: accentColor.withValues(alpha: 0.7))),
              ],
            )
          else
            Text(
              _aiMealIdea.isEmpty
                  ? 'Focus on whole, nourishing foods that make you feel energised.'
                  : _aiMealIdea,
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

class _FoodCard extends StatelessWidget {
  final Map<String, String> food;
  final Color accentColor;

  const _FoodCard({required this.food, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  food['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: accentColor.withValues(alpha: 0.15),
                    child: Icon(Icons.restaurant, color: accentColor, size: 40),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: accentColor.withValues(alpha: 0.08),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                // gradient overlay at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food['benefit']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
