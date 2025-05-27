import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Tambahkan ini untuk mendapatkan nama file utama
import 'bpjs_upload_service.dart';

class BPJSKaryawanPage extends StatefulWidget {
  const BPJSKaryawanPage({super.key});

  @override
  State<BPJSKaryawanPage> createState() => _BPJSKaryawanPageState();
}

class _BPJSKaryawanPageState extends State<BPJSKaryawanPage> {
  int? idEmployee;
  Map<String, File?> selectedImages =
      {}; // Menyimpan gambar yang dipilih berdasarkan fieldName
  String? selectedAnakKe; // Ubah tipe data menjadi String

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  void _loadEmployeeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
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

  void _showPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Dialog tidak bisa ditutup dengan klik di luar
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> uploadBpjsWithArray({
    required BuildContext context,
    required String anggotaBpjs,
    required List<Map<String, dynamic>> documents,
    String? anakKe,
  }) async {
    if (idEmployee == null) {
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'ID karyawan belum tersedia.',
      );
      return;
    }

    List<File> files = [];
    List<String> fieldNames = [];

    // Konversi dokumen ke arrays untuk upload
    for (var doc in documents) {
      if (doc['file'] != null) {
        files.add(doc['file'] as File);
        fieldNames.add(doc['fieldName'] as String);
      }
    }

