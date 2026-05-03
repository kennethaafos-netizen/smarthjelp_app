import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job.dart';
import '../models/job_filter.dart';
import '../providers/app_state.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/job_card.dart';
import '../widgets/job_search_bar.dart';
import 'contact_screen.dart';
import 'faq_screen.dart';
import 'job_detail_screen.dart';
import 'jobs_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  // Generell navigasjon til bottom-nav-index (0=home, 1=jobs, 2=post, 3=chat, 4=profile).
  final Function(int)? onNavigate;
  // FASE 3 FIX: klikk på aktiv-oppdrag-banner går direkte til riktig underfane i Oppdrag.
  // Beholdes separat fra onNavigate for full bakoverkompatibilitet — signaturen på
  // onNavigate forblir uendret.
  final Function(JobsTab)? onNavigateToJobsTab;

  const HomeScreen({
    super.key,
    this.onNavigate,
    this.onNavigateToJobsTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMap = true;
  Job? _selectedJob;
  Set<Marker> _markers = {};
  bool _isTakingJob = false;

  // Sprint 6: erstatter den gamle `String? _selectedCategory`. Hele
  // søk + filter-tilstanden ligger her som ett immutable JobFilter-
  // objekt. Kategori-chips-raden synker mot filter.categories slik at
  // bruker kan velge enten via hurtigchip eller via filter-sheet.
  JobFilter _filter = const JobFilter();

  static const Color _primary = Color(0xFF2356E8);
  static const Color _accent = Color(0xFF18B7A6);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _textPrimary = Color(0xFF0F1E3A);
  static const Color _textMuted = Color(0xFF6E7A90);
  static const Color _danger = Color(0xFFDC2626);

  static const List<_CategoryOption> _categories = [
    _CategoryOption('Alle', Icons.apps_rounded),
    _CategoryOption('Flytting', Icons.local_shipping_outlined),
    _CategoryOption('Rengjøring', Icons.cleaning_services_outlined),
    _CategoryOption('Hage', Icons.grass_outlined),
    _CategoryOption('Montering', Icons.handyman_outlined),
    _CategoryOption('Bygg', Icons.construction_outlined),
    _CategoryOption('Transport', Icons.directions_car_filled_outlined),
  ];

  /// Kategori-labels som filter-sheeten kan velge fra. Speiler chip-
  /// raden, eksklusive "Alle" som er en hurtig-tøm-knapp og ikke en
  /// reell kategori.
  List<String> get _filterableCategories => _categories
      .where((c) => c.label != 'Alle')
      .map((c) => c.label)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().ensureJobsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = _applyFilters(appState);

    // FASE 3 FIX: aktive oppdrag inkluderer NÅ både reserved og inProgress.
    // Det gjør at worker ser banneret så snart han har reservert, og owner
    // ser det så snart jobben er tatt av noen.
    final activeJobs = appState.activeJobsForCurrentUser;
    final myId = appState.currentUser.id;

    // Avgjør hvilken Oppdrag-fane klikk på banneret skal åpne:
    //  - Worker-rollen (ligger i `takenByCurrentUser`) preferes siden
    //    den er mer handlings-kritisk (må starte, fullføre, etc).
    //  - Ellers: owner-rollen.
    final hasTakenRole =
        activeJobs.any((j) => j.acceptedByUserId == myId);
    final bannerTargetTab =
        hasTakenRole ? JobsTab.taken : JobsTab.mine;

    _buildMarkers(appState, jobs);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, jobs, appState.hasUnreadNotifications),
            const SizedBox(height: 12),
            // Sprint 6: søkefelt + filter-knapp ligger rett under
            // headeren. Filter-knappen åpner bottomsheet, søkefeltet
            // oppdaterer _filter.query umiddelbart.
            JobSearchBar(
              query: _filter.query,
              filterActive: _filter.isActive,
              activeFilterCount: _activeFilterCount(),
              onQueryChanged: _onSearchChanged,
              onFilterTap: _openFilterSheet,
            ),
            // Sprint 6: aktive-filter-chips. Returnerer SizedBox.shrink()
            // når filter er passive, så ingen vertikal støy.
            ActiveFilterChips(
              filter: _filter,
              onChange: _onFilterChanged,
              onClearAll: _clearFilters,
            ),
            if (activeJobs.isNotEmpty)
              _activeJobsBanner(activeJobs.length, bannerTargetTab),
            const SizedBox(height: 8),
            _segmentedToggle(),
            const SizedBox(height: 12),
            _categoryChipsRow(),
            const SizedBox(height: 12),

            Expanded(
              child: _showMap ? _mapView(jobs) : _listView(jobs),
            ),

            if (_selectedJob != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _previewCard(_selectedJob!),
                ),
              ),

            if (_isTakingJob)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- SPRINT 6: FILTER PIPELINE ----------------

  /// Komponerer base-list + JobFilter.apply. Når filter eller søk er
  /// aktivt bytter vi fra smartRankedJobs til rå open+!mine-liste,
  /// slik at viewCount-vekten i smartRankedJobs ikke forvrenger
  /// "Nærmest" eller "Pris lav→høy".
  List<Job> _applyFilters(AppState appState) {
    final List<Job> base;
    if (_filter.isActive || _filter.hasQuery) {
      final myId = appState.currentUser.id;
      base = appState.jobs.where((j) {
        if (j.status != JobStatus.open) return false;
        if (j.createdByUserId == myId) return false;
        return true;
      }).toList();
    } else {
      base = appState.smartRankedJobs;
    }
    return _filter.apply(
      base,
      distanceMetersFor: appState.jobDistance,
    );
  }

  /// Antall aktive filter-dimensjoner (for badge på filter-knappen).
  /// query teller ikke — søket har egen X-knapp i søkefeltet og egen
  /// chip i active-filter-raden.
  int _activeFilterCount() {
    var n = 0;
    if (_filter.categories.isNotEmpty) n++;
    if (_filter.minPrice != null || _filter.maxPrice != null) n++;
    if (_filter.radiusKm != null) n++;
    if (_filter.sort != JobSortMode.newest) n++;
    return n;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filter = _filter.copyWith(query: value);
      _selectedJob = null;
    });
  }

  void _onFilterChanged(JobFilter next) {
    setState(() {
      _filter = next;
      _selectedJob = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = const JobFilter();
      _selectedJob = null;
    });
  }

  Future<void> _openFilterSheet() async {
    final next = await showJobFilterSheet(
      context: context,
      initial: _filter,
      availableCategories: _filterableCategories,
    );
    if (next != null && mounted) {
      _onFilterChanged(next);
    }
  }

  // ---------------- CATEGORY CHIPS (HURTIGVALG) ----------------

  Widget _categoryChipsRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = _categories[index];
          final isAll = opt.label == 'Alle';
          // Aktiv tilstand: "Alle" når filter.categories er tom,
          // ellers en spesifikk chip kun når PRESIS én kategori er
          // valgt og den matcher denne chippen. Multi-valg fra filter-
          // sheeten viser ingen aktiv chip her — det er forventet, og
          // active-filter-chips-raden over reflekterer multi-state.
          final active = isAll
              ? _filter.categories.isEmpty
              : (_filter.categories.length == 1 &&
                  _filter.categories.contains(opt.label));
          return _categoryChip(
            label: opt.label,
            icon: opt.icon,
            active: active,
            onTap: () => setState(() {
              _filter = isAll
                  ? _filter.copyWith(categories: const <String>{})
                  : _filter.copyWith(categories: {opt.label});
              _selectedJob = null;
            }),
          );
        },
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? _primary : _textMuted.withOpacity(0.18),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : _textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: active ? Colors.white : _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FASE 3: ACTIVE JOBS BANNER ----------------

  Widget _activeJobsBanner(int count, JobsTab targetTab) {
    final title = count == 1
        ? 'Du har 1 aktivt oppdrag'
        : 'Du har $count aktive oppdrag';
    final subtitleBase = targetTab == JobsTab.taken
        ? (count == 1 ? 'Åpne «Tatt av meg» for å følge det.'
                       : 'Åpne «Tatt av meg» for å følge dem.')
        : (count == 1 ? 'Åpne «Mine» for å følge det.'
                       : 'Åpne «Mine» for å følge dem.');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Preferer tab-aware callback. Fallback til generell onNavigate
            // om ingen tab-callback er satt (f.eks. hvis HomeScreen brukes
            // utenfor AppShell i en test-kontekst).
            final cb = widget.onNavigateToJobsTab;
            if (cb != null) {
              cb(targetTab);
            } else {
              widget.onNavigate?.call(1);
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.24)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleBase,
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PREVIEW CARD ----------------

  Widget _previewCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          JobCard(
            job: job,
            distanceText: job.locationName,
            onTap: () => _openJob(job),
            onTake: job.status == JobStatus.open
                ? () => _takeAndOpen(job)
                : null,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.10),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _selectedJob = null),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAP ----------------

  Widget _mapView(List<Job> jobs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(59.14, 9.65),
            zoom: 11,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onTap: (_) => setState(() => _selectedJob = null),
        ),
      ),
    );
  }

  void _buildMarkers(AppState appState, List<Job> jobs) {
    _markers = jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(
          appState.jobMarkerLat(job),
          appState.jobMarkerLng(job),
        ),
        onTap: () {
          final fresh =
              context.read<AppState>().getJobById(job.id) ?? job;

          setState(() => _selectedJob = fresh);
        },
      );
    }).toSet();
  }

  // ---------------- LIST ----------------

  Widget _listView(List<Job> jobs) {
    if (jobs.isEmpty) {
      // Sprint 6: empty state har to varianter. Når filter eller søk
      // er aktivt får brukeren en "Nullstill"-knapp som rydder alt på
      // ett klikk — ellers default-meldingen som før.
      final hasFilter = _filter.isActive || _filter.hasQuery;
      return _emptyState(
        icon: hasFilter
            ? Icons.filter_alt_off_rounded
            : Icons.travel_explore_outlined,
        title: hasFilter
            ? 'Ingen oppdrag matcher filtrene'
            : 'Ingen oppdrag i nærheten',
        subtitle: hasFilter
            ? 'Prøv å nullstille filteret eller endre søket.'
            : 'Vi varsler deg når noe dukker opp.',
        onClear: hasFilter ? _clearFilters : null,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: jobs
          .map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: JobCard(
                job: job,
                distanceText: job.locationName,
                onTap: () => _openJob(job),
                onTake: job.status == JobStatus.open
                    ? () => _takeAndOpen(job)
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onClear,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _danger,
                ),
                label: const Text(
                  'Nullstill filter',
                  style: TextStyle(
                    color: _danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _danger.withOpacity(0.45)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- ACTIONS ----------------

  Future<void> _takeAndOpen(Job job) async {
    if (_isTakingJob) return;

    final appState = context.read<AppState>();

    setState(() {
      _isTakingJob = true;
      _selectedJob = null;
    });

    final ok = await appState.reserveJob(job.id);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke ta oppdrag')),
      );
      setState(() => _isTakingJob = false);
      return;
    }

    final updated = appState.getJobById(job.id);

    if (updated != null) {
      _openJob(updated);
    }

    if (mounted) setState(() => _isTakingJob = false);
  }

  void _openJob(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );
  }

  // ---------------- UI HEADER ----------------

  Widget _header(BuildContext context, List<Job> jobs, bool hasUnread) {
    final user = context.read<AppState>().currentUser;
    final count = jobs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.firstName.isEmpty ? 'Velkommen' : user.firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                _countPill(count),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _notificationBell(hasUnread),
          const SizedBox(width: 10),
          _avatar(user.firstName),
        ],
      ),
    );
  }

  Widget _notificationBell(bool hasUnread) {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _textMuted.withOpacity(0.14),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _textPrimary,
              size: 22,
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return PopupMenuButton<String>(
      tooltip: 'Min konto',
      offset: const Offset(0, 56),
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _textMuted.withOpacity(0.12)),
      ),
      onSelected: _handleMenuSelection,
      itemBuilder: (_) => [
        _menuEntry('profile', Icons.person_outline_rounded, 'Min side'),
        _menuEntry('settings', Icons.settings_outlined, 'Innstillinger'),
        _menuEntry('contact', Icons.mail_outline_rounded, 'Kontakt oss'),
        _menuEntry('faq', Icons.help_outline_rounded, 'FAQ'),
        const PopupMenuDivider(height: 8),
        _menuEntry(
          'logout',
          Icons.logout_rounded,
          'Logg ut',
          isDanger: true,
        ),
      ],
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: _primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuEntry(
    String value,
    IconData icon,
    String label, {
    bool isDanger = false,
  }) {
    final color = isDanger ? const Color(0xFFDC2626) : _textPrimary;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        widget.onNavigate?.call(4);
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'contact':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ContactScreen()),
        );
        break;
      case 'faq':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FaqScreen()),
        );
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  Future<void> _logout() async {
    // FIX: Tidligere pushet vi OnboardingScreen manuelt med
    // pushAndRemoveUntil((_) => false), som fjernet _BootstrapGate fra
    // navigator-stacken. Etter det lyttet ingen på AppState-auth-endringer,
    // så login "gjorde ingenting" fordi BootstrapGate var borte fra treet.
    //
    // Riktig flyt: kall AppState.logout() og la BootstrapGate bytte home
    // til OnboardingScreen automatisk når isAuthenticated=false.
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    await appState.logout();
    if (!mounted) return;
    navigator.popUntil((r) => r.isFirst);
  }

  Widget _countPill(int count) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onNavigate?.call(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 14, color: _accent),
            const SizedBox(width: 6),
            Text(
              count == 1
                  ? '1 oppdrag tilgjengelig'
                  : '$count oppdrag tilgjengelig',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SEGMENTED TOGGLE ----------------

  Widget _segmentedToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E9F2), width: 1),
        ),
        child: Row(
          children: [
            _segment(
              label: 'Kart',
              icon: Icons.map_outlined,
              active: _showMap,
              onTap: () => setState(() {
                _showMap = true;
                _selectedJob = null;
              }),
            ),
            _segment(
              label: 'Liste',
              icon: Icons.view_list_rounded,
              active: !_showMap,
              onTap: () => setState(() {
                _showMap = false;
                _selectedJob = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : _textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: active ? Colors.white : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'God natt';
    if (hour < 10) return 'God morgen';
    if (hour < 17) return 'God dag';
    if (hour < 22) return 'God kveld';
    return 'God natt';
  }
}

class _CategoryOption {
  final String label;
  final IconData icon;

  const _CategoryOption(this.label, this.icon);
}