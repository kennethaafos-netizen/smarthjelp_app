import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final PageController _controller = PageController();

  // Brukes til deterministisk-nok jitter på koordinater slik at flere jobber
  // i samme by ikke legger seg eksakt oppå hverandre på kartet.
  final Random _random = Random();

  String? category;
  String? location;

  List<XFile> images = [];
  int currentIndex = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _priceValue => int.tryParse(_price.text.trim()) ?? 0;
  double get _feeValue => _priceValue * 0.10;
  double get _totalValue => _priceValue + _feeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legg ut oppdrag')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imagePicker(),
            _field(_title, 'Tittel'),
            _field(_desc, 'Beskrivelse', maxLines: 4),
            _field(
              _price,
              'Pris',
              number: true,
              onChanged: (_) => setState(() {}),
            ),
            if (_priceValue > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oppdragssum til utfører: $_priceValue kr',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plattformavgift: ${_feeValue.toStringAsFixed(0)} kr inkl. mva',
                      style: const TextStyle(
                        color: Color(0xFF6E7A90),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Totalt å betale: ${_totalValue.toStringAsFixed(0)} kr',
                      style: const TextStyle(
                        color: Color(0xFF2356E8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _dropdown(
              kCategories,
              category,
              'Kategori',
              (v) => setState(() => category = v),
            ),
            _dropdown(
              kLocations,
              location,
              'Sted',
              (v) => setState(() => location = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: images.isEmpty
                ? const Center(child: Text('Velg bilder'))
                : const Center(child: Text('Endre bilder')),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => currentIndex = i),
                  itemBuilder: (_, index) {
                    final img = images[index];

                    return FutureBuilder(
                      future: img.readAsBytes(),
                      builder: (_, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Image.memory(
                          snap.data!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: currentIndex > 0
                        ? () => _controller.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            )
                        : null,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onPressed: currentIndex < images.length - 1
                        ? () => _controller.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.black54,
                    child: Text(
                      '${currentIndex + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );

        if (result != null) {
          setState(() {
            images = result.files
                .where((f) => f.bytes != null)
                .take(5)
                .map((f) => XFile.fromData(f.bytes!, name: f.name))
                .toList();
            currentIndex = 0;
          });
        }
      } else {
        final picked = await ImagePicker().pickMultiImage();
        setState(() {
          images = picked.take(5).toList();
          currentIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (category == null || location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg kategori og sted')),
      );
      return;
    }

    final parsedPrice = int.tryParse(_price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pris må være et gyldig tall')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = context.read<AppState>();
      final supabase = SupabaseService();

      // 1) Last opp bilder til storage først. Hvis en enkelt opplastning
      // feiler, logger vi og går videre – vi blokkerer ikke publisering.
      final urls = <String>[];

      for (final img in images) {
        try {
          final bytes = await img.readAsBytes();

          final url = await supabase.uploadJobImage(
            bytes: bytes,
            originalFileName: img.name,
          );

          if (url != null) urls.add(url);
        } catch (e) {
          debugPrint('Upload error: $e');
        }
      }

      // 2) Beregn lat/lng med jitter slik at flere oppdrag i samme by ikke
      // legger seg eksakt oppå hverandre på kartet. Ca ±0.0025° ≈ ±275 m.
      final baseLat = _latForLocation(location!);
      final baseLng = _lngForLocation(location!);
      final jitteredLat = baseLat + _jitterDegrees();
      final jitteredLng = baseLng + _jitterDegrees();

      // 3) Lag jobb i Supabase via AppState. addJob returnerer true/false
      // slik at vi kan gi brukeren korrekt tilbakemelding.
      final ok = await appState.addJob(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: parsedPrice,
        locationName: location!,
        lat: jitteredLat,
        lng: jitteredLng,
        category: category!,
        imageUrl: urls.isNotEmpty ? urls.first : null,
        imageUrls: urls,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kunne ikke lagre oppdraget på server. Prøv igjen.',
            ),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // 4) Synk liste fra server for å få kanonisk state (inkl. server-id og
      // ev. defaults satt av DB).
      await appState.reloadJobs();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oppdrag publisert')),
      );

      _title.clear();
      _desc.clear();
      _price.clear();

      setState(() {
        images = [];
        category = null;
        location = null;
        currentIndex = 0;
      });
    } catch (e, stack) {
      debugPrint('Submit error: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Noe gikk galt under publisering')),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  /// Tilfeldig forskyvning i ca ±0.0025° (~275 m). Brukes for å hindre at
  /// markører i samme by havner eksakt oppå hverandre på kartet.
  double _jitterDegrees() {
    const spread = 0.005; // total bredde ≈ 550 m
    return (_random.nextDouble() - 0.5) * spread;
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool number = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: (v) =>
            (v == null || v.isEmpty) ? '$hint må fylles ut' : null,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  Widget _dropdown(
    List<String> list,
    String? value,
    String label,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: list
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? '$label må velges' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  double _latForLocation(String locationName) {
    switch (locationName) {
      case 'Skien':
        return 59.2096;
      case 'Porsgrunn':
        return 59.1419;
      case 'Bamble':
        return 59.0197;
      case 'Stathelle':
        return 59.0456;
      default:
        return 59.14;
    }
  }

  double _lngForLocation(String locationName) {
    switch (locationName) {
      case 'Skien':
        return 9.6089;
      case 'Porsgrunn':
        return 9.6561;
      case 'Bamble':
        return 9.5600;
      case 'Stathelle':
        return 9.6910;
      default:
        return 9.65;
    }
  }
}
