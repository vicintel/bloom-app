import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _phaseGradient = [Color(0xFFBA68C8), Color(0xFF7B1FA2)];

  int _moodScore(String? mood) {
    if (mood == null) return 0;
    final m = mood.toLowerCase();
    if (m.contains('happy') || m.contains('energetic')) return 5;
    if (m.contains('calm')) return 4;
    if (m.contains('tired') || m.contains('anxious')) return 3;
    if (m.contains('sad') || m.contains('frustrated')) return 2;
    if (m.contains('unwell')) return 1;
    return 3;
  }

  String _moodEmoji(String? mood) {
    if (mood == null) return '😶';
    final m = mood.toLowerCase();
    if (m.contains('happy')) return '😊';
    if (m.contains('sad')) return '😔';
    if (m.contains('frustrated')) return '😤';
    if (m.contains('calm')) return '😌';
    if (m.contains('tired')) return '😴';
    if (m.contains('energetic')) return '⚡';
    if (m.contains('anxious')) return '😰';
    if (m.contains('unwell')) return '🤒';
    return '😶';
  }

  Map<String, int> _countSymptoms(List<Map<String, dynamic>> history) {
    const keywords = ['cramps', 'bloating', 'headache', 'fatigue', 'nausea'];
    final counts = {for (var k in keywords) k: 0};
    for (final entry in history) {
      final symptoms = (entry['symptoms'] as String? ?? '').toLowerCase();
      final description = (entry['description'] as String? ?? '').toLowerCase();
      final combined = '$symptoms $description';
      for (final kw in keywords) {
        if (combined.contains(kw)) {
          counts[kw] = (counts[kw] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CycleState>(
      builder: (context, state, _) {
        final history = state.checkinHistory;
        final periodHistory = state.periodHistory;

        // Last 14 check-ins for mood trend
        final moodData = history.length > 14
            ? history.sublist(history.length - 14)
            : history.toList();

        // Last 6 cycles
        final sortedPeriods = [...periodHistory]
          ..sort((a, b) => a.compareTo(b));
        final cycleLengths = <double>[];
        for (int i = 1; i < sortedPeriods.length && cycleLengths.length < 6; i++) {
          cycleLengths.add(
              sortedPeriods[i].difference(sortedPeriods[i - 1]).inDays.toDouble());
        }

        // Symptom counts
        final symptomCounts = _countSymptoms(history);
        final sortedSymptoms = symptomCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5Symptoms = sortedSymptoms.take(5).toList();

        // Last 5 check-ins
        final recentCheckins = history.length > 5
            ? history.sublist(history.length - 5).reversed.toList()
            : history.reversed.toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Gradient App Bar ─────────────────────────────────────
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
                            'My History',
                            style: GoogleFonts.philosopher(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Charts & trends from your logs',
                            style: const TextStyle(
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
                  'My History',
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
                      // ── Mood Trend Chart ───────────────────────────────
                      _SectionHeader(title: 'Mood Trend'),
                      const SizedBox(height: 12),
                      if (moodData.length < 2)
                        _EmptyChart(
                            message: 'Log more check-ins to see mood trends')
                      else
                        _MoodLineChart(moodData: moodData, moodScore: _moodScore),
                      const SizedBox(height: 28),

                      // ── Cycle Length History ───────────────────────────
                      _SectionHeader(title: 'Cycle Length History'),
                      const SizedBox(height: 12),
                      if (cycleLengths.isEmpty)
                        _EmptyChart(
                            message: 'Log more periods to see cycle history')
                      else
                        _CycleLengthBarChart(cycleLengths: cycleLengths),
                      const SizedBox(height: 28),

                      // ── Symptom Frequency ──────────────────────────────
                      _SectionHeader(title: 'Symptom Frequency'),
                      const SizedBox(height: 12),
                      if (top5Symptoms.every((e) => e.value == 0))
                        _EmptyChart(
                            message:
                                'Log more check-ins to see symptom trends')
                      else
                        _SymptomBarChart(symptoms: top5Symptoms),
                      const SizedBox(height: 28),

                      // ── Recent Check-ins ───────────────────────────────
                      _SectionHeader(title: 'Recent Check-ins'),
                      const SizedBox(height: 12),
                      if (recentCheckins.isEmpty)
                        _EmptyChart(message: 'No check-ins logged yet'),
                      ...recentCheckins.map((entry) => _CheckinCard(
                            entry: entry,
                            moodEmoji: _moodEmoji(entry['mood'] as String?),
                          )),
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

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

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

// ─── Empty Chart Placeholder ──────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_outlined,
              color: scheme.onSurface.withValues(alpha: 0.3), size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mood Line Chart ──────────────────────────────────────────────────────────

class _MoodLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;
  final int Function(String?) moodScore;

  const _MoodLineChart({required this.moodData, required this.moodScore});

  @override
  Widget build(BuildContext context) {
    final spots = moodData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), moodScore(e.value['mood'] as String?).toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  const labels = ['', '😞', '😔', '😐', '😌', '😊'];
                  final idx = value.round();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Text(labels[idx], style: const TextStyle(fontSize: 11));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (moodData.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (idx < 0 || idx >= moodData.length) return const SizedBox.shrink();
                  final ts = moodData[idx]['timestamp'] as String?;
                  if (ts == null) return const SizedBox.shrink();
                  try {
                    final date = DateTime.parse(ts);
                    return Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFBA68C8),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFBA68C8),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFBA68C8).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cycle Length Bar Chart ───────────────────────────────────────────────────

class _CycleLengthBarChart extends StatelessWidget {
  final List<double> cycleLengths;
  const _CycleLengthBarChart({required this.cycleLengths});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: (cycleLengths.reduce((a, b) => a > b ? a : b) + 5).ceilToDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 7,
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  return Text(
                    'C${idx + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 7,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: cycleLengths.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: const Color(0xFF81C784),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Symptom Bar Chart ────────────────────────────────────────────────────────

class _SymptomBarChart extends StatelessWidget {
  final List<MapEntry<String, int>> symptoms;
  const _SymptomBarChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final maxVal = symptoms.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxVal + 1).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value != value.round()) return const SizedBox.shrink();
                  return Text(
                    '${value.round()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (idx < 0 || idx >= symptoms.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      symptoms[idx].key,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: symptoms.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  color: const Color(0xFFE57373),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Check-in Card ────────────────────────────────────────────────────────────

class _CheckinCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String moodEmoji;

  const _CheckinCard({required this.entry, required this.moodEmoji});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ts = entry['timestamp'] as String?;
    String dateStr = 'Unknown date';
    if (ts != null) {
      try {
        final date = DateTime.parse(ts);
        dateStr = DateFormat('EEE, MMM d • h:mm a').format(date);
      } catch (_) {}
    }

    final mood = entry['mood'] as String? ?? 'No mood';
    final painLevel = entry['painLevel'] as int? ?? 0;
    final flow = entry['flow'] as String?;
    final phase = entry['phase'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(moodEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (phase.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    phase,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (painLevel > 0 || flow != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (painLevel > 0) ...[
                  Icon(Icons.sentiment_very_dissatisfied_outlined,
                      size: 14,
                      color: scheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Pain: $painLevel/5',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (flow != null) ...[
                  Icon(Icons.water_drop_outlined,
                      size: 14,
                      color: const Color(0xFFE57373).withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    flow,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
