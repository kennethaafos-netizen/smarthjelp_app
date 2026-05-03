import 'package:flutter/material.dart';

/// Sprint 6: premium søkefelt + filter-knapp som ligger rett under
/// HomeScreen-headeren. Helt frittstående widget — vet ingenting om
/// JobFilter eller AppState. Tar inn current query, callbacks for
/// query-endring og filter-tap, samt et lite badge med antall aktive
/// filter-dimensjoner. Kan gjenbrukes uendret i JobsScreen (Sprint 6.5).
class JobSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onFilterTap;
  final bool filterActive;
  final int activeFilterCount;
  final String hintText;

  const JobSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onFilterTap,
    this.filterActive = false,
    this.activeFilterCount = 0,
    this.hintText = 'Søk i oppdrag …',
  });

  @override
  State<JobSearchBar> createState() => _JobSearchBarState();
}

class _JobSearchBarState extends State<JobSearchBar> {
  static const Color _primary = Color(0xFF2356E8);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);
  static const Color _danger = Color(0xFFDC2626);

  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant JobSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync eksterne clears (f.eks. nullstill via filter-chip) uten å
    // trigge en onChanged-loop. Posisjonerer cursor på enden så bruker
    // kan fortsette å skrive uten ekstra tap.
    if (widget.query != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.query,
        selection:
            TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: focused
                      ? _primary
                      : _textMuted.withOpacity(0.18),
                  width: focused ? 1.4 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: focused ? _primary : _textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: widget.onQueryChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: _primary,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (widget.query.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _ctrl.clear();
                        widget.onQueryChanged('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onFilterTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: widget.filterActive ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.filterActive
                          ? _primary
                          : _textMuted.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: widget.filterActive
                        ? Colors.white
                        : _textPrimary,
                  ),
                ),
                if (widget.filterActive && widget.activeFilterCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _danger,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}