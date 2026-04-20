// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../screens/image_viewer_screen.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onTake;
  final String distanceText;
  final bool compact;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onTake,
    required this.distanceText,
    this.compact = false,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  // Lokal UI-state. Favoritter er bevisst IKKE lagret i AppState ennå.
  bool _favorite = false;

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _textPrimary = Color(0xFF172033);
  static const Color _textMuted = Color(0xFF6E7A90);

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    final owner = context.read<AppState>().getUserById(job.createdByUserId);
    final currentUser = context.watch<AppState>().currentUser;
    final images = context.watch<AppState>().getImages(job.id);

    final previewUrl = images.isNotEmpty
        ? images.first
        : (job.imageUrl != null && job.imageUrl!.isNotEmpty
            ? job.imageUrl
            : null);

    final isOwner = job.createdByUserId == currentUser.id;
    final isWorker = job.acceptedByUserId == currentUser.id;

    final isNew =
        DateTime.now().difference(job.createdAt) < const Duration(hours: 24);

    final double radius = widget.compact ? 20 : 22;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.compact ? 0 : 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // -------- HEADER (IMAGE ELLER PASTELL) + BADGES --------
              _header(job, previewUrl, images, radius, isNew),

              // -------- BODY --------
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  widget.compact ? 14 : 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: widget.compact ? 15 : 17,
                              color: _textPrimary,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusBadge(job, isOwner, isWorker),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.description,
                      maxLines: widget.compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _chip(job.category, icon: null, filled: true),
                        const SizedBox(width: 8),
                        _chip(
                          _timeChipLabel(job.createdAt),
                          icon: Icons.schedule_rounded,
                          filled: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.distanceText,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 14),
                      Container(height: 1, color: const Color(0xFFEEF1F7)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ownerStrip(
                            owner?.firstName,
                            owner?.rating,
                            owner?.ratingCount,
                          ),
                          const Spacer(),
                          _ctaButton(isOwner, isWorker),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- HEADER -------------------

  Widget _header(
    Job job,
    String? previewUrl,
    List<String> images,
    double radius,
    bool isNew,
  ) {
    return Stack(
      children: [
        if (previewUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius),
            ),
            child: GestureDetector(
              onTap: () {
                final gallery = images.isNotEmpty ? images : [previewUrl];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewerScreen(
                      imageUrls: gallery,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: previewUrl,
                child: Image.network(
                  previewUrl,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _pastelHeader(job.category, radius),
                ),
              ),
            ),
          )
        else
          _pastelHeader(job.category, radius),

        // Subtil bunngradient for bedre overlay-lesbarhet
        if (previewUrl != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 70,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // NY-badge
        if (isNew)
          Positioned(
            left: 12,
            top: 12,
            child: _pillBadge(
              text: 'NY',
              bg: _accent,
              fg: Colors.white,
              leadingDot: true,
            ),
          ),

        // Pris-badge (prominent)
        Positioned(
          right: 12,
          top: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatPrice(job.price),
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const TextSpan(
                    text: ' kr',
                    style: TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lokasjon-chip nederst venstre
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: previewUrl != null
                  ? Colors.white
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: _textPrimary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  job.locationName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Favoritt-hjerte (lokal state)
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.08),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _favorite = !_favorite),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: _favorite ? const Color(0xFFEF4B6C) : _textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pastelHeader(String category, double radius) {
    final palette = _pastelForCategory(category);

    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.end],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Stack(
        children: [
          // Subtile "soft shapes" i designstil
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Center(
            child: Icon(
              palette.icon,
              color: Colors.white.withOpacity(0.85),
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- CTA -------------------

  Widget _ctaButton(bool isOwner, bool isWorker) {
    final job = widget.job;
    final bool canTake = job.status == JobStatus.open && !isOwner;

    if (canTake) {
      return SizedBox(
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3E6BFF), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onTake,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 42),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text(
              'Ta jobb',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(color: Color(0xFFE4E9F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 42),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text(
          'Se detaljer',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ------------------- OWNER -------------------

  Widget _ownerStrip(String? name, double? rating, int? ratingCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F7BFF), _accent],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name ?? 'Bruker',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFFFB020)),
                const SizedBox(width: 2),
                Text(
                  (rating ?? 5.0).toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${ratingCount ?? 0})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ------------------- STATUS BADGE -------------------

  Widget _statusBadge(Job job, bool isOwner, bool isWorker) {
    String text;
    Color bg;
    Color fg;

    if (job.status == JobStatus.open) {
      text = 'Åpent';
      bg = _accent.withOpacity(0.14);
      fg = _accent;
    } else if (job.status == JobStatus.reserved) {
      text = isWorker ? 'Din reservasjon' : 'Reservert';
      bg = const Color(0xFFFFF4E5);
      fg = const Color(0xFFE08A00);
    } else if (job.status == JobStatus.inProgress &&
        !job.isCompletedByWorker) {
      text = 'Pågår';
      bg = const Color(0xFFFFEBD1);
      fg = const Color(0xFFE08A00);
    } else if (job.status == JobStatus.inProgress &&
        job.isCompletedByWorker) {
      text = isOwner ? 'Godkjenn?' : 'Venter';
      bg = const Color(0xFFFFE9E0);
      fg = Colors.deepOrange;
    } else {
      text = 'Fullført';
      bg = const Color(0xFFE7F6EC);
      fg = const Color(0xFF2E9757);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- SMALL HELPERS -------------------

  Widget _pillBadge({
    required String text,
    required Color bg,
    required Color fg,
    bool leadingDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {IconData? icon, bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? _primary.withOpacity(0.09) : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: _primary.withOpacity(0.18), width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _primary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  String _timeChipLabel(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diffDays = today.difference(created).inDays;

    if (diffDays == 0) return 'I dag';
    if (diffDays == 1) return 'I går';
    if (diffDays < 7) return 'For $diffDays d siden';

    const months = [
      'jan', 'feb', 'mar', 'apr', 'mai', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'des'
    ];
    return '${createdAt.day}. ${months[createdAt.month - 1]}';
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final fromEnd = str.length - i;
      buffer.write(str[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  _CategoryPalette _pastelForCategory(String category) {
    final key = category.toLowerCase().trim();
    switch (key) {
      case 'flytting':
        return const _CategoryPalette(
          start: Color(0xFFFFD6B8),
          end: Color(0xFFFFBFA0),
          icon: Icons.local_shipping_rounded,
        );
      case 'rengjøring':
      case 'rengjoring':
        return const _CategoryPalette(
          start: Color(0xFFE0DBFF),
          end: Color(0xFFC9BEFF),
          icon: Icons.cleaning_services_rounded,
        );
      case 'hage':
        return const _CategoryPalette(
          start: Color(0xFFC5EBD3),
          end: Color(0xFF9FDCB6),
          icon: Icons.yard_rounded,
        );
      case 'montering':
        return const _CategoryPalette(
          start: Color(0xFFCDEEE8),
          end: Color(0xFFA2DDD3),
          icon: Icons.handyman_rounded,
        );
      case 'bygg':
      case 'handyman':
        return const _CategoryPalette(
          start: Color(0xFFFFE7B5),
          end: Color(0xFFFFD38A),
          icon: Icons.construction_rounded,
        );
      case 'transport':
        return const _CategoryPalette(
          start: Color(0xFFD0E2FF),
          end: Color(0xFFA7C5FF),
          icon: Icons.directions_car_rounded,
        );
      default:
        return const _CategoryPalette(
          start: Color(0xFFDCE7FF),
          end: Color(0xFFB8CCFF),
          icon: Icons.work_rounded,
        );
    }
  }
}

class _CategoryPalette {
  final Color start;
  final Color end;
  final IconData icon;

  const _CategoryPalette({
    required this.start,
    required this.end,
    required this.icon,
  });
}
