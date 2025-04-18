import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'bpjs_upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BPJSKaryawanPage extends StatefulWidget {
  const BPJSKaryawanPage({super.key});

  @override
  State<BPJSKaryawanPage> createState() => _BPJSKaryawanPageState();
}

class _BPJSKaryawanPageState extends State<BPJSKaryawanPage> {
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

  Future<void> pickAndUploadImage({
    required BuildContext context,
    required int idEmployee,
    required String anggotaBpjs,
    required String fieldName,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final response = await uploadBpjsDocument(
          idEmployee: idEmployee,
          anggotaBpjs: anggotaBpjs,
          fieldName: fieldName,
          file: File(pickedFile.path),
        );

        // Show success popup
        _showPopup(
          context: context,
          title: 'Upload Berhasil',
          message: 'Dokumen berhasil diunggah.',
        );
      } catch (e) {
        // Show failure popup
        _showPopup(
          context: context,
          title: 'Upload Gagal',
          message: 'Terjadi kesalahan saat mengunggah dokumen:\n$e',
        );
      }
    }
  }

  void _showPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1572E8)),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BPJS Istri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      _buildBox(
                        title: 'Upload KK',
                        color: const Color(0xFF1572E8),
                        onTap: () {
                          if (idEmployee != null) {
                            pickAndUploadImage(
                              context: context,
                              idEmployee: idEmployee!,
                              anggotaBpjs: "Istri",
                              fieldName: "urlKk",
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ID karyawan belum tersedia"),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildBox(
                        title: 'Upload Surat Nikah',
                        color: const Color(0xFF1572E8),
                        onTap: () {
                          if (idEmployee != null) {
                            pickAndUploadImage(
                              context: context,
                              idEmployee: idEmployee!,
                              anggotaBpjs: "Istri",
                              fieldName: "urlSuratNikah",
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ID karyawan belum tersedia"),
                              ),
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
                  'BPJS Anak > 21 Tahun Masih Kuliah',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildBox(
                      title: 'Upload KK',
                      color: const Color(0xFF1572E8),
                      onTap: () {
                        if (idEmployee != null) {
                          pickAndUploadImage(
                            context: context,
                            idEmployee: idEmployee!,
                            anggotaBpjs: "Anak",
                            fieldName: "urlKk",
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ID karyawan belum tersedia"),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    _buildBox(
                      title: 'Upload Surat Keterangan Lahir',
                      color: const Color(0xFF1572E8),
                      onTap: () {
                        if (idEmployee != null) {
                          pickAndUploadImage(
                            context: context,
                            idEmployee: idEmployee!,
                            anggotaBpjs: "Anak",
                            fieldName: "urlAktekLahir",
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ID karyawan belum tersedia"),
                            ),
                          );
                        }
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
