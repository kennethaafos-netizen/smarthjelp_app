import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ReservedTimer extends StatefulWidget {
  final String jobId;
  final DateTime reservedUntil;

  const ReservedTimer({
    super.key,
    required this.jobId,
    required this.reservedUntil,
  });

  @override
  State<ReservedTimer> createState() => _ReservedTimerState();
}

class _ReservedTimerState extends State<ReservedTimer> {
  late Timer _timer;
  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    final diff = widget.reservedUntil.difference(DateTime.now());

    if (!mounted) return;

    setState(() {
      remaining = diff;
    });

    // 🔥 AUTO EXPIRE
    if (diff.inSeconds <= 0) {
      _timer.cancel();

      // 🔥 KALL APPSTATE
      context.read<AppState>().expireReservation(widget.jobId);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (remaining.inSeconds <= 0) {
      return const Text(
        "Reservasjon utløpt",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final isUrgent = remaining.inSeconds < 60;

    return Text(
      "Reservasjon utløper om ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
      style: TextStyle(
        color: isUrgent ? Colors.red : Colors.orange,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}