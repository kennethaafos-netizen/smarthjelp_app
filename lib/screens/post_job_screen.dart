import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/app_state.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();

  String? category;
  String? location;

  XFile? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Legg ut oppdrag")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _imagePicker(),
          _field(_title, "Tittel"),
          _field(_desc, "Beskrivelse"),
          _field(_price, "Pris", number: true),

          _dropdown(kCategories, category, "Kategori",
              (v) => setState(() => category = v)),

          _dropdown(kLocations, location, "Sted",
              (v) => setState(() => location = v)),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _submit,
            child: const Text("Publiser"),
          )
        ],
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: () async {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery);
        setState(() => image = img);
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: image == null
            ? const Center(child: Text("Velg bilde"))
            : Image.network(image!.path, fit: BoxFit.cover),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: c,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
      child: DropdownButtonFormField(
        initialValue: value,
        items: list
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _submit() {
    context.read<AppState>().addJob(
          title: _title.text,
          description: _desc.text,
          price: int.tryParse(_price.text) ?? 0,
          locationName: location ?? "Ukjent",
          lat: 59.9,
          lng: 10.7,
          category: category ?? "Annet",
          imageUrl: image?.path,
        );

    Navigator.pop(context);
  }
}