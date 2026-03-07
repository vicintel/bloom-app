import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class CycleCalendar extends StatefulWidget {
  final Function(String) onDaySelected;

  const CycleCalendar({
    super.key,
    required this.onDaySelected,
  });

  @override
  State<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<CycleCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late List<DateTime> _periodDays;
  late List<DateTime> _fertilityWindow;
  late DateTime _lastCycleStart;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _initializeCycle();
  }

  void _initializeCycle() {
    // Calculate last cycle start (typically around 20 days ago for a 28-day cycle)
    _lastCycleStart = DateTime.now().subtract(const Duration(days: 8));

    // Period days: 5 days starting from cycle start
    _periodDays = List.generate(
      5,
      (index) => _lastCycleStart.add(Duration(days: index)),
    );

    // Fertility window: days 11-16 of the cycle
    _fertilityWindow = List.generate(
      6,
      (index) => _lastCycleStart.add(Duration(days: 10 + index)),
    );
  }

  bool _isPeriodDay(DateTime day) {
    return _periodDays.any(
      (periodDay) =>
          periodDay.year == day.year &&
          periodDay.month == day.month &&
          periodDay.day == day.day,
    );
  }

  bool _isFertilityDay(DateTime day) {
    return _fertilityWindow.any(
      (fertileDay) =>
          fertileDay.year == day.year &&
          fertileDay.month == day.month &&
          fertileDay.day == day.day,
    );
  }

  int _getCycleDayNumber(DateTime day) {
    final difference = day.difference(_lastCycleStart).inDays;
    if (difference >= 0 && difference < 28) {
      return difference + 1;
    }
    return -1;
  }

  String _getDayInsight(int cycleDay) {
    if (cycleDay <= 0 || cycleDay > 28) {
      return 'Track your cycle for personalized insights.';
    }

    if (cycleDay <= 5) {
      return 'Day $cycleDay: Menstrual Phase. Rest, hydrate, and focus on self-care. Iron-rich foods recommended.';
    } else if (cycleDay <= 10) {
      return 'Day $cycleDay: Follicular Phase. Energy rising! Great time for social activities and workouts.';
    } else if (cycleDay <= 16) {
      return 'Day $cycleDay: Ovulation & Fertility Peak. Maximum energy and confidence. Perfect for important tasks!';
    } else {
      return 'Day $cycleDay: Luteal Phase. Focus on rest and self-reflection. Slow down and recharge.';
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
    final cycleDay = _getCycleDayNumber(day);
    final insight = _getDayInsight(cycleDay);
    widget.onDaySelected(insight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8A0BF).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle Calendar',
            style: GoogleFonts.philosopher(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF463E2D),
            ),
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _onDaySelected(selectedDay);
            },
            onFormatChanged: (format) {},
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.philosopher(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF463E2D),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFFE8A0BF),
                size: 28,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFE8A0BF),
                size: 28,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.philosopher(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF463E2D).withOpacity(0.7),
              ),
              weekendStyle: GoogleFonts.philosopher(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF463E2D).withOpacity(0.7),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, true);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false);
              },
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: const Color(0xFFE8A0BF),
                label: 'Period Days',
              ),
              _buildLegendItem(
                color: const Color(0xFF4ECDC4),
                label: 'Fertility Window',
              ),
              _buildLegendItem(
                color: const Color(0xFF463E2D).withOpacity(0.3),
                label: 'Other Days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected) {
    final isPeriod = _isPeriodDay(day);
    final isFertile = _isFertilityDay(day);
    final isToday = isSameDay(day, DateTime.now());

    Color cellColor = Colors.transparent;
    if (isSelected) {
      cellColor = const Color(0xFFE8A0BF).withOpacity(0.3);
    } else if (isPeriod) {
      cellColor = const Color(0xFFE8A0BF).withOpacity(0.2);
    } else if (isFertile) {
      cellColor = const Color(0xFF4ECDC4).withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(
                color: const Color(0xFF463E2D),
                width: 2,
              )
            : null,
        boxShadow: isPeriod || isFertile
            ? [
                BoxShadow(
                  color: isPeriod
                      ? const Color(0xFFE8A0BF).withOpacity(0.3)
                      : const Color(0xFF4ECDC4).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPeriod)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8A0BF),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: GoogleFonts.philosopher(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF463E2D),
              ),
            ),
            if (isFertile)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.philosopher(
            fontSize: 12,
            color: const Color(0xFF463E2D).withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
