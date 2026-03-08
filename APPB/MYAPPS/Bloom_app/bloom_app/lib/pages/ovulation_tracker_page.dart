import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/cycle_state.dart';

class OvulationTrackerPage extends StatefulWidget {
  const OvulationTrackerPage({super.key});

  @override
  State<OvulationTrackerPage> createState() => _OvulationTrackerPageState();
}

class _OvulationTrackerPageState extends State<OvulationTrackerPage> {
  // Cervical mucus options
  static const _mucusOptions = [
    _MucusOption('Dry', '🔴', 'No discharge', Color(0xFFEF9A9A)),
    _MucusOption('Sticky', '🟠', 'Thick, cloudy', Color(0xFFFFCC80)),
    _MucusOption('Creamy', '🟡', 'Lotion-like, white', Color(0xFFFFF176)),
    _MucusOption('Watery', '🔵', 'Clear, slippery', Color(0xFF80DEEA)),
    _MucusOption('Egg White', '⚪', 'Clear, stretchy — most fertile', Color(0xFF81C784)),
  ];

  String? _selectedMucus;
  double _bbt = 36.5;
  bool _hasPain = false;
  bool _positiveOpk = false;
  bool _isSaving = false;

  static const _gradientColors = [Color(0xFFFFD54F), Color(0xFFF57F17)];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<CycleState>(
      builder: (context, state, _) {
        final predicted = state.ovulationDay;
        final confirmed = state.confirmedOvulationDate;
        final logs = state.ovulationLogs.reversed.toList();

        // Pre-fill today's log if exists
        final today = DateTime.now();
        final todayLog = logs.firstWhere(
          (e) {
            final d = DateTime.tryParse(e['date'] as String? ?? '');
            return d != null &&
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          },
          orElse: () => {},
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Gradient Header ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: _gradientColors.first,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors,
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
                            'Ovulation Tracker',
                            style: GoogleFonts.philosopher(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Log daily signs to pinpoint ovulation',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Ovulation Tracker',
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
                      // ── Predicted vs Confirmed ────────────────────────
                      _buildStatusRow(predicted, confirmed, scheme),
                      const SizedBox(height: 28),

                      // ── Today's Log Form ──────────────────────────────
                      _SectionTitle(title: "Today's Signs"),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d').format(today),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (todayLog.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Already logged today — submitting will update it',
                            style: TextStyle(
                                fontSize: 11, color: Colors.green),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Cervical Mucus
                      _buildCard(
                        scheme: scheme,
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFF4FC3F7),
                        title: 'Cervical Mucus',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _mucusOptions.map((opt) {
                            final selected = _selectedMucus == opt.label;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedMucus = opt.label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? opt.color.withValues(alpha: 0.3)
                                      : opt.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? opt.color
                                        : opt.color.withValues(alpha: 0.3),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(opt.emoji,
                                            style: const TextStyle(
                                                fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          opt.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: selected
                                                ? scheme.onSurface
                                                : scheme.onSurface
                                                    .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BBT
                      _buildCard(
                        scheme: scheme,
                        icon: Icons.thermostat_outlined,
                        color: const Color(0xFFFF7043),
                        title:
                            'Basal Body Temperature (BBT): ${_bbt.toStringAsFixed(1)}°C',
                        child: Column(
                          children: [
                            Slider(
                              value: _bbt,
                              min: 35.5,
                              max: 38.0,
                              divisions: 25,
                              label: '${_bbt.toStringAsFixed(1)}°C',
                              activeColor: const Color(0xFFFF7043),
                              onChanged: (v) =>
                                  setState(() => _bbt = double.parse(v.toStringAsFixed(1))),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('35.5°C',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.4))),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _bbt >= 36.5
                                        ? Colors.orange.withValues(alpha: 0.15)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _bbt >= 37.0
                                        ? '🌡 Post-ovulation rise'
                                        : _bbt >= 36.5
                                            ? '🌡 Normal range'
                                            : '🌡 Below baseline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _bbt >= 36.5
                                          ? Colors.orange
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                Text('38.0°C',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.4))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pain & OPK
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleCard(
                              scheme: scheme,
                              icon: '⚡',
                              title: 'Ovulation Pain',
                              subtitle: 'Mittelschmerz',
                              value: _hasPain,
                              color: const Color(0xFFEF5350),
                              onChanged: (v) =>
                                  setState(() => _hasPain = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildToggleCard(
                              scheme: scheme,
                              icon: '🧪',
                              title: 'Positive OPK',
                              subtitle: 'LH surge detected',
                              value: _positiveOpk,
                              color: const Color(0xFF81C784),
                              onChanged: (v) =>
                                  setState(() => _positiveOpk = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _saveLog(context, state),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Saving…' : "Save Today's Signs",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF57F17),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── OPK Info Card ─────────────────────────────────
                      _buildInfoBox(scheme),
                      const SizedBox(height: 28),

                      // ── Log History ───────────────────────────────────
                      if (logs.isNotEmpty) ...[
                        _SectionTitle(title: 'Recent Logs'),
                        const SizedBox(height: 12),
                        ...logs.take(7).map((log) => _buildLogTile(log, scheme)),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildStatusRow(
      DateTime? predicted, DateTime? confirmed, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: 'Predicted',
            value: predicted != null
                ? DateFormat('MMM d').format(predicted)
                : 'Log period first',
            icon: Icons.schedule_outlined,
            color: const Color(0xFFFFD54F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusChip(
            label: 'Confirmed',
            value: confirmed != null
                ? DateFormat('MMM d').format(confirmed)
                : 'Not yet confirmed',
            icon: confirmed != null
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: confirmed != null
                ? const Color(0xFF81C784)
                : scheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required ColorScheme scheme,
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required ColorScheme scheme,
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? color : scheme.outline.withValues(alpha: 0.2),
            width: value ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: value ? color : scheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'How to read your signs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
              emoji: '⚪',
              text: 'Egg-white mucus = highest fertility, ovulation imminent'),
          _InfoRow(
              emoji: '🌡',
              text:
                  'BBT rises 0.2–0.5°C after ovulation and stays high for 3+ days'),
          _InfoRow(
              emoji: '🧪',
              text:
                  'Positive OPK (LH surge) means ovulation likely within 24–36 hrs'),
          _InfoRow(
              emoji: '⚡',
              text:
                  'Ovulation pain (mittelschmerz) is a one-sided twinge near ovary'),
        ],
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log, ColorScheme scheme) {
    final date = DateTime.tryParse(log['date'] as String? ?? '');
    final mucus = log['mucus'] as String? ?? '—';
    final bbt = log['bbt'] as double?;
    final pain = log['pain'] as bool? ?? false;
    final opk = log['opk'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                date != null ? DateFormat('MMM').format(date) : '—',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                date != null ? DateFormat('d').format(date) : '—',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mucus: $mucus',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (bbt != null)
                      _Chip(
                          label: '${bbt.toStringAsFixed(1)}°C',
                          color: const Color(0xFFFF7043)),
                    if (pain)
                      _Chip(
                          label: '⚡ Pain',
                          color: const Color(0xFFEF5350)),
                    if (opk)
                      _Chip(
                          label: '🧪 +OPK',
                          color: const Color(0xFF81C784)),
                  ],
                ),
              ],
            ),
          ),
          if (opk)
            const Icon(Icons.check_circle,
                color: Color(0xFF81C784), size: 20),
        ],
      ),
    );
  }

  Future<void> _saveLog(BuildContext context, CycleState state) async {
    setState(() => _isSaving = true);
    await state.logOvulationSigns({
      'mucus': _selectedMucus,
      'bbt': _bbt,
      'pain': _hasPain,
      'opk': _positiveOpk,
    });

    // If positive OPK, confirm today as ovulation
    if (_positiveOpk) {
      await state.confirmOvulation(DateTime.now());
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _positiveOpk
                ? 'Signs saved! Positive OPK recorded — ovulation confirmed today.'
                : 'Ovulation signs saved for today.',
          ),
          backgroundColor:
              _positiveOpk ? const Color(0xFF81C784) : null,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _MucusOption {
  final String label;
  final String emoji;
  final String description;
  final Color color;
  const _MucusOption(this.label, this.emoji, this.description, this.color);
}

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

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatusChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color == Theme.of(context).colorScheme.outline
                  ? scheme.onSurface.withValues(alpha: 0.4)
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _InfoRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
