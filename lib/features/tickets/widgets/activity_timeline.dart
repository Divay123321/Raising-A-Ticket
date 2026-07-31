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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(ticketActivityProvider(ticketId));

    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Failed to load activity: $err'),
      data: (entries) {
        if (entries.isEmpty) {
          return const Text('No activity yet.', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(e.type), size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(text: e.actorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: ' ${e.detail}'),
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