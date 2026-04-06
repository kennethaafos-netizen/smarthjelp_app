import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Gi rating"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Hvordan var oppdraget?"),
          const SizedBox(height: 16),
          Slider(
            value: rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: rating.toString(),
            onChanged: (v) => setState(() => rating = v),
          ),
          Text("⭐ ${rating.toStringAsFixed(1)}"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Avbryt"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, rating),
          child: const Text("Send"),
        ),
      ],
    );
  }
}