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

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  JobSortOption _sort = JobSortOption.newest;
  bool _showOnlyOpen = false;

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

    final allJobs = _sortedJobs(
      appState.allJobsSortedByNewest.where((job) {
        if (_showOnlyOpen && job.status != JobStatus.open) return false;
        return true;
      }).toList(),
    );

    final myPosted = appState.postedByCurrentUser;
    final myTaken = appState.takenByCurrentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oppdrag'),
        actions: [
          IconButton(
            tooltip: 'Oppdater liste',
            onPressed: appState.isLoadingJobs
                ? null
                : () => appState.reloadJobs(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: appState.isLoadingJobs && !appState.hasLoadedJobs
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: appState.reloadJobs,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (appState.jobsError != null)
                    _errorBanner(appState.jobsError!),
                  _topControls(context),
                  const SizedBox(height: 16),
                  _sectionTitle('📍 Alle oppdrag'),
                  const SizedBox(height: 8),
                  if (allJobs.isEmpty)
                    _emptyBox('Ingen oppdrag matcher filtreringen akkurat nå.')
                  else
                    ...allJobs.map(
                      (job) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Stack(
                          children: [
                            JobCard(
                              job: job,
                              distanceText: job.locationName,
                              onTap: () => _openJob(context, job),
                              onTake: (job.status == JobStatus.open &&
                                      job.createdByUserId != currentUser.id)
                                  ? () async {
                                      final ok = await context
                                          .read<AppState>()
                                          .reserveJob(job.id);

                                      if (!context.mounted) return;

                                      if (!ok) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kunne ikke reservere oppdraget.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final refreshed = context
                                          .read<AppState>()
                                          .getJobById(job.id);
                                      if (refreshed != null &&
                                          context.mounted) {
                                        _openJob(context, refreshed);
                                      }
                                    }
                                  : null,
                            ),
                            if (job.status == JobStatus.reserved &&
                                job.reservedUntil != null)
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Reservert',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            if (job.cancelRequestedByUserId != null &&
                                job.status == JobStatus.inProgress)
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Avbrytelse bedt om',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _sectionTitle('📤 Mine oppdrag'),
                  const SizedBox(height: 8),
                  if (myPosted.isEmpty)
                    _emptyBox('Du har ikke lagt ut noen oppdrag enda.')
                  else
                    ...myPosted.map(
                      (job) => Column(
                        children: [
                          JobCard(
                            job: job,
                            distanceText: job.locationName,
                            onTap: () => _openJob(context, job),
                          ),
                          if (job.status == JobStatus.reserved &&
                              job.reservedUntil != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ReservedTimer(
                                jobId: job.id,
                                reservedUntil: job.reservedUntil!,
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: job.status == JobStatus.open
                                      ? () => _showEditDialog(context, job)
                                      : null,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Rediger'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: job.status == JobStatus.open
                                      ? () => _confirmDelete(context, job)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Slett'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  _sectionTitle('📥 Oppdrag jeg har tatt'),
                  const SizedBox(height: 8),
                  if (myTaken.isEmpty)
                    _emptyBox('Du har ikke tatt noen oppdrag enda.')
                  else
                    ...myTaken.map(
                      (job) => Column(
                        children: [
                          JobCard(
                            job: job,
                            distanceText: job.locationName,
                            onTap: () => _openJob(context, job),
                          ),
                          if (job.status == JobStatus.reserved &&
                              job.reservedUntil != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ReservedTimer(
                                jobId: job.id,
                                reservedUntil: job.reservedUntil!,
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _topControls(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<JobSortOption>(
                value: _sort,
                decoration: const InputDecoration(
                  labelText: 'Sorter',
                  border: OutlineInputBorder(),
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
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Vis bare åpne oppdrag'),
          value: _showOnlyOpen,
          onChanged: (value) {
            setState(() => _showOnlyOpen = value);
          },
        ),
      ],
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6E7A90),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
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
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Slett'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final appState = context.read<AppState>();
    final ok = await appState.deleteOwnJob(job.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Oppdraget ble slettet.' : 'Kunne ikke slette oppdraget.',
        ),
      ),
    );

    // Hent kanonisk state fra server etter delete
    if (ok) {
      await appState.reloadJobs();
    }
  }

  Future<void> _showEditDialog(BuildContext context, Job job) async {
    final titleCtrl = TextEditingController(text: job.title);
    final descCtrl = TextEditingController(text: job.description);
    final priceCtrl = TextEditingController(text: job.price.toString());
    final categoryCtrl = TextEditingController(text: job.category);
    final locationCtrl = TextEditingController(text: job.locationName);
    final formKey = GlobalKey<FormState>();

    // Lat/lng endres ikke i dialogen – vi beholder eksisterende verdier.
    final double lat = job.lat;
    final double lng = job.lng;

    final saved = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv tittel'
                          : null,
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
                      decoration: const InputDecoration(labelText: 'Sted'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Skriv sted'
                          : null,
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

    final appState = context.read<AppState>();
    final ok = await appState.updateOwnJob(
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

    if (ok) {
      await appState.reloadJobs();
    }
  }
}
