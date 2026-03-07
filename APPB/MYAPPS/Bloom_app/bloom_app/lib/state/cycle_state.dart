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

  CycleState() {
    _load();
  }

  DateTime? get periodStartDate => _periodStartDate;

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
    notifyListeners();
  }

  Future<void> logPeriodStart(DateTime date) async {
    _periodStartDate = date;
    aiInsight = ''; // clear cached insight so dashboard refetches for new phase
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('periodStartDate', date.millisecondsSinceEpoch);
    await prefs.remove('aiInsight');
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
