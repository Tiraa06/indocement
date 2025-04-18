import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'bpjs_upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BPJSTambahanPage extends StatefulWidget {
  const BPJSTambahanPage({super.key});

  @override
  State<BPJSTambahanPage> createState() => _BPJSKaryawanPageState();
}

class _BPJSKaryawanPageState extends State<BPJSTambahanPage> {
  int? idEmployee;

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

Future<void> pickAndCropImage({
  required BuildContext context,
  required int idEmployee,
  required String anggotaBpjs,
  required String fieldName,
}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File? cropped = (await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF1572E8),
          toolbarWidgetColor: Colors.white,
        ),
      ],
    )) as File?;

    if (cropped != null) {
      try {
        final response = await uploadBpjsDocument(
          idEmployee: idEmployee,
          anggotaBpjs: anggotaBpjs,
          fieldName: fieldName,
          file: File(cropped.path),
        );

        // Tampilkan dialog sukses
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Berhasil'),
            content: const Text('Dokumen berhasil diunggah.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Tampilkan dialog gagal
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Gagal'),
            content: Text('Terjadi kesalahan saat mengunggah dokumen:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1572E8)),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Enable scrolling
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Header Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1572E8),
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
                            color: Colors.white.withOpacity(0.2),
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
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Halaman ini digunakan untuk mengunggah dokumen yang diperlukan untuk pengelolaan BPJS Karyawan.',
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
                  // Section 1: BPJS Istri
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1572E8,
                      ).withOpacity(0.1), // Background color
                      borderRadius: BorderRadius.circular(12), // Border radius
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bapak/Ibu Kandung/Mertua',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildBox(
                              title: 'Upload KK',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Tambahan",
                                  fieldName: "urlKk",
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Download Surat Pemotongan Gaji',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Tambahan",
                                  fieldName: "urlSuratNikah",
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Pemotongan Gaji',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Tambahan",
                                  fieldName: "urlSuratPemotonganGaji",
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section 2: BPJS Anak > 21 Tahun Masih Kuliah
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1572E8,
                      ).withOpacity(0.1), // Background color
                      borderRadius: BorderRadius.circular(12), // Border radius
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AnaK > Ke 3',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildBox(
                              title: 'Upload KK',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Anak",
                                  fieldName: "urlKk",
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Keterangan Lahir',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Anak",
                                  fieldName: "urlAkteLahir",
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Download Surat Pemotongan Gaji',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Anak",
                                  fieldName: "urlAkteLahir",
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Pemotongan Gaji',
                              color: const Color(0xFF1572E8),
                              onTap: () {
                                pickAndCropImage(
                                  context: context,
                                  idEmployee: idEmployee!, // Ganti ID sesuai user
                                  anggotaBpjs: "Anak",
                                  fieldName: "urlSuratPemotonganGaji",
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Add bottom spacing
                ],
              ),
            ),
          ),
          // Floating FAQ Button
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Handle FAQ button tap
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('FAQ'),
                        content: const Text(
                          'Frequently Asked Questions about BPJS Karyawan.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ), // Increased padding
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(
                    16,
                  ), // Slightly larger border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.help_outline,
                      size: 28,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ), // Larger icon
                    SizedBox(width: 10),
                    Text(
                      'FAQ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ), // Larger text
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: color,
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
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.file_upload,
                size: 30,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
