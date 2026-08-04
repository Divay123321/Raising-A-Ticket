// lib/features/activity/models/feed_entry.dart
import '../../tickets/models/activity_entry.dart';

enum ActivitySource { project, ticket, employee }

class FeedEntry {
  final ActivityEntry entry;
  final ActivitySource source;
  final String sourceId; // the project/ticket/employee this entry belongs to
  final String sourceLabel; // display name, e.g. project name or ticket title

  const FeedEntry({
    required this.entry,
    required this.source,
    required this.sourceId,
    required this.sourceLabel,
  });
}