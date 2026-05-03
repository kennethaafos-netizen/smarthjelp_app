import 'package:flutter/material.dart';

import '../models/job_filter.dart';

/// Sprint 6: horizontal-scrollable rad med chips for hver aktiv filter-
/// dimensjon. Hver chip kan fjernes individuelt via X. "Nullstill"-pille
/// til høyre tømmer alt på ett klikk. Returnerer SizedBox.shrink() når
/// filter er passive (ingen aktive dimensjoner og ingen søketekst).
///
/// Frittstående widget — bare avhengig av JobFilter-modellen, kan
/// gjenbrukes i JobsScreen (Sprint 6.5).
class ActiveFilterChips extends StatelessWidget {
  final JobFilter filter;
  final ValueChanged<JobFilter> onChange;
  final VoidCallback onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.onChange,
    required this.onClearAll,
  });

  static const Color _primary = Color(0xFF2356E8);
  static const Color _danger = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive && !filter.hasQuery) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    if (filter.hasQuery) {
      chips.add(_chip(
        '"${filter.query.trim()}"',
        Icons.search_rounded,
        onRemove: () => onChange(filter.copyWith(query: '')),
      ));
    }

    for (final cat in filter.categories) {
      chips.add(_chip(
        cat,
        Icons.category_outlined,
        onRemove: () {
          final next = <String>{...filter.categories}..remove(cat);
          onChange(filter.copyWith(categories: next));
        },
      ));
    }

    if (filter.minPrice != null || filter.maxPrice != null) {
      chips.add(_chip(
        _priceLabel(filter.minPrice, filter.maxPrice),
        Icons.payments_outlined,
        onRemove: () => onChange(
          filter.copyWith(minPrice: null, maxPrice: null),
        ),
      ));
    }

    if (filter.radiusKm != null) {
      final r = filter.radiusKm!;
      final label = '< ${r.toStringAsFixed(r < 10 ? 1 : 0)} km';
      chips.add(_chip(
        label,
        Icons.place_outlined,
        onRemove: () => onChange(filter.copyWith(radiusKm: null)),
      ));
    }

    if (filter.sort != JobSortMode.newest) {
      chips.add(_chip(
        filter.sort.label,
        Icons.swap_vert_rounded,
        onRemove: () =>
            onChange(filter.copyWith(sort: JobSortMode.newest)),
      ));
    }

    chips.add(_clearAllChip());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      ),
    );
  }

  String _priceLabel(int? min, int? max) {
    if (min != null && max != null) return '$min – $max kr';
    if (min != null) return '≥ $min kr';
    if (max != null) return '≤ $max kr';
    return '';
  }

  Widget _chip(
    String label,
    IconData icon, {
    required VoidCallback onRemove,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clearAllChip() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClearAll,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _danger.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _danger.withOpacity(0.30)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: _danger),
            SizedBox(width: 4),
            Text(
              'Nullstill',
              style: TextStyle(
                color: _danger,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}