import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'bpjs_upload_service.dart';

class BPJSTambahanPage extends StatefulWidget {
  const BPJSTambahanPage({super.key});

  @override
  State<BPJSTambahanPage> createState() => _BPJSTambahanPageState();
}

class _BPJSTambahanPageState extends State<BPJSTambahanPage> {
  int? idEmployee;
  Map<String, File?> selectedImages = {}; // Menyimpan gambar yang dipilih berdasarkan fieldName
  String? selectedAnggotaBpjs; // Menyimpan pilihan dropdown
  bool _isPopupVisible = false; // Menyimpan status apakah popup sedang ditampilkan

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
    if (_isPopupVisible) return; // Jika popup sedang ditampilkan, jangan tampilkan lagi

    _isPopupVisible = true; // Tandai bahwa popup sedang ditampilkan
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                _isPopupVisible = false; // Reset status popup
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

  Future<void> uploadBpjsWithArray({
    required BuildContext context,
    required String anggotaBpjs,
    required List<Map<String, dynamic>> documents,
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
      );

      Navigator.of(context).pop();
      _showPopup(
        context: context,
        title: 'Berhasil',
        message: 'Dokumen BPJS berhasil diunggah.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1572E8)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi BPJS Tambahan
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
                            'Informasi BPJS Tambahan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Halaman ini digunakan untuk mengunggah dokumen tambahan untuk pengelolaan BPJS.',
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

              // BPJS Tambahan Section
              const Text(
                'BPJS Keluarga Tambahan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Dropdown untuk memilih anggota BPJS
              const Text(
                'Pilih Anggota BPJS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedAnggotaBpjs,
                hint: const Text('Pilih Anggota BPJS'),
                isExpanded: true,
                items: ['Ayah Kandung', 'Ibu Kandung', 'Ayah Mertua', 'Ibu Mertua']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAnggotaBpjs = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Kotak Upload Dokumen
              Column(
                children: [
                  _buildBox(
                    title: 'Upload KK',
                    fieldName: 'UrlKkTambahan',
                    anggotaBpjs: 'Tambahan',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Kirim Dokumen BPJS Tambahan
              ElevatedButton(
                onPressed: () async {
                  // Validasi: Pastikan dropdown dan dokumen diunggah
                  if (selectedAnggotaBpjs == null) {
                    _showPopup(
                      context: context,
                      title: 'Gagal',
                      message: 'Pilih anggota BPJS terlebih dahulu.',
                    );
                    return;
                  }

                  if (selectedImages['UrlKkTambahan'] == null) {
                    _showPopup(
                      context: context,
                      title: 'Gagal',
                      message: 'Anda harus mengunggah KK.',
                    );
                    return;
                  }

                  final List<Map<String, dynamic>> documents = [
                    {
                      'fieldName': 'UrlKk',
                      'file': selectedImages['UrlKkTambahan'],
                    },
                  ];

                  try {
                    await uploadBpjsWithArray(
                      context: context,
                      anggotaBpjs: selectedAnggotaBpjs!,
                      documents: documents,
                    );
                    _showPopup(
                      context: context,
                      title: 'Berhasil',
                      message: 'Dokumen BPJS berhasil diunggah.',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Kirim Dokumen BPJS Tambahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Gaji Section
              const Text(
                'Gaji',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Upload Surat Pemotongan Gaji
              _buildBox(
                title: 'Upload Surat Pemotongan Gaji',
                fieldName: 'UrlSuratPotongGaji',
                anggotaBpjs: 'Gaji',
              ),
              const SizedBox(height: 16),

              // Download Surat Pemotongan Gaji
              ElevatedButton.icon(
                onPressed: () {
                  _downloadSuratPotongGaji();
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Surat Pemotongan Gaji'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Kirim Dokumen Gaji
              ElevatedButton(
                onPressed: () async {
                  // Validasi: Pastikan dokumen diunggah
                  if (selectedImages['UrlSuratPotongGaji'] == null) {
                    _showPopup(
                      context: context,
                      title: 'Gagal',
                      message: 'Anda harus mengunggah Surat Pemotongan Gaji.',
                    );
                    return;
                  }

                  final List<Map<String, dynamic>> documents = [
                    {
                      'fieldName': 'UrlSuratPotongGaji',
                      'file': selectedImages['UrlSuratPotongGaji'],
                    },
                  ];

                  try {
                    await uploadBpjsWithArray(
                      context: context,
                      anggotaBpjs: 'Gaji',
                      documents: documents,
                    );
                    _showPopup(
                      context: context,
                      title: 'Berhasil',
                      message: 'Surat Pemotongan Gaji berhasil diunggah.',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Kirim Surat Pemotongan Gaji',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk mendownload surat pemotongan gaji
  void _downloadSuratPotongGaji() {
    // Tambahkan logika untuk mendownload file
    print("Download Surat Pemotongan Gaji");
  }
}
