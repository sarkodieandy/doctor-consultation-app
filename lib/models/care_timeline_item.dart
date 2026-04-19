class CareTimelineItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<String> contextTags;
  final String statusLabel;
  final DateTime timestamp;
  final String ctaLabel;
  final String routeName;
  final Object? arguments;

  const CareTimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl = '',
    this.contextTags = const [],
    required this.statusLabel,
    required this.timestamp,
    required this.ctaLabel,
    required this.routeName,
    this.arguments,
  });
}
