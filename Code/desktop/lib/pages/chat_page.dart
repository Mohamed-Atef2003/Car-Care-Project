import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Definition of support ticket statuses, priorities, and departments
enum TicketStatus { open, inProgress, pending, resolved, closed }
enum TicketPriority { low, medium, high, urgent }
enum SupportDepartment { general, technical, billing, shipping, returns }

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<AnimationController> _typingAnimControllers;

  // Firebase & Chat Service
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  StreamSubscription? _messagesSubscription;
  
  // State variables
  String _selectedCustomerId = '';
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  List<ChatMessage> messages = [];
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _initFirebase();
    
    // Initialize typing animation controllers
    _typingAnimControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat()
    );
  }

  Future<void> _initFirebase() async {
    try {
      _currentUser = _auth.currentUser;
      
      if (_currentUser == null) {
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first to access customer service'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("User is logged in: ${_currentUser?.uid}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      setState(() => _isLoading = false);
    }
  }


  void _loadMessages() {
    // Cancel any existing subscription
    _messagesSubscription?.cancel();
    
    if (_currentUser == null || _selectedCustomerId.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Search for chat ID from the customer list
    final selectedCustomer = _getSelectedCustomer();
    final chatId = selectedCustomer['chatId'] as String? ?? 
                  _chatService.createChatId(_currentUser!.uid, _selectedCustomerId);
    
    print("Loading messages for chat ID: $chatId");
    
    // Use Firestore directly to access messages
    _messagesSubscription = _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              final messagesList = snapshot.docs
                  .map((doc) => ChatMessage.fromMap(doc.data()))
                  .toList();
              
              setState(() {
                messages = messagesList;
                _isLoading = false;
                
                // Update unread message count and read status
                _updateUnreadCount(_selectedCustomerId, 0);
                _markMessagesAsRead(chatId);
              });
              
              // Scroll to bottom after loading messages
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          onError: (error) {
            debugPrint('Error loading messages: $error');
            if (mounted) setState(() => _isLoading = false);
          }
        );
  }

  // Update messages to be marked as read
  Future<void> _markMessagesAsRead(String chatId) async {
    if (_currentUser == null) return;
    
    try {
      // Get unread messages sent to the current user
      final snapshot = await _firestore
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverID', isEqualTo: _currentUser!.uid)
          .get();
      
      // Update each message to be marked as read
      for (final doc in snapshot.docs) {
        await _firestore
            .collection('Chat')
            .doc(chatId)
            .collection('messages')
            .doc(doc.id)
            .update({'isRead': true});
      }
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  void _updateUnreadCount(String customerId, int count) {
    setState(() {
      for (int i = 0; i < _customers.length; i++) {
        if (_customers[i]['id'] == customerId) {
          _customers[i]['unread'] = count;
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (final controller in _typingAnimControllers) {
      controller.dispose();
    }
    _messagesSubscription?.cancel();
    super.dispose();
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Update selected customer and load their messages
  void _selectCustomer(String customerId) {
    if (_selectedCustomerId != customerId) {
      setState(() => _selectedCustomerId = customerId);
      _loadMessages();
    }
  }

  // Send message to the selected customer
  void _sendMessage() async {
    if (_messageController.text.isEmpty || _currentUser == null || _selectedCustomerId.isEmpty) {
      return;
    }
    
    final message = _messageController.text.trim();
    _messageController.clear();
    
    try {
      // Search for chat ID stored in the customer list
      final selectedCustomer = _getSelectedCustomer();
      final chatId = selectedCustomer['chatId'] as String? ?? 
                   _chatService.createChatId(_currentUser!.uid, _selectedCustomerId);
      
      // Create message object
      final newMessage = ChatMessage(
        senderID: _currentUser!.uid,
        senderEmail: _currentUser!.email ?? '',
        receiverID: _selectedCustomerId,
        message: message,
        timestamp: Timestamp.now(),
        isUser: false,
        senderName: _currentUser?.displayName ?? 'Customer Service',
      );
      
      // Add message directly to Firestore
      await _firestore
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());
      
      // Update last message information in the chat room
      await _firestore.collection('Chat').doc(chatId).set({
        'lastMessage': message,
        'lastTimestamp': Timestamp.now(),
        'participants': [_currentUser!.uid, _selectedCustomerId],
      }, SetOptions(merge: true));
      
      // Scroll to bottom after sending
      if (mounted) _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter the customer list based on search keyword
  List<Map<String, dynamic>> _getFilteredCustomers() {
    if (!_isSearching || _searchQuery.isEmpty) {
      return _customers;
    }
    
    return _customers.where((customer) {
      final name = customer['name']?.toString() ?? '';
      final lastMessage = customer['lastMessage']?.toString() ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

 

  // Get selected customer information
  Map<String, dynamic> _getSelectedCustomer() {
    return _customers.firstWhere(
      (customer) => customer['id'] == _selectedCustomerId,
      orElse: () => {'id': '', 'name': 'Unknown', 'status': 'offline'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/image/logo.png',
              height: 36,
              errorBuilder: (context, error, stackTrace) => 
                Icon(Icons.support_agent, size: 30, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Customer Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      
      body: SafeArea(
        child: _isLoading && _customers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Row(
          children: [
            // Customer list - always appears on desktop and tablet
            if (isTablet || isDesktop)
              _buildCustomersList(),
            
            // Chat area
            Expanded(
              child: _selectedCustomerId.isEmpty
                ? _buildEmptyChat()
                : _buildChatArea(),
            ),
          ],
        ),
      ),
    );
  }

  // Interface when no customer is selected
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a customer from the list to start a conversation',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.gray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build customer list
  Widget _buildCustomersList() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // List header with search box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.background),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _currentUser != null
                          ? _chatService.getCustomerChats(_currentUser!.uid)
                          : Stream.value([]),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData ? snapshot.data!.length : _customers.length;
                        return Text(
                          'Customer List${count == 0 ? " (Empty)" : " ($count)"}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    // Refresh button is hidden because we now use StreamBuilder
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a customer...',
                    prefixIcon: Icon(Icons.search, color: AppColors.gray),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          
          // Customer list with StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _currentUser != null
                  ? _chatService.getCustomerChats(_currentUser!.uid)
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading data: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  _customers = snapshot.data!;
                  final filteredCustomers = _getFilteredCustomers();
                  
                  if (filteredCustomers.isEmpty) {
                    return _buildEmptyCustomersList();
                  }
                  
                  return ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) => _buildCustomerListItem(filteredCustomers[index]),
                  );
                }
                
                return _buildEmptyCustomersList();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build customer list item
  Widget _buildCustomerListItem(Map<String, dynamic> customer) {
    final isSelected = customer['id'] == _selectedCustomerId;
    final customerName = customer['name']?.toString() ?? 'Unknown';
    
    return Material(
      color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: () => _selectCustomer(customer['id'] as String),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.background),
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Customer image with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      customerName.isNotEmpty ? customerName[0] : "?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(width: 12),
              // Customer information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: TextStyle(
                              fontWeight: (customer['unread'] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          customer['time'] ?? '',
                          style: TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer['lastMessage'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                              fontWeight: (customer['unread'] ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((customer['unread'] ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              customer['unread'].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty customer list state
  Widget _buildEmptyCustomersList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isSearching ? 'No search results found' : 'No conversations yet',
            style: TextStyle(color: AppColors.gray),
          ),
          if (!_isSearching && _currentUser != null) ...[
            const SizedBox(height: 10),
          ]
        ],
      ),
    );
  }

  // Build chat area
  Widget _buildChatArea() {
    final selectedCustomer = _getSelectedCustomer();
    final customerName = selectedCustomer['name']?.toString() ?? 'Unknown';
    final firstLetter = customerName.isNotEmpty ? customerName[0] : '?';
    
    return Column(
      children: [
        // Chat header with customer information
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Add delete conversation button (moved to the right)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                tooltip: 'End and delete conversation',
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
        
        // Messages area
        Expanded(
          child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(color: AppColors.gray),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
                ),
        ),
        
        // Message input area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.more_horiz, color: AppColors.gray),
                onPressed: () {
                  _showQuickResponses(context);
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: AppColors.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isSentByMe = message.senderID == _currentUser?.uid;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                message.senderName?.isNotEmpty == true ? message.senderName![0] : "?",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isSentByMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isSentByMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSentByMe && message.senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        message.getFormattedTime(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSentByMe
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.gray,
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSentByMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showQuickResponses(BuildContext context) {
    final List<Map<String, String>> quickResponses = [
      {
        'title': 'Welcome',
        'message': 'مرحباً بك في خدمة العملاء! كيف يمكنني مساعدتك اليوم؟'
      },
      {
        'title': 'Order Status',
        'message': 'سنقوم بالتحقق من حالة طلبك فوراً ونعود إليك خلال دقائق. هل يمكنك تزويدنا برقم الطلب؟'
      },
      {
        'title': 'Technical Support',
        'message': 'لمساعدتك بشكل أفضل، هل يمكنك وصف المشكلة التقنية التي تواجهها بالتفصيل؟'
      },
      {
        'title': 'Shipping Status',
        'message': 'سيتم توصيل طلبك خلال الموعد المحدد. يمكنك تتبع الشحنة من خلال رابط التتبع المرسل إلى بريدك الإلكتروني.'
      },
      {
        'title': 'Payment Issue',
        'message': 'نأسف للإزعاج بخصوص مشكلة الدفع. سنقوم بالتحقق من ذلك والعودة إليك في أقرب وقت ممكن.'
      },
      {
        'title': 'Product Return',
        'message': 'يمكنك إرجاع المنتج خلال 14 يوماً من الاستلام. يرجى التأكد من أن المنتج في حالته الأصلية مع جميع الملحقات.'
      },
      {
        'title': 'Thank You',
        'message': 'شكراً لتواصلك معنا. يسعدنا دائماً خدمتك! هل هناك أي شيء آخر يمكنني مساعدتك به؟'
      },
      {
        'title': 'Closing',
        'message': 'سعدنا بخدمتك اليوم. إذا كانت لديك أي استفسارات أخرى، فلا تتردد في التواصل معنا مرة أخرى. يومك سعيد!'
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.quickreply, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Responses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: quickResponses.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final response = quickResponses[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          response['title']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          response['message']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                        onTap: () {
                          _messageController.text = response['message']!;
                          Navigator.pop(context);
                          
                          // Set cursor at the end of text and focus the field
                          _messageController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _messageController.text.length),
                          );
                          FocusScope.of(context).requestFocus(FocusNode());
                          Future.delayed(const Duration(milliseconds: 100), () {
                            FocusScope.of(context).requestFocus(FocusNode());
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.send, size: 18),
                          color: AppColors.primary,
                          onPressed: () {
                            _messageController.text = response['message']!;
                            Navigator.pop(context);
                            _sendMessage();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'Are you sure you want to delete this conversation? This action cannot be undone and all messages will be permanently removed.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.gray)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteConversation();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete conversation from Firebase
  Future<void> _deleteConversation() async {
    if (_currentUser == null || _selectedCustomerId.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      // Search for conversation ID from customer list
      final selectedCustomer = _getSelectedCustomer();
      final chatId = selectedCustomer['chatId'] as String? ?? 
                    _chatService.createChatId(_currentUser!.uid, _selectedCustomerId);
      
      // Delete all messages in the conversation first
      final messagesSnapshot = await _firestore
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      
      // Add delete operations for all messages to the batch
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Add delete operation for the conversation document itself to the batch
      batch.delete(_firestore.collection('Chat').doc(chatId));
      
      // Execute all delete operations in a single batch
      await batch.commit();
      
      // Update app state
      setState(() {
        messages = [];
        _selectedCustomerId = '';
        
        // Remove customer from local list
        _customers.removeWhere((customer) => customer['id'] == _selectedCustomerId);
        
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      print('Error deleting conversation: $e');
    }
  }

}
