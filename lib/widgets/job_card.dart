// UI UPGRADE: premium polish, hierarchy, spacing, and clearer navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../screens/image_viewer_screen.dart';

class JobCard extends StatelessWidget {
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

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _textPrimary = Color(0xFF172033);
  static const Color _textMuted = Color(0xFF6E7A90);

  @override
  Widget build(BuildContext context) {
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

    final double radius = compact ? 20 : 22;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 0 : 4),
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
              Stack(
                children: [
                  if (previewUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          final gallery =
                              images.isNotEmpty ? images : [previewUrl];
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
                                _imageFallback(radius),
                          ),
                        ),
                      ),
                    )
                  else
                    _imageFallback(radius),
                  if (previewUrl != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(0),
                            ),
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
                  if (isNew)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _badge(
                        text: 'NY',
                        bg: _accent,
                        fg: Colors.white,
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
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
                      child: Text(
                        '${job.price} kr',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  if (previewUrl != null)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  job.locationName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  compact ? 14 : 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 17,
                        color: _textPrimary,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.description,
                      maxLines: compact ? 1 : 2,
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
                        _chip(job.category),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            distanceText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(job, isOwner, isWorker),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ownerStrip(owner?.firstName, owner?.rating),
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

  Widget _ctaButton(bool isOwner, bool isWorker) {
    final bool canTake = job.status == JobStatus.open && !isOwner;

    if (canTake) {
      return SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onTake,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(0, 40),
          ),
          icon: const Icon(Icons.bolt_rounded, size: 16),
          label: const Text(
            'Ta jobb',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          side: const BorderSide(color: Color(0xFFE4E9F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 40),
        ),
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: const Text(
          'Se detaljer',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _ownerStrip(String? name, double? rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F7BFF), _accent],
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name ?? 'Bruker',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB020)),
        const SizedBox(width: 2),
        Text(
          (rating ?? 5.0).toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

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
      bg = _primary.withOpacity(0.12);
      fg = _primary;
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _badge({
    required String text,
    required Color bg,
    required Color fg,
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
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _primary,
        ),
      ),
    );
  }

  Widget _imageFallback(double radius) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius),
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 34, color: Colors.grey),
      ),
    );
  }
}
