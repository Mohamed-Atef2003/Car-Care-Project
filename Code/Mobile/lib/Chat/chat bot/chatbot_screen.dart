import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/colors.dart';
import '../../models/chat_message.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_bubble.dart';
import 'gemini_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _botId = 'CarBot';
  bool _isLoading = false;
  final GeminiService _geminiService = GeminiService();
  late SharedPreferences _prefs;
  
  // Use late initialization to avoid unnecessary memory allocation
  late List<ChatMessage> _messages;
  
  // Keep alive when navigating between screens
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _messages = [];
    _initPrefs();
    // Load user only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messagesJson = _prefs.getStringList('chat_messages') ?? [];
    setState(() {
      _messages = messagesJson.map((json) {
        final map = jsonDecode(json);
        // Convert timestamp from milliseconds to Timestamp
        map['timestamp'] = Timestamp.fromMillisecondsSinceEpoch(map['timestamp']);
        return ChatMessage.fromMap(map);
      }).toList();
    });
  }

  Future<void> _saveMessages() async {
    final messagesJson = _messages.map((msg) {
      final map = msg.toMap();
      // Convert Timestamp to milliseconds for storage
      map['timestamp'] = (map['timestamp'] as Timestamp).millisecondsSinceEpoch;
      return jsonEncode(map);
    }).toList();
    await _prefs.setStringList('chat_messages', messagesJson);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send message to Gemini API
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Get user data from UserProvider - reuse the instance
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    _messageController.clear();

    // Create user message object
    final userMessage = ChatMessage(
      senderID: currentUser.id ?? 'anonymous',
      senderEmail: currentUser.email,
      receiverID: _botId,
      message: messageText,
      timestamp: Timestamp.now(),
      isUser: true,
      senderName: '${currentUser.firstName} ${currentUser.lastName}',
    );

    // Add user message to list - avoid unnecessary setState calls
    if (mounted) {
      setState(() {
        _messages.add(userMessage);
        _isLoading = true;
      });
      await _saveMessages();
    }

    _scrollToBottom();

    try {
      // Get response from Gemini API
      final botResponse = await _geminiService.getChatResponse(messageText);
      
      if (mounted) {
        // Create bot message object
        final botMessage = ChatMessage(
          senderID: _botId,
          senderEmail: 'bot@example.com',
          receiverID: currentUser.id ?? 'anonymous',
          message: botResponse,
          timestamp: Timestamp.now(),
          isUser: false,
          senderName: "Car Care Bot",
        );

        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });
        await _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    // Optimize scrolling with microtask
    Future.microtask(() {
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
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final user = Provider.of<UserProvider>(context).user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Care Bot'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _prefs.remove('chat_messages');
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.car_repair,
                            size: 80,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome to Car Care Bot!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(red: 128, green: 128, blue: 128, alpha: 51),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'We\'re delighted you\'re here and ready to assist with everything related to your car\'s care and maintenance.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  'Start a conversation now to receive helpful tips, schedule service appointments, and get answers to all your car-related inquiries.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'Let\'s begin our journey toward a healthier, high-performing vehicle!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(red: 128, green: 128, blue: 128, alpha: 51),
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
                    decoration: InputDecoration(
                      hintText: 'Type your question about a car problem here...',
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