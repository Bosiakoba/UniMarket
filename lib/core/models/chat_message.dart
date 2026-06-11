import 'listing_item.dart';

enum ChatMessageKind {
  text,
  saleConfirmation,
  systemText,
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

  bool get hasListing => listing != null;

  bool get isSaleConfirmation => kind == ChatMessageKind.saleConfirmation;

  bool get isSystemText => kind == ChatMessageKind.systemText;

  bool get canRespondToSale =>
      isSaleConfirmation &&
      saleId != null &&
      requiresMyResponse &&
      (confirmationStatus == null || confirmationStatus == 'pending');

  ChatMessage copyWith({
    String? confirmationStatus,
    String? timeLabel,
    bool? requiresMyResponse,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isMine: isMine,
      timeLabel: timeLabel ?? this.timeLabel,
      listing: listing,
      kind: kind,
      saleId: saleId,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
      requiresMyResponse: requiresMyResponse ?? this.requiresMyResponse,
    );
  }
}
