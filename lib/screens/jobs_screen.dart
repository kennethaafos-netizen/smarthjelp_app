import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import '../widgets/reserved_timer.dart';
import 'job_detail_screen.dart';

enum JobSortOption {
  newest,
  oldest,
  priceHighLow,
  priceLowHigh,
  popular,
}

enum _JobsTab { all, mine, taken }

const Color _primary = Color(0xFF2356E8);
const Color _bg = Color(0xFFF4F7FC);
const Color _textPrimary = Color(0xFF0F1E3A);
const Color _textMuted = Color(0xFF6E7A90);

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  JobSortOption _sort = JobSortOption.newest;
  bool _showOnlyOpen = false;
  _JobsTab _activeTab = _JobsTab.all;

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
    final currentUser = appState.currentUser;

    final all = _sortedJobs(
      appState.allJobsSortedByNewest.where((job) {
        if (_showOnlyOpen && job.status != JobStatus.open) return false;
        return true;
      }).toList(),
    );

    final mine = _sortedJobs(appState.postedByCurrentUser);
    final taken = _sortedJobs(appState.takenByCurrentUser);

    late final List<Job> visibleJobs;
    late final String emptyText;
    switch (_activeTab) {
      case _JobsTab.all:
        visibleJobs = all;
        emptyText = 'Ingen oppdrag matcher filtreringen akkurat nå.';
        break;
      case _JobsTab.mine:
        visibleJobs = mine;
        emptyText = 'Du har ikke lagt ut noen oppdrag enda.';
        break;
      case _JobsTab.taken:
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
            child: IconButton(
              onPressed: () => appState.reloadJobs(),
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
                    onRefresh: appState.reloadJobs,
                    color: _primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        if (_activeTab == _JobsTab.all) ...[
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

  List<Widget> _buildJobList(
    BuildContext context,
    List<Job> jobs,
    String currentUserId,
  ) {
    final widgets = <Widget>[];

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
                onTake: (_activeTab == _JobsTab.all &&
                        job.status == JobStatus.open &&
                        !isOwner)
                    ? () => _takeJob(context, job)
                    : null,
              ),
              if (job.status == JobStatus.reserved &&
                  job.reservedUntil != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ReservedTimer(
                    jobId: job.id,
                    reservedUntil: job.reservedUntil!,
                  ),
                ),
              if (isOwner && _activeTab == _JobsTab.mine) ...[
                const SizedBox(height: 10),
                _ownerRowActions(context, job),
              ],
              if (isTaker &&
                  _activeTab == _JobsTab.taken &&
                  job.status == JobStatus.reserved) ...[
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
                ? () => _showEditDialog(context, job)
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AppState>().releaseJob(job.id);
        },
        icon: const Icon(Icons.close_rounded, size: 18),
        label: const Text('Slipp reservasjon'),
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
    );
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

  // ---------- TAB PILL ROW ----------
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
              active: _activeTab == _JobsTab.all,
              onTap: () => setState(() => _activeTab = _JobsTab.all),
            ),
            const SizedBox(width: 8),
            _tabPill(
              label: 'Mine',
              count: mineCount,
              active: _activeTab == _JobsTab.mine,
              onTap: () => setState(() => _activeTab = _JobsTab.mine),
            ),
            const SizedBox(width: 8),
            _tabPill(
              label: 'Tatt',
              count: takenCount,
              active: _activeTab == _JobsTab.taken,
              onTap: () => setState(() => _activeTab = _JobsTab.taken),
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

  Future<void> _showEditDialog(BuildContext context, Job job) async {
    final titleCtrl = TextEditingController(text: job.title);
    final descCtrl = TextEditingController(text: job.description);
    final priceCtrl = TextEditingController(text: job.price.toString());
    final categoryCtrl = TextEditingController(text: job.category);
    final locationCtrl = TextEditingController(text: job.locationName);
    final formKey = GlobalKey<FormState>();

    double lat = job.lat;
    double lng = job.lng;

    final saved = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Rediger oppdrag'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tittel'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Skriv tittel' : null,
                    ),
                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Beskrivelse'),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv beskrivelse'
                          : null,
                    ),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Pris'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse((v ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Ugyldig pris';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv kategori'
                          : null,
                    ),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Sted (postnr. + sted)'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Skriv sted' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Avbryt'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Lagre'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved || !context.mounted) return;

    final ok = await context.read<AppState>().updateOwnJob(
          jobId: job.id,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: int.parse(priceCtrl.text.trim()),
          category: categoryCtrl.text.trim(),
          locationName: locationCtrl.text.trim(),
          lat: lat,
          lng: lng,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Oppdraget ble oppdatert.' : 'Kunne ikke oppdatere oppdraget.',
        ),
      ),
    );
  }
}
