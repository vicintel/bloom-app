import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageCategory { cycle, reminder, tip, alert }

class AppMessage {
  final String id;
  final String title;
  final String body;
  final MessageCategory category;
  final DateTime timestamp;
  bool isRead;

  AppMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  IconData get icon {
    switch (category) {
      case MessageCategory.cycle:
        return Icons.water_drop_outlined;
      case MessageCategory.reminder:
        return Icons.alarm_outlined;
      case MessageCategory.tip:
        return Icons.lightbulb_outlined;
      case MessageCategory.alert:
        return Icons.notifications_active_outlined;
    }
  }

  Color categoryColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (category) {
      case MessageCategory.cycle:
        return Colors.pinkAccent;
      case MessageCategory.reminder:
        return cs.primary;
      case MessageCategory.tip:
        return Colors.amber.shade700;
      case MessageCategory.alert:
        return Colors.orange.shade700;
    }
  }

  String get categoryLabel {
    switch (category) {
      case MessageCategory.cycle:
        return 'Cycle';
      case MessageCategory.reminder:
        return 'Reminder';
      case MessageCategory.tip:
        return 'Tip';
      case MessageCategory.alert:
        return 'Alert';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.index,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory AppMessage.fromJson(Map<String, dynamic> j) => AppMessage(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        category: MessageCategory.values[j['category'] as int],
        timestamp: DateTime.parse(j['timestamp'] as String),
        isRead: j['isRead'] as bool? ?? false,
      );
}

class MessageStore extends ChangeNotifier {
  static const _key = 'app_messages';
  List<AppMessage> _messages = [];

  List<AppMessage> get messages =>
      List.unmodifiable(_messages..sort((a, b) => b.timestamp.compareTo(a.timestamp)));

  int get unreadCount => _messages.where((m) => !m.isRead).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _messages = list.map((e) => AppMessage.fromJson(e as Map<String, dynamic>)).toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }

  Future<void> addMessage(AppMessage msg) async {
    // Avoid duplicates by id
    if (_messages.any((m) => m.id == msg.id)) return;
    _messages.add(msg);
    await _save();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final m = _messages.firstWhere((m) => m.id == id, orElse: () => throw StateError('not found'));
    if (!m.isRead) {
      m.isRead = true;
      await _save();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    bool changed = false;
    for (final m in _messages) {
      if (!m.isRead) {
        m.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String id) async {
    _messages.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _messages.clear();
    await _save();
    notifyListeners();
  }

  /// Seeds automatic messages based on cycle data.
  /// Call this from dashboard after cycle state loads.
  Future<void> seedCycleMessages({
    required int? daysUntilPeriod,
    required int? daysUntilOvulation,
    required String currentPhase,
  }) async {
    final now = DateTime.now();

    if (daysUntilPeriod != null) {
      if (daysUntilPeriod == 0) {
        await addMessage(AppMessage(
          id: 'period_today_${now.year}${now.month}${now.day}',
          title: 'Period Expected Today',
          body: 'Your period is expected today. Make sure you have what you need. Take it easy if you feel discomfort.',
          category: MessageCategory.alert,
          timestamp: now,
        ));
      } else if (daysUntilPeriod == 3) {
        await addMessage(AppMessage(
          id: 'period_3d_${now.year}${now.month}${now.day}',
          title: 'Period in 3 Days',
          body: 'Your period is coming up in 3 days. Stay hydrated and consider stocking up on supplies.',
          category: MessageCategory.cycle,
          timestamp: now,
        ));
      } else if (daysUntilPeriod == 7) {
        await addMessage(AppMessage(
          id: 'period_7d_${now.year}${now.month}${now.day}',
          title: 'Period in 1 Week',
          body: 'Your period is about a week away. PMS symptoms may begin soon — be kind to yourself.',
          category: MessageCategory.cycle,
          timestamp: now,
        ));
      }
    }

    if (daysUntilOvulation != null && daysUntilOvulation >= 0 && daysUntilOvulation <= 2) {
      await addMessage(AppMessage(
        id: 'ovulation_${now.year}${now.month}${now.day}',
        title: daysUntilOvulation == 0 ? 'Ovulation Day' : 'Ovulation in $daysUntilOvulation Days',
        body: daysUntilOvulation == 0
            ? 'Today is your predicted ovulation day. Your fertility is at its peak.'
            : 'Ovulation is approaching in $daysUntilOvulation days. This is your fertile window.',
        category: MessageCategory.cycle,
        timestamp: now,
      ));
    }

    // Phase-based wellness tip (once per week)
    final tipId = 'tip_${currentPhase}_${now.year}_w${_weekOfYear(now)}';
    final tips = _phaseTips[currentPhase];
    if (tips != null && tips.isNotEmpty) {
      final tip = tips[now.day % tips.length];
      await addMessage(AppMessage(
        id: tipId,
        title: 'Wellness Tip · ${_capitalize(currentPhase)} Phase',
        body: tip,
        category: MessageCategory.tip,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ));
    }
  }

  int _weekOfYear(DateTime d) => ((d.difference(DateTime(d.year, 1, 1)).inDays) / 7).floor();

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static const _phaseTips = {
    'menstrual': [
      'Rest and warmth are your friends right now. A heating pad can ease cramps naturally.',
      'Iron-rich foods like spinach and lentils help replenish what you lose during your period.',
      'Gentle yoga and stretching can relieve cramps better than staying completely still.',
      'Stay hydrated — bloating is partly from fluid retention, and water helps reduce it.',
    ],
    'follicular': [
      'Your energy is rising! This is a great time to start new projects or workouts.',
      'Estrogen supports muscle recovery — strength training now yields great results.',
      'Your mood and creativity peak in this phase. Use it for brainstorming and social plans.',
      'Lighter, fresh foods like salads and smoothies align well with your rising energy.',
    ],
    'ovulatory': [
      'Your communication skills are at their best — great time for important conversations.',
      'High-intensity workouts feel easier now thanks to peak estrogen and testosterone.',
      'Your skin may glow more than usual. Celebrate it!',
      'This is your most social and confident phase — lean into it.',
    ],
    'luteal': [
      'Magnesium-rich foods (dark chocolate, nuts, seeds) can reduce PMS symptoms.',
      'Your body temperature rises slightly. Opt for cooling foods and lighter layers.',
      'Cravings are real and hormonal. Satisfy them mindfully — no guilt needed.',
      'Prioritise sleep — progesterone can make you feel more tired than usual.',
    ],
  };
}
