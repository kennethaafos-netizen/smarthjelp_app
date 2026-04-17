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

  @override
  Widget build(BuildContext context) {
    final owner = context.read<AppState>().getUserById(job.createdByUserId);
    final currentUser = context.watch<AppState>().currentUser;
    final images = context.watch<AppState>().getImages(job.id);

    final previewUrl = images.isNotEmpty
        ? images.first
        : (job.imageUrl != null && job.imageUrl!.isNotEmpty ? job.imageUrl : null);

    final isOwner = job.createdByUserId == currentUser.id;
    final isWorker = job.acceptedByUserId == currentUser.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 0 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (previewUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
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
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      ),
                    ),
                  ),
                )
              else
                _imageFallback(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 14 : 16,
                              color: const Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.description,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6E7A90),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                    color: Color(0xFF6E7A90),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 8),
                            _statusText(job, isOwner, isWorker),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${job.price} kr',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF18B7A6),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOwner
                              ? 'Du betaler ${job.totalPrice.toStringAsFixed(0)}'
                              : 'Utfører får ${job.payout.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6E7A90),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (job.status == JobStatus.open && !isOwner)
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: onTake,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2356E8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(0, 34),
                              ),
                              child: const Text(
                                'Ta jobb',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(0, 34),
                              ),
                              child: const Text(
                                'Se',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          owner?.firstName ?? 'Bruker',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        owner != null
                            ? owner.rating.toStringAsFixed(1)
                            : '5.0',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusText(Job job, bool isOwner, bool isWorker) {
    String text;
    Color color;

    if (job.status == JobStatus.open) {
      text = 'Åpent oppdrag';
      color = const Color(0xFF18B7A6);
    } else if (job.status == JobStatus.reserved) {
      text = isWorker ? 'Du har reservert' : 'Reservert';
      color = Colors.orange;
    } else if (job.status == JobStatus.inProgress && !job.isCompletedByWorker) {
      text = 'Pågår';
      color = const Color(0xFF2356E8);
    } else if (job.status == JobStatus.inProgress && job.isCompletedByWorker) {
      text = isOwner ? 'Venter på din godkjenning' : 'Venter på godkjenning';
      color = Colors.deepOrange;
    } else {
      text = 'Fullført';
      color = Colors.green;
    }

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 34, color: Colors.grey),
      ),
    );
  }
}