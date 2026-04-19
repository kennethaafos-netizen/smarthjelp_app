// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const _primary = Color(0xFF2356E8);
  static const _accent = Color(0xFF18B7A6);
  static const _bg = Color(0xFFF4F7FC);
  static const _text = Color(0xFF0F1E3A);
  static const _muted = Color(0xFF6E7A90);
  static const _amber = Color(0xFFF5B301);

  int _rating = 5;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentCtrl = TextEditingController();

  static const List<_RatingTag> _tags = [
    _RatingTag('Punktlig', Icons.schedule_rounded),
    _RatingTag('Hyggelig', Icons.emoji_emotions_outlined),
    _RatingTag('Hjelpsom', Icons.volunteer_activism_outlined),
    _RatingTag('Ryddig', Icons.cleaning_services_outlined),
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Dårlig';
      case 2:
        return 'Under forventning';
      case 3:
        return 'Helt greit';
      case 4:
        return 'Bra';
      case 5:
      default:
        return 'Fantastisk!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 18),
              _starsRow(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(_rating),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hva gikk bra?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              _tagsWrap(),
              const SizedBox(height: 20),
              const Text(
                'Kommentar (valgfritt)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _commentField(),
              const SizedBox(height: 22),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _accent],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gi rating',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hvordan var oppdraget?',
                style: TextStyle(
                  fontSize: 13.5,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        InkResponse(
          onTap: () => Navigator.pop(context),
          radius: 22,
          child: const Icon(
            Icons.close_rounded,
            color: _muted,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _starsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (i) {
          final idx = i + 1;
          final isActive = idx <= _rating;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _rating = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(4),
              child: Icon(
                isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isActive ? _amber : _muted.withOpacity(0.5),
                size: 40,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tagsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((t) {
        final selected = _selectedTags.contains(t.label);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (selected) {
              _selectedTags.remove(t.label);
            } else {
              _selectedTags.add(t.label);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _primary.withOpacity(0.10) : _bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _primary : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t.icon,
                  size: 16,
                  color: selected ? _primary : _muted,
                ),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? _primary : _text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _commentField() {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _commentCtrl,
        maxLines: 3,
        minLines: 3,
        maxLength: 240,
        style: const TextStyle(fontSize: 14.5, color: _text),
        decoration: const InputDecoration(
          hintText: 'Skriv en kort tilbakemelding...',
          hintStyle: TextStyle(color: _muted, fontSize: 14),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: _muted,
            ),
            child: const Text(
              'Avbryt',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pop(context, _rating.toDouble()),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _accent],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Send rating',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingTag {
  final String label;
  final IconData icon;
  const _RatingTag(this.label, this.icon);
}
