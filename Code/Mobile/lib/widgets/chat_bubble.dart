import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName!,
                  style: TextStyle(
                    color: message.isUser ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(message.timestamp.toDate()),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }
} 