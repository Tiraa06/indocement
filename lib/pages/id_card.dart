import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart'
    as path; // Menggunakan alias untuk menghindari konflik
import 'package:mime/mime.dart';

class IdCardUploadPage extends StatefulWidget {
  const IdCardUploadPage({Key? key}) : super(key: key);

  @override
  State<IdCardUploadPage> createState() => _IdCardUploadPageState();
}

class _IdCardUploadPageState extends State<IdCardUploadPage> {
  String _selectedStatus = 'Baru';
  final int idEmployee = 3;

  File? fotoBaru;
  File? fotoRusak;
  File? suratKehilangan;

  final picker = ImagePicker();
  bool isLoading = false;

  Future<void> pickImage(Function(File) onPicked) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final mimeType = lookupMimeType(picked.path);
      if (mimeType != 'image/png' && mimeType != 'image/jpeg') {
        showDialog(
          context: context, // BuildContext dari build method
          builder: (dialogContext) => AlertDialog(
            title: const Text('Format Tidak Didukung'),
            content: const Text('Hanya file PNG atau JPG yang diperbolehkan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      onPicked(File(picked.path));
    }
  }

  Future<void> submitForm(BuildContext dialogContext) async {
    // Validasi
    if (fotoBaru == null) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Validasi Gagal'),
          content: const Text('Mohon upload foto terbaru.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_selectedStatus == 'Rusak' && fotoRusak == null) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Validasi Gagal'),
          content: const Text('Mohon upload foto ID card rusak.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_selectedStatus == 'Hilang' && suratKehilangan == null) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Validasi Gagal'),
          content: const Text('Mohon upload surat kehilangan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    var uri = Uri.parse('http://213.35.123.110:5555/api/IdCards/upload');
    var request = http.MultipartRequest('POST', uri);
    request.headers['accept'] = 'text/plain';

    request.fields['IdEmployee'] = idEmployee.toString();
    request.fields['StatusPengajuan'] = _selectedStatus;

    final fotoBaruMimeType = lookupMimeType(fotoBaru!.path) ?? 'image/png';
    final fotoBaruMimeTypeData = fotoBaruMimeType.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'UrlFotoTerbaru',
      fotoBaru!.path,
      contentType: MediaType(fotoBaruMimeTypeData[0], fotoBaruMimeTypeData[1]),
    ));

    if (_selectedStatus == 'Rusak' && fotoRusak != null) {
      final fotoRusakMimeType = lookupMimeType(fotoRusak!.path) ?? 'image/png';
      final fotoRusakMimeTypeData = fotoRusakMimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'UrlCardRusak',
        fotoRusak!.path,
        contentType:
            MediaType(fotoRusakMimeTypeData[0], fotoRusakMimeTypeData[1]),
      ));
    }

    if (_selectedStatus == 'Hilang' && suratKehilangan != null) {
      final suratMimeType =
          lookupMimeType(suratKehilangan!.path) ?? 'image/png';
      final suratMimeTypeData = suratMimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'UrlSuratKehilangan',
        suratKehilangan!.path,
        contentType: MediaType(suratMimeTypeData[0], suratMimeTypeData[1]),
      ));
    }

    try {
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => f.filename).toList()}');
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: dialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Pengajuan Berhasil'),
            content:
                const Text('Pengajuan ID Card Anda telah berhasil disubmit.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    fotoBaru = null;
                    fotoRusak = null;
                    suratKehilangan = null;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: dialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Pengajuan Gagal'),
            content: Text(
              'Gagal mengajukan ID Card: [${response.statusCode}] $responseBody',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Koneksi Gagal'),
          content: Text('Gagal terhubung ke server: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildUploadSection(String label, File? file, Function(File) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => pickImage(onPicked),
              icon: const Icon(Icons.upload_file),
              label: Text(file == null ? 'Pilih Gambar' : 'Ganti'),
            ),
            const SizedBox(width: 12),
            if (file != null)
              Expanded(
                child: Text(
                  path.basename(file.path), // Menggunakan path.basename
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan ID Card'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner / Header
            // Banner / Header
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/banner_id.png',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Form Pengajuan ID Card",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status
                  const Text("Status Pengajuan",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Baru', 'Rusak', 'Hilang']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 24),

                  // Upload Foto
                  buildUploadSection('Foto Terbaru', fotoBaru,
                      (f) => setState(() => fotoBaru = f)),
                  if (_selectedStatus == 'Rusak')
                    buildUploadSection('Foto ID Card Rusak', fotoRusak,
                        (f) => setState(() => fotoRusak = f)),
                  if (_selectedStatus == 'Hilang')
                    buildUploadSection('Surat Kehilangan', suratKehilangan,
                        (f) => setState(() => suratKehilangan = f)),

                  // Tombol Submit
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (BuildContext buttonContext) {
                        return ElevatedButton.icon(
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              : const Icon(Icons.send),
                          label: isLoading
                              ? const Text('Mengirim...')
                              : const Text('Ajukan Sekarang'),
                          onPressed: isLoading
                              ? null
                              : () => submitForm(buttonContext),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue[700],
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
