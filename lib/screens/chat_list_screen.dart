import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.chatJobs;

    return Scaffold(
      appBar: AppBar(title: const Text('Meldinger')),
      body: jobs.isEmpty
          ? const Center(child: Text('Ingen chatter ennå'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];
                final messages = appState.getMessagesForJob(job.id);
                final lastText =
                    messages.isNotEmpty ? messages.last.text : 'Ingen meldinger';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(job.title),
                    subtitle: Text(
                      lastText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              },
            ),
    );
  }
}