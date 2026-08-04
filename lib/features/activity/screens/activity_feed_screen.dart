// lib/features/activity/screens/activity_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/lists/error_state.dart';
import '../../../shared/widgets/lists/list_row_card.dart';
import '../models/feed_entry.dart';
import '../providers/activity_feed_providers.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  IconData _sourceIcon(ActivitySource source) => switch (source) {
    ActivitySource.project => Icons.folder_outlined,
    ActivitySource.ticket => Icons.confirmation_number_outlined,
    ActivitySource.employee => Icons.person_outline,
  };

  String _route(FeedEntry f) => switch (f.source) {
    ActivitySource.project => '/projects/${f.sourceId}',
    ActivitySource.ticket => '/tickets/${f.sourceId}',
    ActivitySource.employee => '/employees/${f.sourceId}',
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
    final feedAsync = ref.watch(activityFeedProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A combined log of recent changes across your projects, tickets, and team.',
            style: TextStyle(
              color: AppColors.slate,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorState(
                message: 'Failed to load activity: $err',
                onRetry: () => ref.invalidate(activityFeedProvider),
              ),
              data: (feed) {
                if (feed.isEmpty) {
                  return const Center(
                    child: Text(
                      'No activity yet.',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: feed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final f = feed[index];
                    return ListRowCard(
                      icon: _sourceIcon(f.source),
                      title: '${f.entry.actorName} ${f.entry.detail}',
                      subtitle:
                          '${f.sourceLabel} · ${_relativeTime(f.entry.timestamp)}',
                      onTap: () => context.go(_route(f)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
