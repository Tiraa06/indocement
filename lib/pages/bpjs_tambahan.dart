import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String? selectedRelationship; // Menyimpan pilihan relationship
  bool _isPopupVisible = false; // Menyimpan status apakah popup sedang ditampilkan
  bool isDownloaded = false; // Menyimpan status apakah file sudah didownload
  bool isFormVisible = false; // Status untuk menampilkan form upload
  File? uploadedFile; // File yang diunggah

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

  Future<void> downloadFile() async {
    if (idEmployee == null) {
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'ID karyawan belum tersedia.',
      );
      return;
    }

    if (selectedRelationship == null) {
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'Pilih hubungan keluarga terlebih dahulu.',
      );
      return;
    }

    final dio = Dio();
    final String fileUrl =
        'http://213.35.123.110:5555/api/Bpjs/generate-salary-deduction/$idEmployee/$selectedRelationship';

    try {
      // Minta izin penyimpanan
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Izin penyimpanan tidak diberikan');
        }
      }

      // Tampilkan dialog loading
      showDialog(
        context: this.context,
        barrierDismissible: false, // Dialog tidak bisa ditutup dengan klik di luar
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading...'),
              ],
            ),
          );
        },
      );

      // Download file menggunakan Dio
      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Jika data kosong, tampilkan popup
      if (response.data == null || response.data.isEmpty) {
        Navigator.of(this.context).pop(); // Tutup dialog loading
        _showPopup(
          context: this.context,
          title: 'Download Gagal',
          message: 'Data keluarga anda belum ditambahkan.',
        );
        return;
      }

      // Tentukan path folder Download
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // Simpan file di folder Download
      final filePath =
          '${directory.path}/salary_deduction_${idEmployee}_$selectedRelationship.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.data!);

      // Tutup dialog loading
      Navigator.of(this.context).pop();

      // Tampilkan notifikasi berhasil
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('File berhasil didownload ke folder Download!')),
      );

      // Tampilkan form upload
      setState(() {
        isFormVisible = true; // Tampilkan form upload
      });
    } catch (e) {
      // Tutup dialog loading
      Navigator.of(this.context).pop();

      // Tampilkan popup jika download gagal
      _showPopup(
        context: this.context,
        title: 'Download Gagal',
        message: 'Terjadi kesalahan saat mendownload file. Silakan coba lagi.',
      );
    }
  }

  Future<void> uploadFile() async {
    if (uploadedFile == null) {
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'Anda harus mengunggah file terlebih dahulu.',
      );
      return;
    }

    // Tampilkan dialog loading
    showLoadingDialog(this.context);

    try {
      // Simulasi proses upload
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(this.context).pop(); // Tutup dialog loading
      _showPopup(
        context: this.context,
        title: 'Berhasil',
        message: 'File berhasil diunggah.',
      );
    } catch (e) {
      Navigator.of(this.context).pop(); // Tutup dialog loading
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'Terjadi kesalahan saat mengunggah file.',
      );
    }
  }

  Future<void> pickFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        uploadedFile = File(pickedFile.path);
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

  void _showPopupWithRedirect({
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
                Navigator.of(context).pop(); // Tutup popup
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuPage()),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          'BPJS Tambahan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi BPJS Tambahan
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
                              'Informasi BPJS Tambahan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Halaman ini digunakan untuk mengunggah dokumen tambahan untuk pengelolaan BPJS.',
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

              // Dropdown untuk memilih anggota BPJS
              const Text(
                'Pilih Anggota BPJS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: selectedAnggotaBpjs,
                    hint: const Text('Pilih Anggota BPJS'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Ayah', 'Ibu', 'Ayah Mertua', 'Ibu Mertua']
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
                ),
              ),
              const SizedBox(height: 16),

              // Kotak Upload Dokumen
              _buildBox(
                title: 'Upload KK',
                fieldName: 'UrlKkTambahan',
                anggotaBpjs: 'Tambahan',
              ),
              const SizedBox(height: 24),

              // Tombol Kirim Dokumen BPJS Tambahan
              ElevatedButton.icon(
                onPressed: () async {
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
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  'Kirim Dokumen BPJS Tambahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Gaji Section
              const Text(
                'Surat Pemotongan Gaji',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Dropdown untuk memilih hubungan keluarga
              const Text(
                'Pilih Hubungan Keluarga',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: selectedRelationship,
                    hint: const Text('Pilih Hubungan Keluarga'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Ayah', 'Ibu', 'Ayah Mertua', 'Ibu Mertua']
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRelationship = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Download Surat Pemotongan Gaji
              ElevatedButton.icon(
                onPressed: downloadFile,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Download Surat Pemotongan Gaji',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form Upload Surat Pemotongan Gaji
              if (isFormVisible)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Surat Pemotongan Gaji',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickFile,
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
                              ),
                              child: const Icon(
                                Icons.upload_file,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                uploadedFile != null
                                    ? basename(uploadedFile!.path)
                                    : 'Belum ada file yang dipilih',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: uploadFile,
                      icon: const Icon(Icons.cloud_upload, color: Colors.white),
                      label: const Text(
                        'Upload File',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1572E8),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
