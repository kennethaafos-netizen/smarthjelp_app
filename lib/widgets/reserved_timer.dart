import 'dart:async';
import 'package:flutter/material.dart';
import '../models/job.dart';

class ReservedTimer extends StatefulWidget {
  final Job job;

  const ReservedTimer({super.key, required this.job});

  @override
  State<ReservedTimer> createState() => _ReservedTimerState();
}

class _ReservedTimerState extends State<ReservedTimer> {
  late Timer _timer;
  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    final until = widget.job.reservedUntil;

    if (until == null) return;

    final diff = until.difference(DateTime.now());

    if (!mounted) return;

    setState(() {
      remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = remaining.inMinutes;
    final sec = remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Reservert $min:${sec.toString().padLeft(2, '0')}",
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}