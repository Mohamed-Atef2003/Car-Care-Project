import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/chat_message.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_bubble.dart';
class CustomerServiceChatScreen extends StatefulWidget {
  const CustomerServiceChatScreen({super.key});

  @override
  State<CustomerServiceChatScreen> createState() => _CustomerServiceChatScreenState();
}

class _CustomerServiceChatScreenState extends State<CustomerServiceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _customerServiceId = 'CkBIAVPIwvaCy3SEBKBKMRaABQk1'; // Admin user ID from Firebase

  @override
  void initState() {
    super.initState();
    // Make sure user data is loaded when the screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  // Get user data from UserProvider
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final currentUser = userProvider.user;
  
  // Check if user exists
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login first')),
    );
    return;
  }

  final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return;

  final message = _messageController.text.trim();
  _messageController.clear();

  // Create chat room ID using ChatService
  final chatRoomId = ChatService().createChatId(
    currentUser.id ?? firebaseUser.uid,
    _customerServiceId,
  );

  // Create message object
  final newMessage = ChatMessage(
    senderID: currentUser.id ?? firebaseUser.uid,
    senderEmail: currentUser.email,
    receiverID: _customerServiceId,
    message: message,
    timestamp: Timestamp.now(),
    isUser: true,
    senderName: '${currentUser.firstName} ${currentUser.lastName}',
  );

  try {
    // Add the message to the 'messages' subcollection
    await FirebaseFirestore.instance
        .collection('Chat')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update or create the main chat document with additional fields:
    // participants, lastMessage, and lastTimestamp
    await FirebaseFirestore.instance
        .collection('Chat')
        .doc(chatRoomId)
        .set({
          'participants': [
            currentUser.id ?? firebaseUser.uid, // current user ID
            _customerServiceId,                 //  customer service ID
          ],
          'customerServiceId': _customerServiceId,
          'customerName': '${currentUser.firstName} ${currentUser.lastName}',
          'customerId': currentUser.id ?? firebaseUser.uid,
          'lastMessage': message,
          'lastTimestamp': Timestamp.now(),
        }, SetOptions(merge: true));

    // Scroll to bottom of the chat view
    _scrollToBottom();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }
}

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const Scaffold(body: Center(child: Text('Please login')));

    final user = Provider.of<UserProvider>(context).user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Create the chat room ID using the same method as in _sendMessage
    final chatRoomId = ChatService().createChatId(
      user.id ?? firebaseUser.uid,
      _customerServiceId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Service'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Chat')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading conversation'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ChatMessage.fromMap(data);
                }).toList() ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintTextDirection: TextDirection.ltr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 