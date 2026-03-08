import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../state/cycle_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _fetchingInsight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadInsight());
  }

  Future<void> _maybeLoadInsight() async {
    final state = Provider.of<CycleState>(context, listen: false);
    if (state.aiInsight.isEmpty && state.periodStartDate != null) {
      await _fetchInsight(state);
    }
  }

  Future<void> _fetchInsight(CycleState state) async {
    if (_fetchingInsight) return;
    setState(() => _fetchingInsight = true);
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        await state.updateAIInsight(state.phaseDescription);
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
                  'You are Bloom, a compassionate menstrual health assistant. Give a single, warm, practical daily insight (2 sentences max).',
            },
            {
              'role': 'user',
              'content':
                  'Today I am on day ${state.cycleDay} of my cycle, in my ${state.currentPhase} phase. Give me a personalized daily insight.',
            },
          ],
          'max_tokens': 120,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && mounted) {
          await state.updateAIInsight(content.trim());
        }
      } else {
        await state.updateAIInsight(state.phaseDescription);
      }
    } catch (_) {
      await state.updateAIInsight(state.phaseDescription);
    } finally {
      if (mounted) setState(() => _fetchingInsight = false);
    }
  }

  Future<void> _logPeriod(CycleState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      helpText: 'When did your last period start?',
    );
    if (picked != null) {
      await state.logPeriodStart(picked);
      await _fetchInsight(state);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  List<Color> _phaseGradient(CycleState state) {
    switch (state.currentPhase) {
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
    return Consumer<CycleState>(
      builder: (context, state, _) {
        final gradient = _phaseGradient(state);
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // ── Hero App Bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: gradient.first,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  'Bloom',
                  style: GoogleFonts.philosopher(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined,
                        color: Colors.white),
                    tooltip: state.periodStartDate != null
                        ? 'Update period start'
                        : 'Log period start',
                    onPressed: () => _logPeriod(state),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _buildHeroContent(context, state, gradient),
                ),
              ),

              // ── Body Content ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Stats chips row
                      if (state.periodStartDate != null) ...[
                        _buildStatsRow(context, state),
                        const SizedBox(height: 14),
                        _buildPredictionCard(context, state),
                        const SizedBox(height: 24),
                      ],

                      // Calendar
                      _buildCalendarCard(context, state),
                      const SizedBox(height: 24),

                      // Today's Insight
                      _buildInsightSection(context, state),
                      const SizedBox(height: 28),

                      // Daily Log
                      Text(
                        'Daily Log',
                        style: GoogleFonts.philosopher(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildActionGrid(context),
                      const SizedBox(height: 48),
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

  // ─── Hero Content ─────────────────────────────────────────────────────────

  Widget _buildHeroContent(
      BuildContext context, CycleState state, List<Color> gradient) {
    final hasData = state.periodStartDate != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (hasData) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        state.currentPhase,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Day ${state.cycleDay} of ${state.cycleLength}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ] else
                    GestureDetector(
                      onTap: () => _logPeriod(state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Log Period Start',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right: cycle ring
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(110, 110),
                    painter: _CycleRingPainter(
                      progress: hasData
                          ? (state.cycleDay / state.cycleLength)
                              .clamp(0.0, 1.0)
                          : 0,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasData ? state.phaseEmoji : '🌸',
                        style: const TextStyle(fontSize: 34),
                      ),
                      if (hasData)
                        Text(
                          'Day ${state.cycleDay}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, CycleState state) {
    final daysLeft = (state.cycleLength - state.cycleDay).clamp(0, state.cycleLength);
    return Row(
      children: [
        _statChip(
          context,
          Icons.calendar_today_outlined,
          'Day ${state.cycleDay}',
          state.phaseColor,
        ),
        const SizedBox(width: 10),
        _statChip(
          context,
          Icons.circle,
          state.currentPhase,
          state.phaseColor,
        ),
        const SizedBox(width: 10),
        _statChip(
          context,
          Icons.timer_outlined,
          '$daysLeft days left',
          state.phaseColor,
        ),
      ],
    );
  }

  Widget _buildPredictionCard(BuildContext context, CycleState state) {
    final days = state.daysUntilNextPeriod;
    final nextDate = state.nextPeriodDate;
    if (days == null || nextDate == null) return const SizedBox.shrink();

    final String label;
    final IconData icon;
    final Color color;

    if (days < 0) {
      label = 'Period may be ${(-days)} day${(-days) == 1 ? '' : 's'} late';
      icon = Icons.notifications_active_outlined;
      color = const Color(0xFFE57373);
    } else if (days == 0) {
      label = 'Your period is expected today';
      icon = Icons.circle_notifications_outlined;
      color = const Color(0xFFE57373);
    } else if (days <= 3) {
      label = 'Period expected in $days day${days == 1 ? '' : 's'} — prepare!';
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFFF9800);
    } else {
      label = 'Next period in $days days';
      icon = Icons.calendar_month_outlined;
      color = state.phaseColor;
    }

    final dateStr = DateFormat('EEE, MMM d').format(nextDate);
    final confidence = state.periodHistory.length >= 3
        ? 'High confidence'
        : state.periodHistory.length == 2
            ? 'Moderate confidence'
            : 'Based on ${state.averageCycleLength}-day cycle';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr · $confidence',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Calendar ─────────────────────────────────────────────────────────────

  Widget _buildCalendarCard(BuildContext context, CycleState state) {
    final nextPeriod = state.nextPeriodDate;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              state.updateDate(selectedDay);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                // Highlight predicted next period day
                if (nextPeriod != null && isSameDay(day, nextPeriod)) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFE57373), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: state.periodStartDate != null
                    ? state.phaseColor
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: (state.periodStartDate != null
                        ? state.phaseColor
                        : Theme.of(context).colorScheme.primary)
                    .withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: state.periodStartDate != null
                    ? state.phaseColor
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ),
          if (nextPeriod != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFE57373), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Predicted period start',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
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

  // ─── Insight Section ──────────────────────────────────────────────────────

  Widget _buildInsightSection(BuildContext context, CycleState state) {
    final insight =
        state.aiInsight.isEmpty ? state.phaseDescription : state.aiInsight;
    final accentColor = state.periodStartDate != null
        ? state.phaseColor
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Insight",
              style: GoogleFonts.philosopher(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _fetchingInsight ? null : () => _fetchInsight(state),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fetchingInsight
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          )
                        : Icon(Icons.refresh, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.12),
                accentColor.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.auto_awesome, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    state.currentPhase == 'Unknown'
                        ? 'Wellness Tip'
                        : '${state.currentPhase} Phase',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                insight,
                style: GoogleFonts.poppins(
                  height: 1.6,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Action Grid ──────────────────────────────────────────────────────────

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        _buildActionCard(
          context,
          icon: Icons.water_drop,
          label: 'Flow',
          subtitle: 'Log today',
          gradientColors: [const Color(0xFFEF5350), const Color(0xFFB71C1C)],
          onTap: () => context.go('/checkin'),
        ),
        _buildActionCard(
          context,
          icon: Icons.mood,
          label: 'Mood',
          subtitle: 'How are you?',
          gradientColors: [const Color(0xFFFF9800), const Color(0xFFE65100)],
          onTap: () => context.go('/checkin'),
        ),
        _buildActionCard(
          context,
          icon: Icons.restaurant_outlined,
          label: 'Nutrition',
          subtitle: 'Phase foods',
          gradientColors: [const Color(0xFF43A047), const Color(0xFF1B5E20)],
          onTap: () => context.push('/nutrition'),
        ),
        _buildActionCard(
          context,
          icon: Icons.fitness_center,
          label: 'Fitness',
          subtitle: 'Workouts',
          gradientColors: [const Color(0xFF1E88E5), const Color(0xFF0D47A1)],
          onTap: () => context.push('/fitness'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter: Cycle Ring ──────────────────────────────────────────────

class _CycleRingPainter extends CustomPainter {
  final double progress;
  _CycleRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const strokeWidth = 7.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) => old.progress != progress;
}
