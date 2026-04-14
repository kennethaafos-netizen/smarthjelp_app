import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final String distanceText;
  final bool compact;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.distanceText,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final owner = context.read<AppState>().getUserById(job.createdByUserId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 0 : 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // 🔥 mer rounded
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // 🔥 mykere shadow
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 BILDE / ICON
                Container(
                  width: compact ? 50 : 60,
                  height: compact ? 50 : 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4F7BFF).withOpacity(0.15),
                        const Color(0xFF18B7A6).withOpacity(0.15),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Color(0xFF2356E8),
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                // 🔥 TEXT
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // 🔥 CATEGORY CHIP (bedre design)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F7BFF).withOpacity(0.15),
                                  const Color(0xFF18B7A6).withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              job.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2356E8),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 🔥 DISTANCE + TIME
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14, color: Color(0xFF6E7A90)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    distanceText,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6E7A90),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 🔥 PRICE + BUTTON
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${job.price} kr",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18B7A6),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔥 PREMIUM BUTTON
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F7BFF), Color(0xFF18B7A6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4F7BFF).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        job.status == JobStatus.open ? "Ta jobb" : "Se",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (!compact) ...[
              const SizedBox(height: 12),

              // 🔥 OWNER ROW (beholdt, men forbedret spacing)
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    child: Icon(Icons.person, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      owner?.firstName ?? "Bruker",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF172033),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        owner != null
                            ? owner.rating.toStringAsFixed(1)
                            : "5.0",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}