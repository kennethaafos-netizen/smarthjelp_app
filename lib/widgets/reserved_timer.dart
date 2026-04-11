import 'package:flutter/material.dart';

import '../models/job.dart';

class ReservedTimer extends StatelessWidget {
  final Job job;

  const ReservedTimer({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.reservedUntil == null) return const SizedBox.shrink();

    final remaining = job.reservedUntil!.difference(DateTime.now());
    final seconds = remaining.inSeconds;
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutesPart = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (safeSeconds % 60).toString().padLeft(2, '0');

    return Text(
      "Reservasjon utløper om $minutesPart:$secondsPart",
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.orange,
      ),
    );
  }
}