import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CycleState extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  DateTime? _periodStartDate;
  int cycleLength = 28;
  String aiInsight = '';
  String lastLog = '';
  List<String> tags = [];
  String adviceType = 'Nutrition';
  Map<String, dynamic> advice = {};
  List<DateTime> _periodHistory = [];

  CycleState() {
    _load();
  }

  DateTime? get periodStartDate => _periodStartDate;
  List<DateTime> get periodHistory => List.unmodifiable(_periodHistory);

  /// Average cycle length calculated from logged period history.
  /// Falls back to user-set cycleLength if fewer than 2 periods logged.
  int get averageCycleLength {
    if (_periodHistory.length < 2) return cycleLength;
    final sorted = [..._periodHistory]..sort((a, b) => a.compareTo(b));
    int total = 0;
    for (int i = 1; i < sorted.length; i++) {
      total += sorted[i].difference(sorted[i - 1]).inDays;
    }
    return (total / (sorted.length - 1)).round();
  }

  /// Predicted start date of next period.
  DateTime? get nextPeriodDate {
    if (_periodStartDate == null) return null;
    return _periodStartDate!.add(Duration(days: averageCycleLength));
  }

  /// Days until next predicted period (can be negative if overdue).
  int? get daysUntilNextPeriod {
    if (nextPeriodDate == null) return null;
    final today = DateTime.now();
    final next = DateTime(nextPeriodDate!.year, nextPeriodDate!.month, nextPeriodDate!.day);
    final todayNorm = DateTime(today.year, today.month, today.day);
    return next.difference(todayNorm).inDays;
  }

  int get cycleDay {
    if (_periodStartDate == null) return 0;
    final day = DateTime.now().difference(_periodStartDate!).inDays + 1;
    return day.clamp(1, cycleLength);
  }

  String get currentPhase {
    if (_periodStartDate == null) return 'Unknown';
    final day = cycleDay;
    if (day <= 5) return 'Menstrual';
    if (day <= 13) return 'Follicular';
    if (day <= 16) return 'Ovulation';
    return 'Luteal';
  }

  Color get phaseColor {
    switch (currentPhase) {
      case 'Menstrual':
        return const Color(0xFFE57373);
      case 'Follicular':
        return const Color(0xFF81C784);
      case 'Ovulation':
        return const Color(0xFFFFD54F);
      case 'Luteal':
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFFE8A0BF);
    }
  }

  String get phaseEmoji {
    switch (currentPhase) {
      case 'Menstrual':
        return '🌑';
      case 'Follicular':
        return '🌱';
      case 'Ovulation':
        return '🌕';
      case 'Luteal':
        return '🍂';
      default:
        return '🌸';
    }
  }

  String get phaseDescription {
    switch (currentPhase) {
      case 'Menstrual':
        return 'Rest, warmth, and nourishing foods. Be gentle with yourself.';
      case 'Follicular':
        return 'Energy is rising. Great time to start new projects and be social.';
      case 'Ovulation':
        return 'Peak energy and confidence. Tackle big tasks and connect with others.';
      case 'Luteal':
        return 'Wind down gradually. Focus on finishing tasks and self-care.';
      default:
        return 'Log your last period start to get personalized phase insights.';
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt('periodStartDate');
    if (startMs != null) {
      _periodStartDate = DateTime.fromMillisecondsSinceEpoch(startMs);
    }
    cycleLength = prefs.getInt('cycleLength') ?? 28;
    aiInsight = prefs.getString('aiInsight') ?? '';
    // Load period history
    final historyJson = prefs.getString('periodHistory');
    if (historyJson != null) {
      final List<dynamic> list = jsonDecode(historyJson);
      _periodHistory = list
          .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms as int))
          .toList();
    } else if (_periodStartDate != null) {
      // Migrate: seed history with existing start date
      _periodHistory = [_periodStartDate!];
    }
    notifyListeners();
  }

  Future<void> logPeriodStart(DateTime date) async {
    _periodStartDate = date;
    aiInsight = '';
    // Add to history if not already present (same day)
    final alreadyLogged = _periodHistory.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
    if (!alreadyLogged) {
      _periodHistory.add(date);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('periodStartDate', date.millisecondsSinceEpoch);
    await prefs.remove('aiInsight');
    await prefs.setString(
      'periodHistory',
      jsonEncode(_periodHistory.map((d) => d.millisecondsSinceEpoch).toList()),
    );
  }

  Future<void> clearPeriodHistory() async {
    _periodHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('periodHistory');
    notifyListeners();
  }

  void updateDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  Future<void> updateAIInsight(String insight) async {
    aiInsight = insight;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiInsight', insight);
  }

  void updateLog(String log) {
    lastLog = log;
    notifyListeners();
  }

  void updateTags(List<String> newTags) {
    tags = newTags;
    notifyListeners();
  }

  void updateAdviceType(String type) {
    adviceType = type;
    notifyListeners();
  }

  void updateAdvice(Map<String, dynamic> newAdvice) {
    advice = newAdvice;
    notifyListeners();
  }

  void reset() {
    selectedDate = DateTime.now();
    _periodStartDate = null;
    aiInsight = '';
    lastLog = '';
    tags = [];
    adviceType = 'Nutrition';
    advice = {};
    notifyListeners();
  }
}
