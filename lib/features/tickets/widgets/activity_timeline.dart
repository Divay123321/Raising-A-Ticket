import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_entry.dart';
import '../providers/ticket_providers.dart';

class ActivityTimeline extends ConsumerWidget {
  final String ticketId;
  const ActivityTimeline({super.key, required this.ticketId});

  IconData _iconFor(ActivityType type) => switch (type) {
    ActivityType.created => Icons.add_circle_outline,
    ActivityType.edited => Icons.edit_outlined,
    ActivityType.statusChanged => Icons.sync_alt,
    ActivityType.assigned => Icons.person_add_alt_outlined,
  };

  Color _colorFor(ActivityType type) => switch (type) {
    ActivityType.created => Colors.green,
    ActivityType.edited => Colors.blueGrey,
    ActivityType.statusChanged => Colors.orange,
    ActivityType.assigned => Colors.blue,
  };

  String _relativeTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ticketActivityProvider(ticketId));

    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Failed to load activity: $err'),
      data: (entries) {
        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No activity yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return Column(
          children: entries.asMap().entries.map((indexed) {
            final index = indexed.key;
            final e = indexed.value;
            final isLast = index == entries.length - 1;
            final color = _colorFor(e.type);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconFor(e.type), size: 16, color: color),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: e.actorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' ${e.detail}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _relativeTime(e.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
