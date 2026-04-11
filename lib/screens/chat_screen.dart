import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/job.dart';
import '../providers/app_state.dart';

class ChatScreen extends StatefulWidget {
  final Job job;

  const ChatScreen({super.key, required this.job});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  ChatMessage? _replyTo;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final messages = appState.getMessagesForJob(widget.job.id);
    final currentUser = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[messages.length - 1 - i];
                final isMe = msg.senderId == currentUser.id;
                final sender =
                    appState.getUserById(msg.senderId)?.firstName ?? "Bruker";

                return GestureDetector(
                  onLongPress: () {
                    setState(() => _replyTo = msg);
                  },
                  onTap: () {
                    appState.toggleReaction(msg.id, "❤️");
                  },
                  child: _buildBubble(msg, isMe, sender),
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Svarer på: ${_replyTo!.text}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _replyTo = null),
                  )
                ],
              ),
            ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe, String name) {
    final time = DateFormat.Hm().format(msg.createdAt);
    final isSystem = msg.senderId == 'system';

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              "$name • $time",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF2356E8) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.replyToText != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.replyToText!,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (msg.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      msg.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (msg.text.isNotEmpty)
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                if (msg.reaction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(msg.reaction!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: "Skriv melding...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                context.read<AppState>().sendMessage(
                      widget.job.id,
                      _ctrl.text,
                      replyTo: _replyTo,
                    );
                _ctrl.clear();
                setState(() => _replyTo = null);
              },
            )
          ],
        ),
      ),
    );
  }
}