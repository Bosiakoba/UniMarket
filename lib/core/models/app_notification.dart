enum NotificationType {
  verification,
  listing,
  message,
  wishlist,
  sellerApplication,
  system,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.section,
    this.isRead = false,
    this.type = NotificationType.system,
    this.targetId,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final String section;
  final bool isRead;
  final NotificationType type;
  final String? targetId;
  final String? actionLabel;

  bool get hasAction => targetId != null && actionLabel != null;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      section: section,
      isRead: isRead ?? this.isRead,
      type: type,
      targetId: targetId,
      actionLabel: actionLabel,
    );
  }
}
