import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class KeluhanPage extends StatefulWidget {
  const KeluhanPage({super.key});

  @override
  _KeluhanPageState createState() => _KeluhanPageState();
}

class _KeluhanPageState extends State<KeluhanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  File? _selectedImage;

  List<Map<String, dynamic>> keluhanTerkirim = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keluhan Karyawan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: keluhanTerkirim.isEmpty
                  ? _buildForm()
                  : ListView.builder(
                      itemCount: keluhanTerkirim.length,
                      itemBuilder: (context, index) {
                        final keluhan = keluhanTerkirim[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  keluhan['judul'],
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(keluhan['deskripsi']),
                                const SizedBox(height: 12),
                                if (keluhan['foto'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(keluhan['foto']),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.person, size: 16),
                                        SizedBox(width: 4),
                                        Text("Anda"),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "Sedang diproses",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  keluhanTerkirim.clear();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("Kirim Keluhan Baru"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kirimkan keluhan Anda di bawah ini.",
                style:
                    GoogleFonts.roboto(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _judulController,
              decoration: InputDecoration(
                labelText: 'Judul Keluhan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi Keluhan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Deskripsi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            Text("Lampiran Foto (opsional):"),
            const SizedBox(height: 8),
            _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, height: 150))
                : Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child:
                        const Center(child: Text("Tidak ada gambar terpilih")),
                  ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Pilih Gambar"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _kirimKeluhan(_judulController.text,
                      _deskripsiController.text, _selectedImage);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Kirim Keluhan"),
            )
          ],
        ),
      ),
    );
  }

  void _kirimKeluhan(String judul, String deskripsi, File? fotoLampiran) {
    setState(() {
      keluhanTerkirim.add({
        'judul': judul,
        'deskripsi': deskripsi,
        'foto': fotoLampiran,
      });
      _judulController.clear();
      _deskripsiController.clear();
      _selectedImage = null;
    });
  }
}
