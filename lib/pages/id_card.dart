import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class IdCardUploadPage extends StatefulWidget {
  const IdCardUploadPage({super.key});

  @override
  State<IdCardUploadPage> createState() => _IdCardUploadPageState();
}

class _IdCardUploadPageState extends State<IdCardUploadPage> {
  String _selectedStatus = 'Baru';
  int? idEmployee;

  File? fotoBaru;
  File? fotoRusak;
  File? suratKehilangan;

  final picker = ImagePicker();
  bool isLoading = false;
  bool isDateFormattingInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      isDateFormattingInitialized = true;
    });
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
    if (idEmployee == null) {
      print('Error: idEmployee is null');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Gagal memuat ID karyawan. Silakan login ulang.'),
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

  Future<void> pickImage(Function(File) onPicked,
      {bool allowPdf = false}) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final mimeType = lookupMimeType(picked.path);
      if (allowPdf) {
        if (mimeType != 'image/png' &&
            mimeType != 'image/jpeg' &&
            mimeType != 'application/pdf') {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Format Tidak Didukung'),
              content: const Text(
                  'Hanya file PNG, JPG, atau PDF yang diperbolehkan.'),
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
      } else {
        if (mimeType != 'image/png' && mimeType != 'image/jpeg') {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Format Tidak Didukung'),
              content:
                  const Text('Hanya file PNG atau JPG yang diperbolehkan.'),
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
      }
      onPicked(File(picked.path));
    }
  }

  Future<void> submitForm(BuildContext dialogContext) async {
    if (idEmployee == null) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content:
              const Text('ID karyawan tidak ditemukan. Silakan login ulang.'),
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

    if (!isDateFormattingInitialized) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'Data format tanggal sedang diinisialisasi. Coba lagi sebentar.'),
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
          lookupMimeType(suratKehilangan!.path) ?? 'application/pdf';
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
        final responseData = jsonDecode(responseBody);
        final tglPengajuan = responseData['TglPengajuan'];
        String formattedDate = 'Tanggal tidak tersedia';
        if (tglPengajuan != null) {
          final dateTime = DateTime.parse(tglPengajuan).toLocal();
          formattedDate =
              DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(dateTime);
        }

        showDialog(
          context: dialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Pengajuan Berhasil'),
            content: Text(
              'Pengajuan ID Card Anda telah berhasil disubmit.\nTanggal Pengajuan: $formattedDate',
            ),
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

  Widget buildUploadSection(String label, File? file, Function(File) onPicked,
      {bool allowPdf = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => pickImage(onPicked, allowPdf: allowPdf),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1572E8),
                    borderRadius: BorderRadius.circular(8),
                    image: file != null
                        ? DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: file == null
                      ? const Icon(
                          Icons.upload_file,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        file != null
                            ? path.basename(file.path)
                            : 'Belum ada file yang dipilih',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                        (f) => setState(() => suratKehilangan = f),
                        allowPdf: true),

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
                            backgroundColor: const Color(0xFF1572E8),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Warna teks tetap putih
                            ),
                            foregroundColor: Colors.white, // Warna ikon default
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
