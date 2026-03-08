import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

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

  // New fields
  int customCycleLength = 28;
  bool birthControlMode = false;
  List<Map<String, dynamic>> _checkinHistory = [];
  Map<String, int> _waterSleepToday = {};

  // Ovulation tracking
  List<Map<String, dynamic>> _ovulationLogs = [];
  DateTime? _confirmedOvulationDate;

  CycleState() {
    _load();
  }

  DateTime? get periodStartDate => _periodStartDate;
  List<DateTime> get periodHistory => List.unmodifiable(_periodHistory);

  // New getters
  DateTime? get fertileWindowStart =>
      _periodStartDate?.add(const Duration(days: 10));
  DateTime? get fertileWindowEnd =>
      _periodStartDate?.add(const Duration(days: 16));
  DateTime? get ovulationDay =>
      _periodStartDate?.add(const Duration(days: 14));

  List<Map<String, dynamic>> get checkinHistory =>
      List.unmodifiable(_checkinHistory);

  List<Map<String, dynamic>> get ovulationLogs =>
      List.unmodifiable(_ovulationLogs);
  DateTime? get confirmedOvulationDate => _confirmedOvulationDate;

  int get waterToday => _waterSleepToday['water'] ?? 0;
  int get sleepToday => _waterSleepToday['sleep'] ?? 0;

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
    if (birthControlMode) {
      // In birth control mode: only Active/Inactive phases
      final day = cycleDay;
      return day <= 21 ? 'Active' : 'Inactive';
    }
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
      case 'Active':
        return const Color(0xFF42A5F5);
      case 'Inactive':
        return const Color(0xFF78909C);
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
      case 'Active':
        return '💊';
      case 'Inactive':
        return '⏸️';
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
      case 'Active':
        return 'Active pill phase. Take your pill at the same time each day.';
      case 'Inactive':
        return 'Inactive pill phase. You may experience withdrawal bleeding.';
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
      _periodHistory = [_periodStartDate!];
    }

    // Load check-in history
    final checkinJson = prefs.getString('checkin_history');
    if (checkinJson != null) {
      final List<dynamic> list = jsonDecode(checkinJson);
      _checkinHistory = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // Load water/sleep
    final waterSleepJson = prefs.getString('water_sleep_today');
    if (waterSleepJson != null) {
      final Map<String, dynamic> map = jsonDecode(waterSleepJson);
      _waterSleepToday = map.map((k, v) => MapEntry(k, v as int));
    }

    // Load custom cycle length
    customCycleLength = prefs.getInt('custom_cycle_length') ?? 28;

    // Load birth control mode
    birthControlMode = prefs.getBool('birth_control_mode') ?? false;

    // Load ovulation logs
    final ovulationJson = prefs.getString('ovulation_logs');
    if (ovulationJson != null) {
      final List<dynamic> list = jsonDecode(ovulationJson);
      _ovulationLogs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // Load confirmed ovulation date
    final confirmedMs = prefs.getInt('confirmed_ovulation_date');
    if (confirmedMs != null) {
      _confirmedOvulationDate = DateTime.fromMillisecondsSinceEpoch(confirmedMs);
    }

    notifyListeners();
  }

  Future<void> logPeriodStart(DateTime date) async {
    _periodStartDate = date;
    aiInsight = '';
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

    // Schedule late period alert
    if (nextPeriodDate != null) {
      await NotificationService.scheduleLateperiodAlert(nextPeriodDate!);
    }
  }

  Future<void> logCheckin(Map<String, dynamic> entry) async {
    final entryWithTimestamp = {
      ...entry,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _checkinHistory.add(entryWithTimestamp);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkin_history', jsonEncode(_checkinHistory));
  }

  Future<void> logWater(int glasses) async {
    _waterSleepToday['water'] = glasses;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_sleep_today', jsonEncode(_waterSleepToday));
  }

  Future<void> logSleep(int hours) async {
    _waterSleepToday['sleep'] = hours;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_sleep_today', jsonEncode(_waterSleepToday));
  }

  Future<void> setCycleLength(int length) async {
    customCycleLength = length;
    cycleLength = length;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_cycle_length', length);
    await prefs.setInt('cycleLength', length);
  }

  Future<void> setBirthControlMode(bool val) async {
    birthControlMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('birth_control_mode', val);
  }

  Future<void> clearCheckinHistory() async {
    _checkinHistory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('checkin_history');
  }

  Future<void> logOvulationSigns(Map<String, dynamic> entry) async {
    final entryWithDate = {
      ...entry,
      'date': DateTime.now().toIso8601String(),
    };
    // Replace today's log if one already exists
    final today = DateTime.now();
    _ovulationLogs.removeWhere((e) {
      final d = DateTime.tryParse(e['date'] as String? ?? '');
      return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    });
    _ovulationLogs.add(entryWithDate);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ovulation_logs', jsonEncode(_ovulationLogs));
  }

  Future<void> confirmOvulation(DateTime date) async {
    _confirmedOvulationDate = date;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('confirmed_ovulation_date', date.millisecondsSinceEpoch);
  }

  Future<void> clearOvulationLogs() async {
    _ovulationLogs.clear();
    _confirmedOvulationDate = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ovulation_logs');
    await prefs.remove('confirmed_ovulation_date');
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
    _checkinHistory.clear();
    _waterSleepToday.clear();
    notifyListeners();
  }
}
