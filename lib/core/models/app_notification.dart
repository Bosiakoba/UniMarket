class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.section,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final String section;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      section: section,
      isRead: isRead ?? this.isRead,
    );
  }
}
