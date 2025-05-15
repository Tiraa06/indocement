import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_karyawan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TambahDataPasutriPage extends StatefulWidget {
  const TambahDataPasutriPage({super.key});

  @override
  State<TambahDataPasutriPage> createState() => _TambahDataPasutriPageState();
}

class _TambahDataPasutriPageState extends State<TambahDataPasutriPage> {
  int? idEmployee;
  String? urlKk;
  String? urlSuratNikah;
  bool isLoading = false;
  Map<String, File?> selectedImages = {}; // Menyimpan gambar yang dipilih berdasarkan fieldName

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
    if (idEmployee != null) {
      _fetchUploadedData();
    }
  }

  Future<void> _fetchUploadedData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Dio().get(
        'http://192.168.100.140:5555/api/Bpjs',
        queryParameters: {'idEmployee': idEmployee},
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;

        // Cari data berdasarkan AnggotaBpjs = "Pasangan"
        final data = dataList.firstWhere(
          (item) => item['AnggotaBpjs'] == 'Pasangan',
          orElse: () => null,
        );

        if (data != null) {
          // Simpan data ke SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('Id', data['Id']);
          await prefs.setInt('IdEmployee', data['IdEmployee']);
          await prefs.setString('AnggotaBpjs', data['AnggotaBpjs']);

          setState(() {
            urlKk = data['UrlKk'];
            urlSuratNikah = data['UrlSuratNikah'];
          });
        } else {
          // Jika data tidak ditemukan, tampilkan popup
          _showUploadPrompt();
        }
      } else {
        throw Exception('Gagal memuat data dari API.');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage({
    required String fieldName,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImages[fieldName] = File(pickedFile.path);
      });
    }
  }

Future<void> uploadDokumenPasutriGanda() async {
  try {
    setState(() => isLoading = true);

    // Ambil data dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt('Id');
    final int? employeeId = prefs.getInt('IdEmployee');
    final String? anggotaBpjs = prefs.getString('AnggotaBpjs');

    if (id == null || employeeId == null || anggotaBpjs == null) {
      throw Exception('Data ID, IdEmployee, atau AnggotaBpjs tidak ditemukan.');
    }

    // Siapkan data untuk dikirim ke API
    final formData = FormData();

    // Tambahkan file UrlKk ke FormData
    if (selectedImages['UrlKk'] != null) {
      formData.files.add(
        MapEntry(
          'Files',
          await MultipartFile.fromFile(
            selectedImages['UrlKk']!.path,
            filename: basename(selectedImages['UrlKk']!.path),
          ),
        ),
      );
    }

    // Tambahkan file UrlSuratNikah ke FormData
    if (selectedImages['UrlSuratNikah'] != null) {
      formData.files.add(
        MapEntry(
          'Files',
          await MultipartFile.fromFile(
            selectedImages['UrlSuratNikah']!.path,
            filename: basename(selectedImages['UrlSuratNikah']!.path),
          ),
        ),
      );
    }

    // Tambahkan field tambahan ke FormData
    formData.fields.addAll([
      MapEntry('idEmployee', employeeId.toString()),
      MapEntry('FileTypes', 'UrlKk'),
      MapEntry('FileTypes', 'UrlSuratNikah'),
      MapEntry('AnggotaBpjs', anggotaBpjs),
    ]);

    // Kirim data ke API dengan metode PUT
    final uploadResponse = await Dio().put(
      'http://192.168.100.140:5555/api/Bpjs/upload/$id',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (uploadResponse.statusCode == 200) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('File berhasil diunggah.')),
      );
      await _fetchUploadedData(); // Refresh data setelah upload
    } else {
      throw Exception('Upload gagal: ${uploadResponse.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

void _showUploadPrompt() {
  showDialog(
    context: this.context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Membuat sudut membulat
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28), // Ikon peringatan
            SizedBox(width: 8),
            Text(
              'Data Belum Tersedia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Data KK dan Surat Nikah belum diunggah. Silakan unggah data terlebih dahulu di halaman BPJS Kesehatan.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup popup
              Navigator.pop(context); // Kembali ke halaman PCIR Page
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey, // Warna teks tombol
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup popup
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BPJSKaryawanPage(), // Ganti dengan halaman BPJS Kesehatan
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1572E8), // Warna tombol biru
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Membuat sudut membulat
              ),
            ),
            child: const Text(
              'Unggah Sekarang',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

  void _openPdfViewer(String url, String title) {
    Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(url: url, title: title),
      ),
    );
  }

  Widget _buildUploadedFileBox(String? url, String label) {
    if (url == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white, // Background card tetap putih
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red), // Ikon PDF
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    url.split('/').last,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox({
    required String title,
    required String fieldName,
  }) {
    return GestureDetector(
      onTap: () => pickImage(fieldName: fieldName),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white, // Background card tetap putih
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(8),
                  image: selectedImages[fieldName] != null
                      ? DecorationImage(
                          image: FileImage(selectedImages[fieldName]!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedImages[fieldName] == null
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedImages[fieldName] != null
                          ? basename(selectedImages[fieldName]!.path) // Hanya nama file
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Data BPJS'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data yang Telah Diunggah
                    const Text(
                      'Data yang Telah Diunggah',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadedFileBox(urlKk, 'Kartu Keluarga'),
                    _buildUploadedFileBox(urlSuratNikah, 'Surat Nikah'),
                    const SizedBox(height: 24),

                    // Perbarui Data
                    const Text(
                      'Perbarui Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Form Upload
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white, // Background card tetap putih
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Dokumen',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Kartu Keluarga',
                              fieldName: 'UrlKk',
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Nikah',
                              fieldName: 'UrlSuratNikah',
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                await uploadDokumenPasutriGanda();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1572E8),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Perbarui Data',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}