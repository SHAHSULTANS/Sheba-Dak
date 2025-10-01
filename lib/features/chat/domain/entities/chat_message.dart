class ChatMessage {
  final String id;  // Unique message ID.
  final String bookingId;  // Links to BookingEntity.id.
  final String senderId;  // UserEntity.id (customer or provider).
  final String recipientId;  // UserEntity.id (opposite party).
  final String message;  // Text content.
  final DateTime timestamp;  // Sent time.

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        senderId: json['sender_id'] as String,
        recipientId: json['recipient_id'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}