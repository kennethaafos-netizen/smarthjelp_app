import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMap = true;
  Job? _selectedJob;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.smartRankedJobs;

    _buildMarkers(jobs);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, jobs),
            const SizedBox(height: 10),
            _toggle(),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showMap ? _mapView(jobs) : _listView(jobs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, List<Job> jobs) {
    final user = context.read<AppState>().currentUser;
    final nearbyCount = jobs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Hei ${user.firstName} 👋",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate?.call(4),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.person_outline),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showMap = false),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2356E8), Color(0xFF18B7A6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$nearbyCount oppdrag i nærheten av deg",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _toggleBtn("Kart", _showMap, () {
              setState(() => _showMap = true);
            }),
            _toggleBtn("Liste", !_showMap, () {
              setState(() => _showMap = false);
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2356E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapView(List<Job> jobs) {
    return Stack(
      key: const ValueKey('map_view'),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
        if (_selectedJob != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: JobCard(
              job: _selectedJob!,
              distanceText: _selectedJob!.locationName,
              onTap: () => _openJob(_selectedJob!),
            ),
          ),
      ],
    );
  }

  void _buildMarkers(List<Job> jobs) {
    _markers = jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(job.lat, job.lng),
        infoWindow: InfoWindow(
          title: "${job.title} • ${job.price} kr",
          snippet: "${job.category} • ${job.locationName}",
        ),
        onTap: () => setState(() => _selectedJob = job),
      );
    }).toSet();
  }

  Widget _listView(List<Job> jobs) {
    final trending = [...jobs]
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

    return ListView(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "🔥 Trending",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170, // 🔥 økt for knapp
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final job = trending[i];

              return GestureDetector(
                onTap: () => _openJob(job),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${job.price} kr"),

                          ElevatedButton(
                            onPressed: () {
                              context.read<AppState>().reserveJob(job.id);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              minimumSize: const Size(0, 40),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Ta jobb",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "📍 Alle oppdrag",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        ...jobs.map(
          (job) => JobCard(
            job: job,
            distanceText: job.locationName,
            onTap: () => _openJob(job),
          ),
        ),
      ],
    );
  }

  void _openJob(Job job) {
    context.read<AppState>().incrementView(job.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );
  }
}