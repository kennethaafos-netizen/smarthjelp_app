import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../models/job.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

class PostJobScreen extends StatefulWidget {
  final Job? existingJob;
  const PostJobScreen({super.key, this.existingJob});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _postcode = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PageController _controller = PageController();

  String? category;
  List<XFile> images = [];
  int currentIndex = 0;
  bool _isSubmitting = false;
  String? _editKommune;

  bool get _isEditing => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    final job = widget.existingJob;
    if (job != null) {
      _title.text = job.title;
      _desc.text = job.description;
      _price.text = job.price.toString();
      category = job.category;
      _editKommune = kLocations.contains(job.locationName) ? job.locationName : kLocations.first;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _postcode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _kommuneForPostcode(String raw) {
    final p = int.tryParse(raw.trim());
    if (p == null) return null;
    if (p >= 3700 && p <= 3747) return 'Skien';
    if (p >= 3748 && p <= 3749) return 'Siljan';
    if (p >= 3900 && p <= 3949) return 'Porsgrunn';
    if (p >= 3950 && p <= 3999) return 'Bamble';
    return null;
  }

  String? get _derivedKommune => _kommuneForPostcode(_postcode.text);

  int get _priceValue => int.tryParse(_price.text.trim()) ?? 0;
  double get _feeValue => _priceValue * 0.10;
  double get _totalValue => _priceValue + _feeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Rediger oppdrag' : 'Legg ut oppdrag')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 140),
          children: [
            if (!_isEditing) _imagePicker(),
            _field(_title, 'Tittel'),
            _field(_desc, 'Beskrivelse', maxLines: 4),
            _field(_price, 'Pris til oppdragstaker (kr)', number: true, onChanged: (_) => setState(() {})),
            if (_priceValue > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E9F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Til oppdragstaker: $_priceValue kr',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F1E3A))),
                    const SizedBox(height: 6),
                    Text('Plattformavgift: ${_feeValue.toStringAsFixed(0)} kr inkl. mva',
                        style: const TextStyle(color: Color(0xFF6E7A90), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Du betaler totalt: ${_totalValue.toStringAsFixed(0)} kr',
                        style: const TextStyle(color: Color(0xFF2356E8), fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Beløpet holdes trygt av SmartHjelp til du godkjenner fullført jobb.',
                        style: TextStyle(color: Color(0xFF0EA877), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            _dropdown(kCategories, category, 'Kategori', (v) => setState(() => category = v)),
            if (_isEditing)
              _dropdown(kLocations, _editKommune, 'Kommune', (v) => setState(() => _editKommune = v))
            else
              _postcodeField(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Lagre endringer' : 'Publiser'),
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
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
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
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity);
                      },
                    );
                  },
                ),
                Positioned(
                  left: 10, top: 0, bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: currentIndex > 0
                        ? () => _controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.ease)
                        : null,
                  ),
                ),
                Positioned(
                  right: 10, top: 0, bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onPressed: currentIndex < images.length - 1
                        ? () => _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.ease)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black54,
                    child: Text('${currentIndex + 1}/${images.length}', style: const TextStyle(color: Colors.white)),
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
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
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
        setState(() { images = picked.take(5).toList(); currentIndex = 0; });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (category == null) return;

    final String kommune;
    if (_isEditing) {
      if (_editKommune == null) return;
      kommune = _editKommune!;
    } else {
      final derived = _derivedKommune;
      if (derived == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Postnummeret er ikke i SmartHjelp sitt dekningsområde (Skien, Porsgrunn, Siljan, Bamble).'),
        ));
        return;
      }
      kommune = derived;
    }

    final parsedPrice = int.tryParse(_price.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pris må være et gyldig tall')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = context.read<AppState>();
      if (_isEditing) {
        final ok = await appState.updateOwnJob(
          jobId: widget.existingJob!.id,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          price: parsedPrice,
          category: category!,
          locationName: kommune,
          lat: _latForLocation(kommune),
          lng: _lngForLocation(kommune),
        );
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oppdrag oppdatert')));
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunne ikke oppdatere oppdraget.')));
        }
      } else {
        final supabase = SupabaseService();
        final urls = <String>[];
        final localFallbacks = <String>[];

        for (final img in images) {
          try {
            final bytes = await img.readAsBytes();
            final url = await supabase.uploadJobImage(bytes: bytes, originalFileName: img.name);
            if (url != null) {
              urls.add(url);
            } else if (!kIsWeb && img.path.isNotEmpty) {
              localFallbacks.add(img.path);
            }
          } catch (e) {
            debugPrint('Upload error: $e');
            if (!kIsWeb && img.path.isNotEmpty) localFallbacks.add(img.path);
          }
        }

        final allUrls = [...urls, ...localFallbacks];
        final ok = await appState.addJob(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          price: parsedPrice,
          locationName: kommune,
          lat: _latForLocation(kommune),
          lng: _lngForLocation(kommune),
          category: category!,
          imageUrl: allUrls.isNotEmpty ? allUrls.first : null,
          imageUrls: allUrls,
        );

        if (ok) await appState.reloadJobs();
        if (!mounted) return;

        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kunne ikke lagre oppdraget i Supabase. Sjekk tilkobling / innlogging.'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oppdrag publisert')));
          _title.clear(); _desc.clear(); _price.clear(); _postcode.clear();
          setState(() { images = []; category = null; currentIndex = 0; });
        }
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Noe gikk galt under publisering')));
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool number = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    // FASE 3 FIX: multiline felt skal gi newline når brukeren trykker Enter,
    // ikke submit. Dette krever TextInputType.multiline + newline-action.
    final isMultiline = maxLines > 1;
    final keyboard = number
        ? TextInputType.number
        : (isMultiline ? TextInputType.multiline : TextInputType.text);
    final action = isMultiline ? TextInputAction.newline : TextInputAction.next;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        textInputAction: action,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? '$hint må fylles ut' : null,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  Widget _postcodeField() {
    final kommune = _derivedKommune;
    final hasInput = _postcode.text.trim().isNotEmpty;
    final isValid = kommune != null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _postcode,
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Postnummer må fylles ut';
              if (_kommuneForPostcode(v) == null) return 'Postnummeret er utenfor dekningsområdet';
              return null;
            },
            decoration: const InputDecoration(hintText: 'Postnummer (f.eks. 3717)', counterText: ''),
          ),
          if (hasInput)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                isValid ? 'Kommune: $kommune' : 'Utenfor dekningsområdet (Skien, Porsgrunn, Siljan, Bamble)',
                style: TextStyle(
                  color: isValid ? const Color(0xFF0EA877) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> list, String? value, String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? '$label må velges' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  double _latForLocation(String locationName) {
    final key = locationName.trim().toLowerCase();
    if (key.contains('skien')) return 59.2096;
    if (key.contains('porsgrunn')) return 59.1419;
    if (key.contains('siljan')) return 59.3024;
    if (key.contains('langesund')) return 59.0000;
    if (key.contains('stathelle')) return 59.0456;
    if (key.contains('bamble')) return 59.0197;
    return 59.14;
  }

  double _lngForLocation(String locationName) {
    final key = locationName.trim().toLowerCase();
    if (key.contains('skien')) return 9.6089;
    if (key.contains('porsgrunn')) return 9.6561;
    if (key.contains('siljan')) return 9.7181;
    if (key.contains('langesund')) return 9.7500;
    if (key.contains('stathelle')) return 9.6910;
    if (key.contains('bamble')) return 9.5600;
    return 9.65;
  }
}
