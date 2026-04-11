import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/job.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.chatJobs;

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: jobs.map((job) => _chatItem(context, job)).toList(),
      ),
    );
  }

  Widget _chatItem(BuildContext context, Job job) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(job.title.substring(0, 1)),
        ),

        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text(job.locationName),

        trailing: const Icon(Icons.chevron_right),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(job: job),
            ),
          );
        },
      ),
    );
  }
}