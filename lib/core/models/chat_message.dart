import 'listing_item.dart';

enum ChatMessageKind {
  text,
  saleConfirmation,
  systemText,
}

/// Delivery status for optimistic messages.
enum ChatMessageSendStatus {
  /// Message delivered by the server (or loaded from server).
  sent,

  /// Message added optimistically – network request in flight.
  sending,

  /// Network request failed.
  failed,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.timeLabel,
    this.listing,
    this.kind = ChatMessageKind.text,
    this.saleId,
    this.confirmationStatus,
    this.requiresMyResponse = false,
    this.sendStatus = ChatMessageSendStatus.sent,
    this.isEdited = false,
    this.isDeletedForMe = false,
    this.isDeletedForAll = false,
    this.sentAt,
  });

  final String id;
  final String text;
  final bool isMine;
  final String timeLabel;
  final ListingItem? listing;
  final ChatMessageKind kind;
  final String? saleId;
  final String? confirmationStatus;
  final bool requiresMyResponse;
  final ChatMessageSendStatus sendStatus;
  final bool isEdited;
  final bool isDeletedForMe;
  final bool isDeletedForAll;
  final DateTime? sentAt;

  bool get hasListing => listing != null;

  bool get isSaleConfirmation => kind == ChatMessageKind.saleConfirmation;

  bool get isSystemText => kind == ChatMessageKind.systemText;

  bool get isSending => sendStatus == ChatMessageSendStatus.sending;

  bool get isFailed => sendStatus == ChatMessageSendStatus.failed;

  bool get canRespondToSale =>
      isSaleConfirmation &&
      saleId != null &&
      requiresMyResponse &&
      (confirmationStatus == null || confirmationStatus == 'pending');

  ChatMessage copyWith({
    String? text,
    String? confirmationStatus,
    String? timeLabel,
    bool? requiresMyResponse,
    ChatMessageSendStatus? sendStatus,
    bool? isEdited,
    bool? isDeletedForMe,
    bool? isDeletedForAll,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isMine: isMine,
      timeLabel: timeLabel ?? this.timeLabel,
      listing: listing,
      kind: kind,
      saleId: saleId,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
      requiresMyResponse: requiresMyResponse ?? this.requiresMyResponse,
      sendStatus: sendStatus ?? this.sendStatus,
      isEdited: isEdited ?? this.isEdited,
      isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
      isDeletedForAll: isDeletedForAll ?? this.isDeletedForAll,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
