import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';
import 'post_job_screen.dart';

enum JobSortOption {
  newest,
  oldest,
  priceHighLow,
  priceLowHigh,
  popular,
}

// FASE 3 FIX: gjort offentlig så AppShell / HomeScreen kan sende brukeren
// direkte til en valgt tab via `JobsScreen.initialTab`.
enum JobsTab { all, mine, taken }

enum JobsFilter {
  all,
  takenActive,
  postedActive,
  takenCompleted,
  postedCompleted,
}

const Color _primary = Color(0xFF2356E8);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key, this.initialFilter, this.initialTab});

  final JobsFilter? initialFilter;
  // FASE 3 FIX: velg hvilken fane som skal være aktiv ved første build.
  // Brukes av HomeScreen banner + AppShell for å åpne «Mine» / «Tatt»
  // direkte når bruker klikker aktivt-oppdrag-banneret.
  final JobsTab? initialTab;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  JobSortOption _sort = JobSortOption.newest;
  bool _showOnlyOpen = false;
  late JobsTab _activeTab = widget.initialTab ?? JobsTab.all;
  bool _isRefreshing = false;

  bool get _isFilteredView =>
      widget.initialFilter != null && widget.initialFilter != JobsFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().ensureJobsLoaded();
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await context.read<AppState>().reloadJobs();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oppdrag oppdatert'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFilteredView) {
      return _buildFilteredView(context);
    }
    return _buildTabbedView(context);
  }

  Widget _buildFilteredView(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;
    final filter = widget.initialFilter!;
    final jobs = _sortedJobs(_jobsForFilter(appState, filter));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text(
          _filterTitle(filter),
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isRefreshing
                ? const SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh_rounded, color: _primary),
                    tooltip: 'Last inn på nytt',
                  ),
          ),
        ],
      ),
      body: appState.isLoadingJobs && !appState.hasLoadedJobs
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _filterSummary(filter, jobs.length),
                  const SizedBox(height: 14),
                  if (jobs.isEmpty)
                    _emptyBox(_emptyTextForFilter(filter))
                  else
                    ..._buildJobList(
                      context,
                      jobs,
                      currentUser.id,
                      filter: filter,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabbedView(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;

    // FASE 2 PATCH: «Alle oppdrag»-fanen skal kun vise ÅPNE oppdrag.
    // Reservert/pågående/fullført hører hjemme under «Mine» / «Tatt»,
    // ikke i offentlig feed. Involverte brukere ser sine aktive jobber
    // fortsatt under sin egen fane.
    final all = _sortedJobs(
      appState.allJobsSortedByNewest.where((job) {
        if (job.status != JobStatus.open) return false;
        if (_showOnlyOpen && job.status != JobStatus.open) return false;
        return true;
      }).toList(),
    );

    final mine = _sortedJobs(appState.postedByCurrentUser);
    final taken = _sortedJobs(appState.takenByCurrentUser);

    late final List<Job> visibleJobs;
    late final String emptyText;
    switch (_activeTab) {
      case JobsTab.all:
        visibleJobs = all;
        emptyText = 'Ingen åpne oppdrag akkurat nå.';
        break;
      case JobsTab.mine:
        visibleJobs = mine;
        emptyText = 'Du har ikke lagt ut noen oppdrag enda.';
        break;
      case JobsTab.taken:
        visibleJobs = taken;
        emptyText = 'Du har ikke tatt noen oppdrag enda.';
        break;
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Oppdrag',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isRefreshing
                ? const SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh_rounded, color: _primary),
                    tooltip: 'Last inn på nytt',
                  ),
          ),
        ],
      ),
      body: appState.isLoadingJobs && !appState.hasLoadedJobs
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _tabPillRow(
                  allCount: all.length,
                  mineCount: mine.length,
                  takenCount: taken.length,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: _primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        if (_activeTab == JobsTab.all) ...[
                          _topControls(context),
                          const SizedBox(height: 18),
                        ],
                        if (visibleJobs.isEmpty)
                          _emptyBox(emptyText)
                        else
                          ..._buildJobList(
                            context,
                            visibleJobs,
                            currentUser.id,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Job> _jobsForFilter(AppState appState, JobsFilter filter) {
    switch (filter) {
      case JobsFilter.all:
        // Fokusert visning fra f.eks. Profil: viser full liste.
        return appState.allJobsSortedByNewest;
      case JobsFilter.takenActive:
        return appState.activeTakenJobs;
      case JobsFilter.postedActive:
        return appState.activePostedJobs;
      case JobsFilter.takenCompleted:
        return appState.completedTakenJobs;
      case JobsFilter.postedCompleted:
        return appState.completedPostedJobs;
    }
  }

  String _filterTitle(JobsFilter filter) {
    switch (filter) {
      case JobsFilter.all:
        return 'Alle oppdrag';
      case JobsFilter.takenActive:
        return 'Oppdrag jeg tar';
      case JobsFilter.postedActive:
        return 'Mine aktive oppdrag';
      case JobsFilter.takenCompleted:
        return 'Fullført av meg';
      case JobsFilter.postedCompleted:
        return 'Mine fullførte oppdrag';
    }
  }

  String _filterSubtitle(JobsFilter filter) {
    switch (filter) {
      case JobsFilter.all:
        return 'Alle tilgjengelige oppdrag';
      case JobsFilter.takenActive:
        return 'Oppdrag du har reservert eller jobber med.';
      case JobsFilter.postedActive:
        return 'Oppdrag du har lagt ut som fortsatt er aktive.';
      case JobsFilter.takenCompleted:
        return 'Oppdrag du har fullført for andre.';
      case JobsFilter.postedCompleted:
        return 'Oppdrag andre har fullført for deg.';
    }
  }

  String _emptyTextForFilter(JobsFilter filter) {
    switch (filter) {
      case JobsFilter.all:
        return 'Ingen oppdrag akkurat nå.';
      case JobsFilter.takenActive:
        return 'Du har ingen aktive oppdrag.';
      case JobsFilter.postedActive:
        return 'Du har ingen aktive oppdrag ute.';
      case JobsFilter.takenCompleted:
        return 'Du har ikke fullført noen oppdrag enda.';
      case JobsFilter.postedCompleted:
        return 'Ingen av oppdragene dine er fullført enda.';
    }
  }

  Widget _filterSummary(JobsFilter filter, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: _primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _filterTitle(filter),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _filterSubtitle(filter),
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildJobList(
    BuildContext context,
    List<Job> jobs,
    String currentUserId, {
    JobsFilter? filter,
  }) {
    final widgets = <Widget>[];
    final isAllTab = filter == null && _activeTab == JobsTab.all;
    final isMineTab = filter == null && _activeTab == JobsTab.mine;
    final isTakenTab = filter == null && _activeTab == JobsTab.taken;

    final showOwnerActions = isMineTab ||
        filter == JobsFilter.postedActive ||
        filter == JobsFilter.postedCompleted;
    final showTakerActions = isTakenTab || filter == JobsFilter.takenActive;

    for (final job in jobs) {
      final isOwner = job.createdByUserId == currentUserId;
      final isTaker = job.acceptedByUserId == currentUserId;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              JobCard(
                job: job,
                distanceText: job.locationName,
                onTap: () => _openJob(context, job),
                onTake: (isAllTab &&
                        job.status == JobStatus.open &&
                        !isOwner)
                    ? () => _takeJob(context, job)
                    : null,
              ),
              if (isOwner &&
                  showOwnerActions &&
                  job.status == JobStatus.open) ...[
                const SizedBox(height: 10),
                _ownerRowActions(context, job),
              ],
              if (isTaker && showTakerActions && job.isActive) ...[
                const SizedBox(height: 10),
                _takerRowActions(context, job),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _ownerRowActions(BuildContext context, Job job) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: job.status == JobStatus.open
                ? () => _openEditScreen(context, job)
                : null,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Rediger'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: BorderSide(color: _primary.withOpacity(0.35)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: job.status == JobStatus.open
                ? () => _confirmDelete(context, job)
                : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Slett'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0x55DC2626)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _takerRowActions(BuildContext context, Job job) {
    if (job.isReserved) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                await context.read<AppState>().startJob(job.id);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Start jobb'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmReleaseReservation(context, job),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Avbryt reservasjon'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE08A00),
                side: const BorderSide(color: Color(0x66E08A00)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    if (job.isInProgress) {
      final alreadyMarkedDone = job.isCompletedByWorker;
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: alreadyMarkedDone
                  ? null
                  : () async {
                      await context.read<AppState>().completeJob(job.id);
                    },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                alreadyMarkedDone ? 'Venter på godkjenning' : 'Fullfør jobb',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA877),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF0EA877).withOpacity(0.35),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AppState>().cancelJob(job.id);
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Avbryt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0x55DC2626)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirmReleaseReservation(
    BuildContext context,
    Job job,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Avbryt reservasjon?'),
        content: const Text(
          'Oppdraget åpnes igjen for andre, og oppdragsgiver får varsel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nei'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE08A00),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ja, avbryt'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AppState>().releaseJob(job.id);
  }

  Future<void> _takeJob(BuildContext context, Job job) async {
    final appState = context.read<AppState>();
    final ok = await appState.reserveJob(job.id);

    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke reservere oppdraget.'),
        ),
      );
      return;
    }

    final refreshed = appState.getJobById(job.id);
    if (refreshed != null && context.mounted) {
      _openJob(context, refreshed);
    }
  }

  Widget _tabPillRow({
    required int allCount,
    required int mineCount,
    required int takenCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _tabPill(
              label: 'Alle oppdrag',
              count: allCount,
              active: _activeTab == JobsTab.all,
              onTap: () => setState(() => _activeTab = JobsTab.all),
            ),
            const SizedBox(width: 8),
            _tabPill(
              label: 'Mine',
              count: mineCount,
              active: _activeTab == JobsTab.mine,
              onTap: () => setState(() => _activeTab = JobsTab.mine),
            ),
            const SizedBox(width: 8),
            _tabPill(
              label: 'Tatt',
              count: takenCount,
              active: _activeTab == JobsTab.taken,
              onTap: () => setState(() => _activeTab = JobsTab.taken),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill({
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: active ? Colors.white : _textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.22)
                    : _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  color: active ? Colors.white : _primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<JobSortOption>(
            value: _sort,
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            decoration: InputDecoration(
              labelText: 'Sorter etter',
              labelStyle: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(
                value: JobSortOption.newest,
                child: Text('Nyeste først'),
              ),
              DropdownMenuItem(
                value: JobSortOption.oldest,
                child: Text('Eldste først'),
              ),
              DropdownMenuItem(
                value: JobSortOption.priceHighLow,
                child: Text('Pris høy → lav'),
              ),
              DropdownMenuItem(
                value: JobSortOption.priceLowHigh,
                child: Text('Pris lav → høy'),
              ),
              DropdownMenuItem(
                value: JobSortOption.popular,
                child: Text('Mest vist'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sort = value);
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: _primary,
            title: const Text(
              'Vis bare åpne oppdrag',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: _showOnlyOpen,
            onChanged: (value) {
              setState(() => _showOnlyOpen = value);
            },
          ),
        ],
      ),
    );
  }

  List<Job> _sortedJobs(List<Job> jobs) {
    final copy = [...jobs];

    switch (_sort) {
      case JobSortOption.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case JobSortOption.oldest:
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case JobSortOption.priceHighLow:
        copy.sort((a, b) => b.price.compareTo(a.price));
        break;
      case JobSortOption.priceLowHigh:
        copy.sort((a, b) => a.price.compareTo(b.price));
        break;
      case JobSortOption.popular:
        copy.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    return copy;
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inbox_outlined,
                color: _textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openJob(BuildContext context, Job job) {
    context.read<AppState>().incrementView(job.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }

  void _openEditScreen(BuildContext context, Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostJobScreen(existingJob: job),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Job job) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Slett oppdrag'),
            content: const Text(
              'Er du sikker på at du vil slette dette oppdraget? Dette kan ikke angres.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Avbryt'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Slett'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final ok = await context.read<AppState>().deleteOwnJob(job.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Oppdraget ble slettet.' : 'Kunne ikke slette oppdraget.',
        ),
      ),
    );
  }
}
