import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../state/cycle_state.dart';
import 'glass_container.dart';

class PhaseCalendar extends StatelessWidget {
  final List<DateTime> periodDays;
  final List<DateTime> fertileWindow;
  const PhaseCalendar({super.key, required this.periodDays, required this.fertileWindow});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CycleState>(context);
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: state.selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
        onDaySelected: (selected, focused) {
          state.updateDate(selected);
          // Trigger AI update elsewhere
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final isPeriod = periodDays.any((d) => isSameDay(d, day));
            final isFertile = fertileWindow.any((d) => isSameDay(d, day));
            return Container(
              decoration: BoxDecoration(
                color: isPeriod
                    ? const Color(0xFFF8BBD0).withOpacity(0.6)
                    : null,
                boxShadow: isFertile
                    ? [BoxShadow(color: Colors.tealAccent.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isPeriod ? Colors.white : isFertile ? Colors.teal[900] : null,
                  fontWeight: isPeriod || isFertile ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
