import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../../models/chat_message.dart';

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

  // إنشاء معرف فريد للمحادثة من معرفين للمستخدمين
  String createChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // إرسال رسالة
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderName,
    required String senderId,
    required String senderEmail,
    required String receiverId,
  }) async {
    final timestamp = Timestamp.now();
    
    // إنشاء كائن الرسالة
    final newMessage = ChatMessage(
      senderID: senderId,
      senderEmail: senderEmail,
      receiverID: receiverId,
      message: message,
      timestamp: timestamp,
      isUser: false,
      senderName: senderName,
    );

    // إضافة الرسالة إلى Firestore
    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection('messages')
        .add(newMessage.toMap());

    // تحديث معلومات آخر رسالة في غرفة الدردشة
    await _firestore.collection(_chatCollection).doc(chatId).set({
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  // الحصول على محادثة بين مستخدمين
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

  // الحصول على قائمة المحادثات بدون أي فلترة
  Stream<List<Map<String, dynamic>>> getCustomerChats(String supportAgentId) {
    return _firestore
      .collection(_chatCollection)
      .snapshots()
      .asyncMap((snapshot) async {
        List<Map<String, dynamic>> chats = [];
        
        for (var doc in snapshot.docs) {
          try {
            final chatId = doc.id;
            final data = doc.data();
            
            // إعداد بيانات المحادثة مباشرة
            final chatInfo = {
              'id': chatId,
              'name': data['customer_name'] ?? 'عميل جديد',
              'lastMessage': data['lastMessage'] ?? 'محادثة جديدة',
              'time': data['lastTimestamp'] != null ? _formatTimestamp(data['lastTimestamp']) : '',
              'status': 'online',
              'unread': 0,
              'chatId': chatId,
            };
            
            chats.add(chatInfo);
          } catch (e) {
            print("خطأ في معالجة المحادثة: $e");
          }
        }
        
        return chats;
      });
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      return 'أمس';
    } else {
      return '${date.day}/${date.month}';
    }
  }
} 