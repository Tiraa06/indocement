import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'bpjs_upload_service.dart';

class TambahDataAnakPage extends StatefulWidget {
  const TambahDataAnakPage({super.key});

  @override
  State<TambahDataAnakPage> createState() => _TambahDataAnakPageState();
}

class _TambahDataAnakPageState extends State<TambahDataAnakPage> {
  int? idEmployee;
  Map<String, File?> selectedImages = {}; // Menyimpan gambar yang dipilih berdasarkan fieldName

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
      barrierDismissible: false, // Dialog tidak bisa ditutup dengan klik di luar
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> uploadPasutriDocuments() async {
    if (idEmployee == null) {
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'ID karyawan belum tersedia.',
      );
      return;
    }

    if (selectedImages['UrlKk'] == null || selectedImages['UrlAkteLahir'] == null) {
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'Anda harus mengunggah KK dan Akte Kelahiran.',
      );
      return;
    }

    showLoadingDialog(this.context); // Gunakan context dari State

    try {
      // Upload KK
      await uploadBpjsDocumentCompressed(
        idEmployee: idEmployee!,
        anggotaBpjs: 'Anak',
        fieldName: 'UrlKk',
        file: selectedImages['UrlKk']!,
      );

      // Upload Surat Nikah
      await uploadBpjsDocumentCompressed(
        idEmployee: idEmployee!,
        anggotaBpjs: 'Anak',
        fieldName: 'UrlAkteLahir',
        file: selectedImages['UrlAkteLahir']!,
      );

      Navigator.of(this.context).pop(); // Tutup loading dialog
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Berhasil',
        message: 'Dokumen berhasil diunggah.',
      );
    } catch (e) {
      Navigator.of(this.context).pop(); // Tutup loading dialog
      print("❌ Error saat mengunggah dokumen: $e");
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'Terjadi kesalahan saat mengunggah dokumen.',
      );
    }
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
        message: 'Dokumen BPJS ${anggotaBpjs == "Anak" ? "Istri" : "Anak"} berhasil diunggah.',
      );
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

  Future<void> uploadAndUpdateDataAnak() async {
    if (idEmployee == null) {
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'ID karyawan belum tersedia.',
      );
      return;
    }

    if (selectedImages['UrlKkAnak'] == null || selectedImages['UrlAkteLahir'] == null) {
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'Anda harus mengunggah KK dan Akte Kelahiran.',
      );
      return;
    }

    showLoadingDialog(this.context); // Gunakan context dari State

    try {
      // Upload KK
      await uploadBpjsDocumentCompressed(
        idEmployee: idEmployee!,
        anggotaBpjs: 'Anak',
        fieldName: 'UrlKk',
        file: selectedImages['UrlKkAnak']!,
      );

      // Upload Akta Lahir
      await uploadBpjsDocumentCompressed(
        idEmployee: idEmployee!,
        anggotaBpjs: 'Anak',
        fieldName: 'UrlAkteLahir',
        file: selectedImages['UrlAkteLahir']!,
      );

      Navigator.of(this.context).pop(); // Tutup loading dialog
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Berhasil',
        message: 'Dokumen berhasil diunggah.',
      );
    } catch (e) {
      Navigator.of(this.context).pop(); // Tutup loading dialog
      print("❌ Error saat mengunggah dokumen: $e");
      _showPopup(
        context: this.context, // Gunakan context dari State
        title: 'Gagal',
        message: 'Terjadi kesalahan saat mengunggah dokumen.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Tombol back putih
          onPressed: () {
            Navigator.pop(context); // Navigasi kembali
          },
        ),
        elevation: 0, // Hilangkan bayangan AppBar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi BPJS Karyawan
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromARGB(255, 255, 255, 255), // Border warna putih
                          width: 1, // Ketebalan border 1px
                        ),
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
                            'Tambah Data Suami/Istri',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Halaman ini digunakan untuk mengunggah dokumen yang diperlukan untuk mengupload data suami/istri.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload KK
              _buildBox(
                title: 'Upload KK',
                fieldName: 'UrlKk',
              ),
              const SizedBox(height: 16),

              // Upload Surat Nikah
              _buildBox(
                title: 'Upload Akte Kelahiran',
                fieldName: 'UrlAkteLahir',
              ),
              const SizedBox(height: 24),

              // Tombol Kirim
              ElevatedButton(
                onPressed: uploadPasutriDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Kirim Dokumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
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
      child: Container(
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
    );
  }
}