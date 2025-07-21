import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final bool isUser;
  final Timestamp timestamp;
  final String? senderName;

  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;



  ChatMessage({
    required this.isUser,
    required this.timestamp,
    this.senderName,
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
  });

  // convert to a map
Map<String, dynamic> toMap() {
  return {
    'senderID' : senderID,
    'senderEmail' : senderEmail,
    'receiverID' : receiverID,
    'message' : message,
    'timestamp' : timestamp,
    'isUser' : isUser,
    'senderName' : senderName,
  };
 }

  // Create from a map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderID: map['senderID'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isUser: map['isUser'] ?? false,
      senderName: map['senderName'],
    );
  }
}

// from map








