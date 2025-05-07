import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
        'http://213.35.123.110:5555/api/Bpjs',
        queryParameters: {'idEmployee': idEmployee},
      );

      if (response.statusCode == 200) {
        print(response.data); // Log untuk memeriksa struktur data

        if (response.data is Map<String, dynamic>) {
          final data = response.data;
          setState(() {
            urlKk = data['UrlKk'];
            urlSuratNikah = data['UrlSuratNikah'];
          });
        } else if (response.data is List) {
          final List<dynamic> dataList = response.data;

          // Cari data berdasarkan idEmployee
          final data = dataList.firstWhere(
            (item) => item['IdEmployee'] == idEmployee,
            orElse: () => null,
          );

          if (data != null) {
            setState(() {
              urlKk = data['UrlKk'];
              urlSuratNikah = data['UrlSuratNikah'];
            });
          } else {
            throw Exception('Data untuk idEmployee tidak ditemukan.');
          }
        } else {
          throw Exception('Response API tidak sesuai format yang diharapkan.');
        }
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

  Future<void> uploadPasutriDocuments({
    required String anggotaBpjs,
    String? anakKe,
  }) async {
    if (idEmployee == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('ID karyawan belum tersedia.')),
      );
      return;
    }
  
    if (selectedImages['UrlKk'] == null && selectedImages['UrlAkteLahir'] == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Anda harus memilih file untuk diperbarui.')),
      );
      return;
    }
  
    try {
      setState(() {
        isLoading = true;
      });
  
      // Ambil data dari API untuk mendapatkan ID yang sesuai
      final response = await Dio().get(
        'http://213.35.123.110:5555/api/Bpjs',
        queryParameters: {'idEmployee': idEmployee},
      );
  
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
  
        // Cari ID yang sesuai dengan AnggotaBpjs dan AnakKe (jika ada)
        final matchingEntry = data.firstWhere(
          (item) =>
              item['IdEmployee'] == idEmployee &&
              item['AnggotaBpjs'] == anggotaBpjs &&
              (anakKe == null || item['AnakKe'] == anakKe),
          orElse: () => null,
        );
  
        int idToUse;
        if (matchingEntry != null) {
          idToUse = matchingEntry['Id']; // Gunakan ID yang ditemukan
        } else {
          // Jika tidak ditemukan, buat entri baru
          final createResponse = await Dio().post(
            'http://213.35.123.110:5555/api/Bpjs',
            data: {
              'IdEmployee': idEmployee,
              'AnggotaBpjs': anggotaBpjs,
              'AnakKe': anakKe,
            },
          );
  
          if (createResponse.statusCode == 201) {
            idToUse = createResponse.data['Id']; // Ambil ID dari entri baru
          } else {
            throw Exception('Gagal membuat entri baru: ${createResponse.statusCode}');
          }
        }
  
        // Siapkan data untuk dikirim ke API
        final formData = FormData.fromMap({
          if (selectedImages['UrlKk'] != null)
            'UrlKk': await MultipartFile.fromFile(
              selectedImages['UrlKk']!.path,
              filename: 'UrlKk_${idEmployee}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ),
          if (selectedImages['UrlAkteLahir'] != null)
            'UrlAkteLahir': await MultipartFile.fromFile(
              selectedImages['UrlAkteLahir']!.path,
              filename: 'UrlAkteLahir_${idEmployee}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ),
        });
  
        // Kirim data ke API dengan endpoint dinamis
        final uploadResponse = await Dio().put(
          'http://213.35.123.110:5555/api/Bpjs/upload/$idToUse',
          data: formData,
        );
  
        if (uploadResponse.statusCode == 200) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(content: Text('Data berhasil diperbarui!')),
          );
  
          // Refresh data setelah update
          await _fetchUploadedData();
        } else {
          throw Exception('Gagal memperbarui data: ${uploadResponse.statusCode}');
        }
      } else {
        throw Exception('Gagal memuat data dari API.');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black, // Border warna hitam
          width: 1, // Ketebalan border 1px
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
                    const Text(
                      'Data yang Telah Diunggah',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadedFileBox(urlKk, 'Kartu Keluarga'),
                    _buildUploadedFileBox(urlSuratNikah, 'Surat Nikah'),
                    const SizedBox(height: 24),
                    const Text(
                      'Perbarui Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Form Upload (Tidak Diubah)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black, // Border warna hitam
                          width: 1, // Ketebalan border 1px
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => pickImage(fieldName: 'UrlKk'),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pilih File Kartu Keluarga'),
                          ),
                          if (selectedImages['UrlKk'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                  'File KK: ${basename(selectedImages['UrlKk']!.path)}'),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => pickImage(fieldName: 'UrlSuratNikah'),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pilih File Surat Nikah'),
                          ),
                          if (selectedImages['UrlSuratNikah'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                  'File Surat Nikah: ${basename(selectedImages['UrlSuratNikah']!.path)}'),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => uploadPasutriDocuments(
                              anggotaBpjs: 'exampleAnggotaBpjs', // Replace with actual value
                              anakKe: 'exampleAnakKe', // Replace with actual value or null
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1572E8),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Perbarui Data',
                              style: TextStyle(color: Colors.white),
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