import 'package:flutter/material.dart';

import '../models/job_filter.dart';

/// Sprint 6: bottom sheet for full filter-kontroll. Tar inn current
/// JobFilter + tilgjengelige kategorier, og returnerer (via Navigator.pop)
/// en ny JobFilter ved "Bruk" eller null ved "Avbryt".
///
/// Søkefeltet bor utenfor sheeten (i HomeScreen-headeren), så vi
/// preserverer `query` uendret — sheeten endrer bare kategori, pris,
/// radius og sort.
const double _maxPrice = 10000.0;
const double _maxRadiusKm = 50.0;

Future<JobFilter?> showJobFilterSheet({
  required BuildContext context,
  required JobFilter initial,
  required List<String> availableCategories,
}) {
  return showModalBottomSheet<JobFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(
      initial: initial,
      availableCategories: availableCategories,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final JobFilter initial;
  final List<String> availableCategories;

  const _FilterSheet({
    required this.initial,
    required this.availableCategories,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const Color _primary = Color(0xFF2356E8);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);

  late Set<String> _categories;
  late RangeValues _priceRange;
  late double _radiusKm;
  late bool _radiusEnabled;
  late JobSortMode _sort;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _priceRange = RangeValues(
      (widget.initial.minPrice ?? 0).toDouble(),
      (widget.initial.maxPrice ?? _maxPrice).toDouble(),
    );
    _radiusKm = widget.initial.radiusKm ?? 10.0;
    _radiusEnabled = widget.initial.radiusKm != null;
    _sort = widget.initial.sort;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _grabber(),
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Kategori'),
                        const SizedBox(height: 10),
                        _categoryWrap(),
                        const SizedBox(height: 22),
                        _sectionLabel('Pris'),
                        const SizedBox(height: 6),
                        _priceSection(),
                        const SizedBox(height: 22),
                        _sectionLabel('Radius'),
                        const SizedBox(height: 6),
                        _radiusSection(),
                        const SizedBox(height: 22),
                        _sectionLabel('Sortering'),
                        const SizedBox(height: 8),
                        _sortSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _grabber() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: _textMuted.withOpacity(0.30),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 14, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Filtrer oppdrag',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: _resetLocal,
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            child: const Text('Nullstill'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _categoryWrap() {
    if (widget.availableCategories.isEmpty) {
      return Text(
        'Ingen kategorier tilgjengelig',
        style: TextStyle(
          color: _textMuted,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableCategories.map((cat) {
        final selected = _categories.contains(cat);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (selected) {
              _categories.remove(cat);
            } else {
              _categories.add(cat);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _primary.withOpacity(0.12) : _bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _primary : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: selected ? _primary : _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _priceSection() {
    final minLabel = '${_priceRange.start.round()} kr';
    final maxLabel = _priceRange.end >= _maxPrice
        ? '${_maxPrice.round()}+ kr'
        : '${_priceRange.end.round()} kr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              minLabel,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              maxLabel,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primary,
            inactiveTrackColor: _primary.withOpacity(0.15),
            thumbColor: _primary,
            overlayColor: _primary.withOpacity(0.10),
            valueIndicatorColor: _primary,
            rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxPrice,
            divisions: 50,
            labels: RangeLabels(minLabel, maxLabel),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
        ),
      ],
    );
  }

  Widget _radiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _radiusEnabled
                    ? 'Innenfor ${_radiusKm.toStringAsFixed(_radiusKm < 10 ? 1 : 0)} km'
                    : 'Av (alle avstander)',
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Switch.adaptive(
              value: _radiusEnabled,
              activeColor: _primary,
              onChanged: (v) => setState(() => _radiusEnabled = v),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:
                _radiusEnabled ? _primary : _textMuted,
            inactiveTrackColor: (_radiusEnabled ? _primary : _textMuted)
                .withOpacity(0.15),
            thumbColor: _radiusEnabled ? _primary : _textMuted,
            overlayColor: _primary.withOpacity(0.10),
          ),
          child: Slider(
            value: _radiusKm,
            min: 1,
            max: _maxRadiusKm,
            divisions: 49,
            onChanged: _radiusEnabled
                ? (v) => setState(() => _radiusKm = v)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _sortSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: JobSortMode.values.map((mode) {
        final selected = _sort == mode;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _sort = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _primary : _bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _primary : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              mode.label,
              style: TextStyle(
                color: selected ? Colors.white : _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _footer() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textMuted,
                  side:
                      BorderSide(color: _textMuted.withOpacity(0.30)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Avbryt'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                child: const Text('Bruk filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetLocal() {
    setState(() {
      _categories = <String>{};
      _priceRange = const RangeValues(0, _maxPrice);
      _radiusKm = 10;
      _radiusEnabled = false;
      _sort = JobSortMode.newest;
    });
  }

  void _apply() {
    // Min 0 og max ved øvre grense behandles som "ingen grense" → null,
    // slik at isActive ikke trigger uten reell endring.
    final minPrice =
        _priceRange.start <= 0 ? null : _priceRange.start.round();
    final maxPrice = _priceRange.end >= _maxPrice
        ? null
        : _priceRange.end.round();
    final next = JobFilter(
      categories: {..._categories},
      minPrice: minPrice,
      maxPrice: maxPrice,
      radiusKm: _radiusEnabled ? _radiusKm : null,
      sort: _sort,
      query: widget.initial.query, // søket lever utenfor sheeten
    );
    Navigator.of(context).pop(next);
  }
}