    if (files.isEmpty) {
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'Pilih minimal satu dokumen untuk diunggah.',
      );
      return;
    }

    if (files.length != fieldNames.length) {
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'Jumlah file dan tipe file tidak sesuai.',
      );
      return;
    }

    showLoadingDialog(context);

    try {
      await uploadBpjsDocumentsCompressed(
        idEmployee: idEmployee!,
        anggotaBpjs: anggotaBpjs,
        fieldNames: fieldNames,
        files: files,
        anakKe: anakKe,
      );

      Navigator.of(context).pop();
      _showPopup(
        context: context,
        title: 'Berhasil',
        message:
            'Dokumen BPJS ${anggotaBpjs == "Pasangan" ? "Istri" : "Anak"} berhasil diunggah.',
      );

      // Jeda 2 detik sebelum cek BPJS terbaru
      await Future.delayed(const Duration(seconds: 2));

      // Ambil data employee dari API
      final empResponse = await Dio().get(
        'http://103.31.235.237:5555/api/Employees',
        queryParameters: {'id': idEmployee},
      );
      int? idSection;
      if (empResponse.statusCode == 200 &&
          empResponse.data is List &&
          empResponse.data.isNotEmpty) {
        final employee = empResponse.data.firstWhere(
          (e) => e['Id'] == idEmployee,
          orElse: () => null,
        );
        if (employee != null) {
          idSection = employee['IdSection'];
        }
      }

      // Ambil BPJS terbaru sesuai IdSection
      int? latestBpjsId;
      if (idSection != null) {
        final bpjsResponse = await Dio().get(
          'http://103.31.235.237:5555/api/Bpjs',
          queryParameters: {'idSection': idSection},
        );
        if (bpjsResponse.statusCode == 200 &&
            bpjsResponse.data is List &&
            bpjsResponse.data.isNotEmpty) {
          final latestEntry = bpjsResponse.data.last;
          latestBpjsId = latestEntry['Id'];
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      print("❌ Error saat mengunggah dokumen: $e");
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'Terjadi kesalahan saat mengunggah dokumen.',
      );
    }
  }

  Future<void> uploadBpjsDocuments({
    required BuildContext context,
    required String anggotaBpjs,
    required List<Map<String, dynamic>> documents,
    String? anakKe,
  }) async {
    if (idEmployee == null) {
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'ID karyawan belum tersedia.',
      );
      return;
    }

    if (documents.isEmpty) {
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'Pilih minimal satu dokumen untuk diunggah.',
      );
      return;
    }

    showLoadingDialog(context);

    try {
      // Ambil data dari API untuk mendapatkan ID yang sesuai
      final response = await Dio().get(
        'http://103.31.235.237:5555/api/Bpjs',
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

        if (matchingEntry == null) {
          throw Exception(
              'Data untuk ID Employee dan kategori BPJS tidak ditemukan.');
        }

        final matchingId = matchingEntry['Id']; // Ambil ID yang sesuai

        // Siapkan data untuk dikirim ke API
        final formData = FormData.fromMap({
          for (var doc in documents)
            doc['fieldName']: await MultipartFile.fromFile(
              (doc['file'] as File).path,
              filename: basename((doc['file'] as File).path),
            ),
        });

        // Kirim data ke API dengan endpoint dinamis
        final uploadResponse = await Dio().put(
          'http://103.31.235.237:5555/api/Bpjs/upload/$matchingId',
          data: formData,
        );

        if (uploadResponse.statusCode == 200) {
          Navigator.of(context).pop();
          _showPopup(
            context: context,
            title: 'Berhasil',
            message: 'Dokumen BPJS berhasil diunggah.',
          );

          // Jeda 2 detik sebelum cek BPJS terbaru
          await Future.delayed(const Duration(seconds: 2));

          // Ambil data employee dari API
          final empResponse = await Dio().get(
            'http://103.31.235.237:5555/api/Employees',
            queryParameters: {'id': idEmployee},
          );
          int? idSection;
          if (empResponse.statusCode == 200 &&
              empResponse.data is List &&
              empResponse.data.isNotEmpty) {
            final employee = empResponse.data.firstWhere(
              (e) => e['Id'] == idEmployee,
              orElse: () => null,
            );
            if (employee != null) {
              idSection = employee['IdSection'];
            }
          }

          // Ambil BPJS terbaru sesuai IdSection
          int? latestBpjsId;
          if (idSection != null) {
            final bpjsResponse = await Dio().get(
              'http://103.31.235.237:5555/api/Bpjs',
              queryParameters: {'idSection': idSection},
            );
            if (bpjsResponse.statusCode == 200 &&
                bpjsResponse.data is List &&
                bpjsResponse.data.isNotEmpty) {
              final latestEntry = bpjsResponse.data.last;
              latestBpjsId = latestEntry['Id'];
            }
          }
        } else {
          throw Exception(
              'Gagal memperbarui data: ${uploadResponse.statusCode}');
        }
      } else {
        throw Exception('Gagal memuat data dari API.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Tutup loading dialog
      print("❌ Error saat mengunggah dokumen: $e");
      _showPopup(
        context: context,
        title: 'Gagal',
        message: 'Terjadi kesalahan saat mengunggah dokumen.',
      );
    }
  }

  Widget _buildBox({
    required String title,
    required String fieldName,
    required String anggotaBpjs,
  }) {
    return GestureDetector(
      onTap: () => pickImage(fieldName: fieldName),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                        ? basename(
                            selectedImages[fieldName]!.path) // Hanya nama file
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
    );
  }

  Widget _buildUploadButton({
    required String title,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1572E8), // Warna tombol
        minimumSize: const Size(double.infinity, 50), // Lebar penuh
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Sudut melengkung
        ),
        elevation: 4, // Bayangan tombol
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
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
            const Icon(Icons.picture_as_pdf,
                size: 40, color: Colors.red), // Ikon PDF
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          'BPJS Karyawan',
          style: TextStyle(
            color: Colors.white, // Judul header warna putih
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // Tombol back warna putih
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MenuPage(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi BPJS Karyawan
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        ),
                        child: const Icon(
                          Icons.info,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Informasi BPJS Karyawan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Halaman ini digunakan untuk mengunggah dokumen yang diperlukan untuk pengelolaan BPJS Pasangan dan BPJS Anak.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // BPJS Istri Section
              _buildSection(
                title: 'BPJS Pasanagan',
                children: [
                  _buildBox(
                    title: 'Upload KK',
                    fieldName: 'UrlKk',
                    anggotaBpjs: 'Pasangan',
                  ),
                  const SizedBox(height: 16),
                  _buildBox(
                    title: 'Upload Surat Nikah',
                    fieldName: 'UrlSuratNikah',
                    anggotaBpjs: 'Pasangan',
                  ),
                  const SizedBox(height: 16),
                  _buildUploadButton(
                    title: 'Kirim Dokumen BPJS Pasangan',
                    icon: Icons.upload_file,
                    onPressed: () async {
                      // Validasi dan pengunggahan dokumen
                      if (selectedImages['UrlKk'] == null ||
                          selectedImages['UrlSuratNikah'] == null) {
                        _showPopup(
                          context: context,
                          title: 'Gagal',
                          message: 'Anda harus mengunggah KK dan Surat Nikah.',
                        );
                        return;
                      }

                      final List<Map<String, dynamic>> documents = [
                        {
                          'fieldName': 'UrlKk',
                          'file': selectedImages['UrlKk'],
                        },
                        {
                          'fieldName': 'UrlSuratNikah',
                          'file': selectedImages['UrlSuratNikah'],
                        },
                      ];

                      try {
                        await uploadBpjsWithArray(
                          context: context,
                          anggotaBpjs: 'Pasangan',
                          documents: documents,
                        );
                      } catch (e) {
                        print("❌ Error saat mengunggah dokumen: $e");
                        _showPopup(
                          context: context,
                          title: 'Gagal',
                          message: 'Terjadi kesalahan saat mengunggah dokumen.',
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // BPJS Anak Section
              _buildSection(
                title: 'BPJS Anak', // Ganti judul section di sini
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAnakKe,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Pilih Anak Ke-'),
                        ),
                        isExpanded: true,
                        // Hanya anak ke 1-3
                        items:
                            List.generate(3, (index) => (index + 1).toString())
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text('Anak ke-$e'),
                                      ),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAnakKe = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Note: "Untuk anak ke 4 sampai seterusnya di halaman BPJS Tambahan"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildBox(
                    title: 'Upload KK',
                    fieldName: 'UrlKkAnak',
                    anggotaBpjs: 'Anak',
                  ),
                  const SizedBox(height: 16),
                  _buildBox(
                    title: 'Upload Surat Keterangan Lahir',
                    fieldName: 'UrlAkteLahir',
                    anggotaBpjs: 'Anak',
                  ),
                  const SizedBox(height: 16),
                  _buildUploadButton(
                    title: 'Kirim Dokumen BPJS Anak',
                    icon: Icons.upload_file,
                    onPressed: () async {
                      // Validasi dan pengunggahan dokumen
                      if (selectedAnakKe == null) {
                        _showPopup(
                          context: context,
                          title: 'Gagal',
                          message: 'Pilih Anak Ke berapa terlebih dahulu.',
                        );
                        return;
                      }

                      if (selectedImages['UrlKkAnak'] == null ||
                          selectedImages['UrlAkteLahir'] == null) {
                        _showPopup(
                          context: context,
                          title: 'Gagal',
                          message: 'Anda harus mengunggah KK dan Akta Lahir.',
                        );
                        return;
                      }

                      final List<Map<String, dynamic>> documents = [
                        {
                          'fieldName': 'UrlKk',
                          'file': selectedImages['UrlKkAnak'],
                        },
                        {
                          'fieldName': 'UrlAkteLahir',
                          'file': selectedImages['UrlAkteLahir'],
                        },
                      ];

                      try {
                        await uploadBpjsWithArray(
                          context: context,
                          anggotaBpjs: 'Anak',
                          documents: documents,
                          anakKe: selectedAnakKe,
                        );
                      } catch (e) {
                        print("❌ Error saat mengunggah dokumen: $e");
                        _showPopup(
                          context: context,
                          title: 'Gagal',
                          message: 'Terjadi kesalahan saat mengunggah dokumen.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
