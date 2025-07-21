import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _chatCollection = 'Chat';




////////////////////////////////////////////////////////////

// get current user info
final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;



// get all messages from the chat room


// Stream<List<Map<String, dynamic>>> getChatMessages() {
//   return FirebaseFirestore.instance("Chat").snapshots().map((snapshot){
//     return snapshot.docs.map((doc){
//       final user = doc.data();
//       return user;
//     }).toList();
//   });
// }


//////////////////////////////////////////////////////////////

  // Create a unique chat ID from two user IDs
  String createChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderName,
    required String senderId,
    required String senderEmail,
    required String receiverId,
  }) async {
    final timestamp = Timestamp.now();
    
    // Create message object
    final newMessage = ChatMessage(
      senderID: senderId,
      senderEmail: senderEmail,
      receiverID: receiverId,
      message: message,
      timestamp: timestamp,
      isUser: false,
      senderName: senderName,
    );

    // Add message to Firestore
    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update last message info in chat room
    await _firestore.collection(_chatCollection).doc(chatId).set({
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  // Get conversation between users
  Stream<List<ChatMessage>> getConversation(String userId1, String userId2) {
    final chatId = createChatId(userId1, userId2);
    return _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  // Get list of chats without any filtering
  Stream<List<Map<String, dynamic>>> getCustomerChats(String supportAgentId) {
  return _firestore
    .collection(_chatCollection)
    .where('participants', arrayContains: supportAgentId) // Filter chats for current user
    .snapshots()
    .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chats = [];
      
      for (var doc in snapshot.docs) {
        try {
          final chatId = doc.id;
          final data = doc.data();
          
          // Search for customer name from various possible fields
          String customerName = data['customerName'] ?? data['customer_name'] ?? '';
          
          // If customer name not found, use service ID if available
          if (customerName.isEmpty) {
            customerName = data['customerServiceID'] ?? '';
          }
          
          // Prepare chat data
          final chatInfo = {
            'id': chatId,
            'name': customerName,
            'lastMessage': data['lastMessage'] ?? '',
            'time': data['lastTimestamp'] != null ? _formatTimestamp(data['lastTimestamp']) : '',
            'status': 'online',
            'unread': 0,
            'chatId': chatId,
          };
          
          chats.add(chatInfo);
        } catch (e) {
          print("Error processing chat: $e");
        }
      }
      
      return chats;
    });
}


  // Format timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  // Get customer details using customer ID
  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    try {
      // Try to find customer data in the chat document
      final chatDoc = await _firestore
          .collection(_chatCollection)
          .doc(customerId)
          .get();
      
      if (chatDoc.exists && chatDoc.data() != null) {
        final data = chatDoc.data()!;
        return {
          'customerId': customerId,
          'customerName': data['customerName'] ?? '',
          'customerServiceId': data['customerServiceID'] ?? '',
          'lastMessage': data['lastMessage'] ?? '',
          'lastTimestamp': data['lastTimestamp'],
          'participants': data['participants'] ?? [],
        };
      }
      
      // If customer not found, return empty information
      return {
        'customerId': customerId,
        'customerName': '',
        'customerServiceId': '',
        'lastMessage': '',
        'lastTimestamp': null,
        'participants': [],
      };
    } catch (e) {
      print("Error getting customer data: $e");
      rethrow;
    }
  }
} 