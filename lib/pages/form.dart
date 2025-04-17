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
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kirimkan keluhan Anda di bawah ini.",
                  style:
                      GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _judulController,
                  decoration: InputDecoration(
                    labelText: 'Judul Keluhan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Judul tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Keluhan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Deskripsi tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 20),

                // Upload Gambar (Opsional)
                Text("Lampiran Foto (opsional):", style: GoogleFonts.roboto()),
                const SizedBox(height: 8),
                if (_selectedImage != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Center(
                      child: Text("Tidak ada gambar terpilih"),
                    ),
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
                      _kirimKeluhan(
                        _judulController.text,
                        _deskripsiController.text,
                        _selectedImage,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE2328),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    "Kirim Keluhan",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

void _kirimKeluhan(String judul, String deskripsi, File? fotoLampiran) {
    // Reset form setelah pengiriman
    _judulController.clear();
    _deskripsiController.clear();
    setState(() {
      _selectedImage = null;
    });

    // Tampilkan modal konfirmasi dengan detail keluhan + info manajer
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Keluhan Terkirim'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Berikut detail keluhan Anda:"),
                const SizedBox(height: 10),

                // 📌 Judul Keluhan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.title, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        judul,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 📝 Deskripsi Keluhan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deskripsi,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),

                // 👨‍💼 Nama Manajer
                Row(
                  children: const [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text("Bapak Andi Prasetyo",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),

                // 🏢 Departemen
                Row(
                  children: const [
                    Icon(Icons.apartment, size: 20),
                    SizedBox(width: 8),
                    Text("Departemen Human Resources",
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Keluhan Anda berhasil dikirim.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}
