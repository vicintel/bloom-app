import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool _generatingReport = false;
  String _monthlyReport = '';

  static const _phaseGradient = [Color(0xFFBA68C8), Color(0xFF7B1FA2)];

  Future<void> _generateMonthlyReport(CycleState state) async {
    if (_generatingReport) return;
    setState(() {
      _generatingReport = true;
      _monthlyReport = '';
    });

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() => _monthlyReport =
            'API key not configured. Please add your GROQ API key to the .env file.');
        return;
      }

      final history = state.checkinHistory;
      final last10 = history.length > 10
          ? history.sublist(history.length - 10)
          : history.toList();

      final summaryLines = last10.map((e) {
        final mood = e['mood'] ?? 'unknown';
        final symptoms = e['symptoms'] ?? 'none';
        final painLevel = e['painLevel'] ?? 0;
        final phase = e['phase'] ?? 'unknown';
        return 'Phase: $phase, Mood: $mood, Pain: $painLevel/5, Symptoms: $symptoms';
      }).join('\n');

      final prompt = '''
Based on the following 10 recent wellness check-ins for a menstrual cycle app user:

$summaryLines

Cycle data:
- Average cycle length: ${state.averageCycleLength} days
- Current phase: ${state.currentPhase}
- Total cycles logged: ${state.periodHistory.length}

Please generate a compassionate monthly wellness report covering:
1. Average mood pattern observed
2. Common symptoms noted
3. Overall wellness observations
4. 3 personalized recommendations for next month

Keep it warm, supportive, and under 200 words.
''';

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
                  'You are Bloom, a compassionate menstrual health assistant. Generate warm, supportive wellness reports.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 350,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && mounted) {
          setState(() => _monthlyReport = content.trim());
        }
      } else {
        if (mounted) {
          setState(() => _monthlyReport =
              'Unable to generate report. Please check your connection and try again.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _monthlyReport =
            'Unable to generate report. Please check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _generatingReport = false);
    }
  }

  List<_SupplementData> _getSupplements(String phase) {
    switch (phase) {
      case 'Menstrual':
        return [
          _SupplementData(name: 'Iron', benefit: 'Replenishes iron lost during menstruation, prevents fatigue', icon: '🩸', color: const Color(0xFFE57373)),
          _SupplementData(name: 'Magnesium', benefit: 'Reduces cramping and muscle tension, eases PMS symptoms', icon: '✨', color: const Color(0xFFE57373)),
          _SupplementData(name: 'Ginger', benefit: 'Natural anti-inflammatory that soothes cramps and nausea', icon: '🫚', color: const Color(0xFFE57373)),
        ];
      case 'Follicular':
        return [
          _SupplementData(name: 'B Vitamins', benefit: 'Boosts energy and supports estrogen metabolism as levels rise', icon: '💊', color: const Color(0xFF81C784)),
          _SupplementData(name: 'Zinc', benefit: 'Supports immune function and skin health during this growth phase', icon: '⚡', color: const Color(0xFF81C784)),
          _SupplementData(name: 'Probiotics', benefit: 'Supports gut health and hormonal balance', icon: '🌱', color: const Color(0xFF81C784)),
        ];
      case 'Ovulation':
        return [
          _SupplementData(name: 'Vitamin C', benefit: 'Supports progesterone production and immune health at ovulation', icon: '🍊', color: const Color(0xFFFFD54F)),
          _SupplementData(name: 'CoQ10', benefit: 'Supports egg quality and mitochondrial energy production', icon: '⚡', color: const Color(0xFFFFD54F)),
          _SupplementData(name: 'Maca', benefit: 'Adaptogen that may support hormonal balance and libido', icon: '🌿', color: const Color(0xFFFFD54F)),
        ];
      case 'Luteal':
        return [
          _SupplementData(name: 'Vitamin D', benefit: 'Reduces PMS symptoms and supports mood regulation', icon: '☀️', color: const Color(0xFFBA68C8)),
          _SupplementData(name: 'Calcium', benefit: 'Alleviates mood swings, bloating, and cramp discomfort', icon: '🦴', color: const Color(0xFFBA68C8)),
          _SupplementData(name: 'Evening Primrose', benefit: 'Rich in GLA, helps reduce breast tenderness and PMS', icon: '🌸', color: const Color(0xFFBA68C8)),
        ];
      default:
        return [
          _SupplementData(name: 'Vitamin D', benefit: 'Supports overall hormonal health and mood regulation', icon: '☀️', color: const Color(0xFFBA68C8)),
          _SupplementData(name: 'Magnesium', benefit: 'Essential for hundreds of bodily processes including hormone balance', icon: '✨', color: const Color(0xFFBA68C8)),
          _SupplementData(name: 'Omega-3', benefit: 'Reduces inflammation and supports hormonal balance', icon: '🐟', color: const Color(0xFFBA68C8)),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<CycleState>(
      builder: (context, state, _) {
        final supplements = _getSupplements(state.currentPhase);
        final fertileStart = state.fertileWindowStart;
        final fertileEnd = state.fertileWindowEnd;
        final ovulation = state.ovulationDay;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Gradient App Bar ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: _phaseGradient.first,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: _phaseGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Insights',
                            style: GoogleFonts.philosopher(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'AI reports & personalised guidance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Insights',
                  style: GoogleFonts.philosopher(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── AI Monthly Report ──────────────────────────────
                      _SectionTitle(title: 'AI Monthly Report'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFBA68C8).withValues(alpha: 0.15),
                              const Color(0xFFBA68C8).withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFBA68C8).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBA68C8).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome,
                                      color: Color(0xFFBA68C8), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Monthly Wellness Report',
                                  style: GoogleFonts.philosopher(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFFBA68C8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_monthlyReport.isNotEmpty)
                              Text(
                                _monthlyReport,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1.7,
                                  color: scheme.onSurface.withValues(alpha: 0.85),
                                ),
                              )
                            else
                              Text(
                                state.checkinHistory.isEmpty
                                    ? 'Complete at least one check-in to generate your personalized report.'
                                    : 'Tap below to generate your AI-powered monthly wellness report.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface.withValues(alpha: 0.6),
                                  height: 1.5,
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: state.checkinHistory.isEmpty || _generatingReport
                                    ? null
                                    : () => _generateMonthlyReport(state),
                                icon: _generatingReport
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.analytics_outlined),
                                label: Text(
                                  _generatingReport
                                      ? 'Generating report…'
                                      : 'Generate My Report',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBA68C8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Fertile Window Info ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Fertile Window'),
                          TextButton.icon(
                            onPressed: () => context.push('/ovulation'),
                            icon: const Icon(Icons.track_changes, size: 16),
                            label: const Text('Track', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (fertileStart == null || fertileEnd == null)
                        _InfoCard(
                          icon: Icons.calendar_month_outlined,
                          color: const Color(0xFF81C784),
                          content:
                              'Log your period start date to see your fertile window.',
                        )
                      else
                        _FertileWindowCard(
                          fertileStart: fertileStart,
                          fertileEnd: fertileEnd,
                          ovulationDay: ovulation,
                        ),
                      const SizedBox(height: 28),

                      // ── Supplement Suggestions ─────────────────────────
                      _SectionTitle(title: 'Supplement Suggestions'),
                      const SizedBox(height: 4),
                      Text(
                        'Based on your ${state.currentPhase} phase',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...supplements.map((s) => _SupplementCard(
                            name: s.name,
                            benefit: s.benefit,
                            icon: s.icon,
                            color: s.color,
                          )),
                      const SizedBox(height: 28),

                      // ── Custom Cycle Length ────────────────────────────
                      _SectionTitle(title: 'Cycle Length Setting'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.loop,
                                    color: scheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cycle Length: ${state.customCycleLength} days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adjust to match your natural cycle (21–45 days)',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            Slider(
                              value: state.customCycleLength.toDouble(),
                              min: 21,
                              max: 45,
                              divisions: 24,
                              label: '${state.customCycleLength} days',
                              activeColor: scheme.primary,
                              onChanged: (val) => state.setCycleLength(val.round()),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('21 days',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurface.withValues(alpha: 0.4))),
                                Text('45 days',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurface.withValues(alpha: 0.4))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Birth Control Mode ─────────────────────────────
                      _SectionTitle(title: 'Birth Control Mode'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Birth Control Mode',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adjusts phase display to Active/Inactive for pill-based contraception.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface.withValues(alpha: 0.55),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: state.birthControlMode,
                              onChanged: (val) => state.setBirthControlMode(val),
                              activeColor: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.philosopher(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fertile Window Card ──────────────────────────────────────────────────────

class _FertileWindowCard extends StatelessWidget {
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final DateTime? ovulationDay;

  const _FertileWindowCard({
    required this.fertileStart,
    required this.fertileEnd,
    this.ovulationDay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(fertileStart.year, fertileStart.month, fertileStart.day);
    final end = DateTime(fertileEnd.year, fertileEnd.month, fertileEnd.day);

    final String countdownText;
    if (today.isBefore(start)) {
      final daysUntil = start.difference(today).inDays;
      countdownText = 'Starts in $daysUntil day${daysUntil == 1 ? '' : 's'}';
    } else if (!today.isAfter(end)) {
      final daysLeft = end.difference(today).inDays + 1;
      countdownText = 'Active — $daysLeft day${daysLeft == 1 ? '' : 's'} remaining';
    } else {
      countdownText = 'Completed this cycle';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF81C784).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border,
                    color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MMM d').format(fertileStart)} – ${DateFormat('MMM d').format(fertileEnd)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      countdownText,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ovulationDay != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFF57F17), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Ovulation: ${DateFormat('EEE, MMM d').format(ovulationDay!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57F17),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Supplement Card ──────────────────────────────────────────────────────────

class _SupplementCard extends StatelessWidget {
  final String name;
  final String benefit;
  final String icon;
  final Color color;

  const _SupplementCard({
    required this.name,
    required this.benefit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  benefit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supplement Data Model ────────────────────────────────────────────────────

class _SupplementData {
  final String name;
  final String benefit;
  final String icon;
  final Color color;

  const _SupplementData({
    required this.name,
    required this.benefit,
    required this.icon,
    required this.color,
  });
}
