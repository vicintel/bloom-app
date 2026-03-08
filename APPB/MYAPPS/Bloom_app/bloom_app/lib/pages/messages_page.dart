import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/message_store.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<MessageStore>(
            builder: (context, store, _) {
              if (store.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: store.markAllRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<MessageStore>(
        builder: (context, store, _) {
          final msgs = store.messages;

          if (msgs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                  const SizedBox(height: 6),
                  Text('Cycle alerts and tips will appear here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          )),
                ],
              ),
            );
          }

          // Group messages by date
          final grouped = <String, List<AppMessage>>{};
          for (final m in msgs) {
            final label = _dateLabel(m.timestamp);
            grouped.putIfAbsent(label, () => []).add(m);
          }

          final sections = grouped.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sections.fold<int>(0, (sum, e) => sum + 1 + e.value.length),
            itemBuilder: (context, idx) {
              int offset = 0;
              for (final section in sections) {
                if (idx == offset) {
                  // Section header
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Text(
                      section.key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            letterSpacing: 0.5,
                          ),
                    ),
                  );
                }
                final itemIndex = idx - offset - 1;
                if (itemIndex >= 0 && itemIndex < section.value.length) {
                  return _MessageTile(msg: section.value[itemIndex]);
                }
                offset += 1 + section.value.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(dt);
  }
}

class _MessageTile extends StatelessWidget {
  final AppMessage msg;
  const _MessageTile({required this.msg});

  @override
  Widget build(BuildContext context) {
    final store = context.read<MessageStore>();
    final cs = Theme.of(context).colorScheme;
    final color = msg.categoryColor(context);
    final unread = !msg.isRead;

    return Dismissible(
      key: ValueKey(msg.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) => store.deleteMessage(msg.id),
      child: InkWell(
        onTap: () {
          if (unread) store.markRead(msg.id);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: unread
                ? cs.primaryContainer.withOpacity(0.35)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? cs.primary.withOpacity(0.25) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(msg.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              msg.categoryLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Unread dot
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.bold : FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeLabel(msg.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(dt);
  }
}
