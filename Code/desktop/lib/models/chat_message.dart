import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool isUser;
  final String? senderName;
  final bool isRead;

  ChatMessage({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    required this.isUser,
    this.senderName,
    this.isRead = false,
  });

  // Convert to Map to send data to Firestore
  Map<String, dynamic> toMap() => toJson();

  // Create from Map when receiving data from Firestore
  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage.fromJson(map);

  // Get formatted time for display
  String getFormattedTime() {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Clone method for updating messages
  ChatMessage copyWith({
    String? senderID,
    String? senderEmail,
    String? receiverID,
    String? message,
    Timestamp? timestamp,
    bool? isUser,
    String? senderName,
    bool? isRead,
  }) {
    return ChatMessage(
      senderID: senderID ?? this.senderID,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverID: receiverID ?? this.receiverID,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isUser: isUser ?? this.isUser,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
    );
  }

  // Serialization to JSON
  Map<String, dynamic> toJson() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'isUser': isUser,
      'senderName': senderName,
      'isRead': isRead,
    };
  }

  // Deserialization from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp conversion
    final timestamp = json['timestamp'] is Timestamp 
        ? json['timestamp'] as Timestamp
        : json['timestamp'] is int 
            ? Timestamp.fromMillisecondsSinceEpoch(json['timestamp'])
            : Timestamp.now();

    return ChatMessage(
      senderID: json['senderID'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      receiverID: json['receiverID'] ?? '',
      message: json['message'] ?? '',
      timestamp: timestamp,
      isUser: json['isUser'] ?? false,
      senderName: json['senderName'],
      isRead: json['isRead'] ?? false,
    );
  }

  // Helper method to check if this message was sent by a specific user
  bool isSentByUser(String userId) => senderID == userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && senderID == other.senderID;

  @override
  int get hashCode => senderID.hashCode;
}

enum MessageType { text, image, file, audio, video, location }
enum MessageStatus { sending, sent, delivered, read, failed }
