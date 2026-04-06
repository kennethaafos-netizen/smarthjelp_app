// FULL FILE – chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import 'job_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final Job job;

  const ChatScreen({super.key, required this.job});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final currentJob =
        appState.jobs.firstWhere((j) => j.id == widget.job.id);

    final messages = appState.getMessagesForJob(currentJob.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: currentJob),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                if (messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "💬 Avtal pris, tidspunkt og detaljer her",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isMe = m.senderId == appState.currentUser.id;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Skriv melding...",
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  appState.sendMessage(
                    currentJob.id,
                    _controller.text,
                  );
                  _controller.clear();
                },
              ),
            ],
          ),

          _actionBar(appState, currentJob),
        ],
      ),
    );
  }

  Widget _actionBar(AppState appState, Job job) {
    if (job.status == JobStatus.open) {
      return _btn("Ta oppdrag", Colors.blue, () {
        appState.reserveJob(job.id);
      });
    }

    if (job.status == JobStatus.reserved) {
      return Row(
        children: [
          Expanded(
            child: _btn("Avbryt", Colors.grey, () {
              appState.releaseJob(job.id);
            }),
          ),
          Expanded(
            child: _btn("Start jobb", Colors.green, () {
              appState.confirmJob(job.id);
            }),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}