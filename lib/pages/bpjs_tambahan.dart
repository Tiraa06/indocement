<<<<<<< HEAD
import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bpjs_upload_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class BPJSTambahanPage extends StatefulWidget {
  const BPJSTambahanPage({super.key});

  @override
  State<BPJSTambahanPage> createState() => _BPJSTambahanPageState();
}

class _BPJSTambahanPageState extends State<BPJSTambahanPage> {
  int? idEmployee;
  Map<String, File?> selectedImages =
      {}; // Menyimpan gambar yang dipilih berdasarkan fieldName
  String? selectedAnggotaBpjs; // Menyimpan pilihan dropdown
  String? selectedRelationship; // Menyimpan pilihan relationship
  final bool _isPopupVisible =
      false; // Menyimpan status apakah popup sedang ditampilkan
  bool isDownloaded = false; // Menyimpan status apakah file sudah didownload
  bool isFormVisible = false; // Status untuk menampilkan form upload
  File? uploadedFile; // File yang diunggah

  // Tambahkan variabel di state:
  int? selectedAnakKe;
  Map<String, File?> selectedImagesAnakKe = {};

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _requestStoragePermission();
  }

  void _loadEmployeeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        // Jika user menolak, minta lagi sampai diberikan atau user memilih "Jangan tanya lagi"
        await Permission.storage.request();
      }
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

  // Tambahkan fungsi pickImageAnakKe:
  Future<void> pickImageAnakKe({required String fieldName}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImagesAnakKe[fieldName] = File(pickedFile.path);
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
        'http://103.31.235.237:5555/api/Bpjs/generate-salary-deduction/$idEmployee/$selectedRelationship';

    try {
      // Tampilkan dialog loading
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: const [
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
                SizedBox(width: 20),
                Expanded(child: Text('Mohon tunggu, file sedang didownload...')),
              ],
            ),
          );
        },
      );

      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      Navigator.of(this.context).pop(); // Tutup loading dialog

      if (response.statusCode == 200) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        final filePath =
            '${directory.path}/salary_deduction_${idEmployee}_$selectedRelationship.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke $filePath')),
        );

        setState(() {
          isDownloaded = true;
          isFormVisible = true;
        });

        _showDownloadPopup(
          title: 'Download Berhasil',
          message: 'File berhasil diunduh.',
          onOpenFile: () {
            OpenFile.open(filePath);
          },
        );
      } else {
        // Jika gagal download, tampilkan modal dengan pesan khusus
        _showPopup(
          context: this.context,
          title: 'Gagal Download',
          message: 'Data keluarga belum tersedia. Silakan input data keluarga terlebih dahulu.',
        );
      }
    } catch (e) {
      Navigator.of(this.context).pop();
      _showPopup(
        context: this.context,
        title: 'Download Gagal',
        message: 'Data keluarga belum tersedia. Silakan input data keluarga terlebih dahulu.',
      );
      print('Download error: $e');
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
    final bool isError = title.toLowerCase().contains('gagal') || title.toLowerCase().contains('error');
    final Color mainColor = isError ? Colors.red : const Color(0xFF1572E8);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: mainColor,
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: mainColor,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    required String anakKe,
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedImages[fieldName] != null
                        ? basename(selectedImages[fieldName]!.path)
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

  void _showDownloadPopup({
    required String title,
    required String message,
    required VoidCallback onOpenFile,
    String okText = 'OK',
    String openText = 'Open File',
  }) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1572E8).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: const Icon(
                    Icons.file_download_done_rounded,
                    color: Color(0xFF1572E8),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF1572E8),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open_rounded, size: 20, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1572E8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenFile();
                        },
                        label: Text(
                          openText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1572E8), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          okText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1572E8),
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          'BPJS Tambahan',
          style: TextStyle(
            color: Colors.white, // Judul header warna putih
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // Tombol back warna putih
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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
                              'Halaman ini digunakan untuk mengunggah dokumen tambahan untuk pengelolaan data BPJS Tambahan.',
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

              // Section Pilih Anggota BPJS, Upload KK, Upload Surat Regis, dan Tombol Kirim Regis
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan icon dan judul
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1572E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.group,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Pilih Anggota BPJS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown anggota BPJS
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1572E8),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedAnggotaBpjs,
                            hint: const Text(
                              'Pilih Anggota BPJS',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1572E8),
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF1572E8), size: 32),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            items: [
                              'Ayah',
                              'Ibu',
                              'Ayah Mertua',
                              'Ibu Mertua',
                              'Anak ke-4',
                              'Anak ke-5',
                              'Anak ke-6',
                              'Anak ke-7',
                            ]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          Icon(Icons.person,
                                              color: Colors.blue[400]),
                                          const SizedBox(width: 8),
                                          Text(e),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAnggotaBpjs = value;
                                uploadedFile = null;
                                isFormVisible = false;
                                selectedRelationship = value;
                              });
                            },
                          ),
                        ),
                      ),
                      // Tombol download jika sudah pilih anggota BPJS
                      if (selectedAnggotaBpjs != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: downloadFile,
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Download Surat Registrasi BPJS Tambahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1572E8),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedAnggotaBpjs!.startsWith('Anak ke-')) ...[
                          // Hanya tampil jika pilih Anak ke-4 dst
                          GestureDetector(
                            onTap: () =>
                                pickImage(fieldName: 'UrlAkteLahirTambahan'),
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
                                      image: selectedImages[
                                                  'UrlAkteLahirTambahan'] !=
                                              null
                                          ? DecorationImage(
                                              image: FileImage(selectedImages[
                                                  'UrlAkteLahirTambahan']!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: selectedImages[
                                                'UrlAkteLahirTambahan'] ==
                                            null
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Akte Kelahiran',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedImages[
                                                      'UrlAkteLahirTambahan'] !=
                                                  null
                                              ? basename(selectedImages[
                                                      'UrlAkteLahirTambahan']!
                                                  .path)
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
                                    child: uploadedFile != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              uploadedFile!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Surat Registrasi BPJS Tambahan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          uploadedFile != null
                                              ? basename(uploadedFile!.path)
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
                          const SizedBox(height: 24),
                          // Tombol kirim untuk anak ke-4 dst
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              // ...tombol kirim anak ke-4 dst...
                              onPressed: () async {
                                // Validasi file
                                if (selectedImages['UrlAkteLahirTambahan'] ==
                                    null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Akte Kelahiran terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (uploadedFile == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Surat Registrasi BPJS Tambahan terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (idEmployee == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'ID karyawan belum tersedia.',
                                  );
                                  return;
                                }
                                showLoadingDialog(context);
                                try {
                                  final dio = Dio();
                                  final formData = FormData();

                                  // Ambil angka anak ke-berapa dari string, misal "Anak ke-4" -> 4
                                  int anakKe = 0;
                                  if (selectedAnggotaBpjs != null &&
                                      selectedAnggotaBpjs!
                                          .startsWith('Anak ke-')) {
                                    anakKe = int.tryParse(selectedAnggotaBpjs!
                                            .replaceAll(
                                                RegExp(r'[^0-9]'), '')) ??
                                        0;
                                  }

                                  // Tambahkan file ke array Files & FileTypes
                                  formData.files.addAll([
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        selectedImages['UrlAkteLahirTambahan']!
                                            .path,
                                        filename: basename(selectedImages[
                                                'UrlAkteLahirTambahan']!
                                            .path),
                                      ),
                                    ),
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        uploadedFile!.path,
                                        filename: basename(uploadedFile!.path),
                                      ),
                                    ),
                                  ]);
                                  formData.fields.addAll([
                                    MapEntry(
                                        "IdEmployee", idEmployee.toString()),
                                    MapEntry("FileTypes", "UrlAkteLahir"),
                                    MapEntry("FileTypes", "UrlSuratPotongGaji"),
                                    // Kirim hanya "Anak" ke AnggotaBpjs
                                    MapEntry("AnggotaBpjs", "Anak"),
                                    // Kirim hanya angka ke AnakKe
                                    MapEntry("AnakKe", anakKe.toString()),
                                  ]);

                                  final response = await dio.post(
                                    'http://103.31.235.237:5555/api/Bpjs/upload',
                                    data: formData,
                                    options: Options(
                                      headers: {
                                        'accept': 'application/json',
                                        'Content-Type': 'multipart/form-data',
                                      },
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  if (response.statusCode == 200) {
                                    _showPopup(
                                      context: context,
                                      title: 'Berhasil',
                                      message: 'Data anak berhasil dikirim.',
                                    );
                                  } else {
                                    _showPopup(
                                      context: context,
                                      title: 'Gagal',
                                      message:
                                          'Gagal mengirim data anak. (${response.statusCode})\n${response.data}',
                                    );
                                  }
                                } on DioException {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } on SocketException catch (_) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } on TimeoutException catch (_) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Terjadi kesalahan saat mengirim data.\n$e',
                                  );
                                }
                              },
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'Kirim Data Anak',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1572E8),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Hanya tampil jika pilih Ayah/Ibu/Mertua
                          _buildBox(
                            title: 'Upload KK',
                            fieldName: 'UrlKkTambahan',
                            anggotaBpjs: 'Tambahan',
                          ),
                          const SizedBox(height: 16),
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
                                    child: uploadedFile != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              uploadedFile!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Surat Registrasi BPJS Tambahan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          uploadedFile != null
                                              ? basename(uploadedFile!.path)
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
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              // ...tombol kirim untuk Ayah/Ibu/Mertua...
                              onPressed: () async {
                                if (uploadedFile == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Surat Registrasi BPJS Tambahan terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (idEmployee == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'ID karyawan belum tersedia.',
                                  );
                                  return;
                                }
                                showLoadingDialog(context);
                                try {
                                  final dio = Dio();
                                  final formData = FormData();

                                  formData.files.addAll([
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        uploadedFile!.path,
                                        filename: basename(uploadedFile!.path),
                                      ),
                                    ),
                                  ]);
                                  formData.fields.addAll([
                                    MapEntry(
                                        "IdEmployee", idEmployee.toString()),
                                    MapEntry("FileTypes", "UrlSuratPotongGaji"),
                                    MapEntry(
                                        "AnggotaBpjs", selectedAnggotaBpjs!),
                                  ]);

                                  final response = await dio.post(
                                    'http://103.31.235.237:5555/api/Bpjs/upload',
                                    data: formData,
                                    options: Options(
                                      headers: {
                                        'accept': 'application/json',
                                        'Content-Type': 'multipart/form-data',
                                      },
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  if (response.statusCode == 200) {
                                    _showPopup(
                                      context: context,
                                      title: 'Berhasil',
                                      message: 'Surat Registrasi BPJS Tambahan berhasil dikirim.',
                                    );
                                  } else {
                                    _showPopup(
                                      context: context,
                                      title: 'Gagal',
                                      message:
                                          'Gagal mengirim file. (${response.statusCode})\n${response.data}',
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  print('❌ Error kirim surat regis: $e');
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Terjadi kesalahan saat mengirim file.\n$e',
                                  );
                                }
                              },
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'Kirim Surat Registrasi BPJS Tambahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1572E8),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
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
=======
import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bpjs_upload_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class BPJSTambahanPage extends StatefulWidget {
  const BPJSTambahanPage({super.key});

  @override
  State<BPJSTambahanPage> createState() => _BPJSTambahanPageState();
}

class _BPJSTambahanPageState extends State<BPJSTambahanPage> {
  int? idEmployee;
  Map<String, File?> selectedImages =
      {}; // Menyimpan gambar yang dipilih berdasarkan fieldName
  String? selectedAnggotaBpjs; // Menyimpan pilihan dropdown
  String? selectedRelationship; // Menyimpan pilihan relationship
  final bool _isPopupVisible =
      false; // Menyimpan status apakah popup sedang ditampilkan
  bool isDownloaded = false; // Menyimpan status apakah file sudah didownload
  bool isFormVisible = false; // Status untuk menampilkan form upload
  File? uploadedFile; // File yang diunggah

  // Tambahkan variabel di state:
  int? selectedAnakKe;
  Map<String, File?> selectedImagesAnakKe = {};

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _requestStoragePermission();
  }

  void _loadEmployeeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        // Jika user menolak, minta lagi sampai diberikan atau user memilih "Jangan tanya lagi"
        await Permission.storage.request();
      }
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

  // Tambahkan fungsi pickImageAnakKe:
  Future<void> pickImageAnakKe({required String fieldName}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImagesAnakKe[fieldName] = File(pickedFile.path);
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
        'http://103.31.235.237:5555/api/Bpjs/generate-salary-deduction/$idEmployee/$selectedRelationship';

    try {
      // Tampilkan dialog loading
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: const [
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
                SizedBox(width: 20),
                Expanded(child: Text('Mohon tunggu, file sedang didownload...')),
              ],
            ),
          );
        },
      );

      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      Navigator.of(this.context).pop(); // Tutup loading dialog

      if (response.statusCode == 200) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        final filePath =
            '${directory.path}/salary_deduction_${idEmployee}_$selectedRelationship.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke $filePath')),
        );

        setState(() {
          isDownloaded = true;
          isFormVisible = true;
        });

        _showDownloadPopup(
          title: 'Download Berhasil',
          message: 'File berhasil diunduh.',
          onOpenFile: () {
            OpenFile.open(filePath);
          },
        );
      } else {
        // Jika gagal download, tampilkan modal dengan pesan khusus
        _showPopup(
          context: this.context,
          title: 'Gagal Download',
          message: 'Data keluarga belum tersedia. Silakan input data keluarga terlebih dahulu.',
        );
      }
    } catch (e) {
      Navigator.of(this.context).pop();
      _showPopup(
        context: this.context,
        title: 'Download Gagal',
        message: 'Data keluarga belum tersedia. Silakan input data keluarga terlebih dahulu.',
      );
      print('Download error: $e');
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
    final bool isError = title.toLowerCase().contains('gagal') || title.toLowerCase().contains('error');
    final Color mainColor = isError ? Colors.red : const Color(0xFF1572E8);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: mainColor,
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: mainColor,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    required String anakKe,
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedImages[fieldName] != null
                        ? basename(selectedImages[fieldName]!.path)
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

  void _showDownloadPopup({
    required String title,
    required String message,
    required VoidCallback onOpenFile,
    String okText = 'OK',
    String openText = 'Open File',
  }) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1572E8).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: const Icon(
                    Icons.file_download_done_rounded,
                    color: Color(0xFF1572E8),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF1572E8),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open_rounded, size: 20, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1572E8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenFile();
                        },
                        label: Text(
                          openText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1572E8), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          okText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1572E8),
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          'BPJS Tambahan',
          style: TextStyle(
            color: Colors.white, // Judul header warna putih
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // Tombol back warna putih
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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
                              'Halaman ini digunakan untuk mengunggah dokumen tambahan untuk pengelolaan data BPJS Tambahan.',
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

              // Section Pilih Anggota BPJS, Upload KK, Upload Surat Regis, dan Tombol Kirim Regis
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan icon dan judul
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1572E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.group,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Pilih Anggota BPJS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown anggota BPJS
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1572E8),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedAnggotaBpjs,
                            hint: const Text(
                              'Pilih Anggota BPJS',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1572E8),
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF1572E8), size: 32),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            items: [
                              'Ayah',
                              'Ibu',
                              'Ayah Mertua',
                              'Ibu Mertua',
                              'Anak ke-4',
                              'Anak ke-5',
                              'Anak ke-6',
                              'Anak ke-7',
                            ]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        children: [
                                          Icon(Icons.person,
                                              color: Colors.blue[400]),
                                          const SizedBox(width: 8),
                                          Text(e),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAnggotaBpjs = value;
                                uploadedFile = null;
                                isFormVisible = false;
                                selectedRelationship = value;
                              });
                            },
                          ),
                        ),
                      ),
                      // Tombol download jika sudah pilih anggota BPJS
                      if (selectedAnggotaBpjs != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: downloadFile,
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Download Surat Registrasi BPJS Tambahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1572E8),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedAnggotaBpjs!.startsWith('Anak ke-')) ...[
                          // Hanya tampil jika pilih Anak ke-4 dst
                          GestureDetector(
                            onTap: () =>
                                pickImage(fieldName: 'UrlAkteLahirTambahan'),
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
                                      image: selectedImages[
                                                  'UrlAkteLahirTambahan'] !=
                                              null
                                          ? DecorationImage(
                                              image: FileImage(selectedImages[
                                                  'UrlAkteLahirTambahan']!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: selectedImages[
                                                'UrlAkteLahirTambahan'] ==
                                            null
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Akte Kelahiran',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedImages[
                                                      'UrlAkteLahirTambahan'] !=
                                                  null
                                              ? basename(selectedImages[
                                                      'UrlAkteLahirTambahan']!
                                                  .path)
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
                                    child: uploadedFile != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              uploadedFile!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Surat Registrasi BPJS Tambahan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          uploadedFile != null
                                              ? basename(uploadedFile!.path)
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
                          const SizedBox(height: 24),
                          // Tombol kirim untuk anak ke-4 dst
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              // ...tombol kirim anak ke-4 dst...
                              onPressed: () async {
                                // Validasi file
                                if (selectedImages['UrlAkteLahirTambahan'] ==
                                    null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Akte Kelahiran terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (uploadedFile == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Surat Registrasi BPJS Tambahan terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (idEmployee == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'ID karyawan belum tersedia.',
                                  );
                                  return;
                                }
                                showLoadingDialog(context);
                                try {
                                  final dio = Dio();
                                  final formData = FormData();

                                  // Ambil angka anak ke-berapa dari string, misal "Anak ke-4" -> 4
                                  int anakKe = 0;
                                  if (selectedAnggotaBpjs != null &&
                                      selectedAnggotaBpjs!
                                          .startsWith('Anak ke-')) {
                                    anakKe = int.tryParse(selectedAnggotaBpjs!
                                            .replaceAll(
                                                RegExp(r'[^0-9]'), '')) ??
                                        0;
                                  }

                                  // Tambahkan file ke array Files & FileTypes
                                  formData.files.addAll([
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        selectedImages['UrlAkteLahirTambahan']!
                                            .path,
                                        filename: basename(selectedImages[
                                                'UrlAkteLahirTambahan']!
                                            .path),
                                      ),
                                    ),
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        uploadedFile!.path,
                                        filename: basename(uploadedFile!.path),
                                      ),
                                    ),
                                  ]);
                                  formData.fields.addAll([
                                    MapEntry(
                                        "IdEmployee", idEmployee.toString()),
                                    MapEntry("FileTypes", "UrlAkteLahir"),
                                    MapEntry("FileTypes", "UrlSuratPotongGaji"),
                                    // Kirim hanya "Anak" ke AnggotaBpjs
                                    MapEntry("AnggotaBpjs", "Anak"),
                                    // Kirim hanya angka ke AnakKe
                                    MapEntry("AnakKe", anakKe.toString()),
                                  ]);

                                  final response = await dio.post(
                                    'http://103.31.235.237:5555/api/Bpjs/upload',
                                    data: formData,
                                    options: Options(
                                      headers: {
                                        'accept': 'application/json',
                                        'Content-Type': 'multipart/form-data',
                                      },
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  if (response.statusCode == 200) {
                                    _showPopup(
                                      context: context,
                                      title: 'Berhasil',
                                      message: 'Data anak berhasil dikirim.',
                                    );
                                  } else {
                                    _showPopup(
                                      context: context,
                                      title: 'Gagal',
                                      message:
                                          'Gagal mengirim data anak. (${response.statusCode})\n${response.data}',
                                    );
                                  }
                                } on DioException {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } on SocketException catch (_) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } on TimeoutException catch (_) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Server sedang dalam gangguan.',
                                  );
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'Terjadi kesalahan saat mengirim data.\n$e',
                                  );
                                }
                              },
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'Kirim Data Anak',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1572E8),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Hanya tampil jika pilih Ayah/Ibu/Mertua
                          _buildBox(
                            title: 'Upload KK',
                            fieldName: 'UrlKkTambahan',
                            anggotaBpjs: 'Tambahan',
                          ),
                          const SizedBox(height: 16),
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
                                    child: uploadedFile != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              uploadedFile!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Upload Surat Registrasi BPJS Tambahan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          uploadedFile != null
                                              ? basename(uploadedFile!.path)
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
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              // ...tombol kirim untuk Ayah/Ibu/Mertua...
                              onPressed: () async {
                                if (uploadedFile == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Anda harus mengunggah Surat Registrasi BPJS Tambahan terlebih dahulu.',
                                  );
                                  return;
                                }
                                if (idEmployee == null) {
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message: 'ID karyawan belum tersedia.',
                                  );
                                  return;
                                }
                                showLoadingDialog(context);
                                try {
                                  final dio = Dio();
                                  final formData = FormData();

                                  formData.files.addAll([
                                    MapEntry(
                                      "Files",
                                      await MultipartFile.fromFile(
                                        uploadedFile!.path,
                                        filename: basename(uploadedFile!.path),
                                      ),
                                    ),
                                  ]);
                                  formData.fields.addAll([
                                    MapEntry(
                                        "IdEmployee", idEmployee.toString()),
                                    MapEntry("FileTypes", "UrlSuratPotongGaji"),
                                    MapEntry(
                                        "AnggotaBpjs", selectedAnggotaBpjs!),
                                  ]);

                                  final response = await dio.post(
                                    'http://103.31.235.237:5555/api/Bpjs/upload',
                                    data: formData,
                                    options: Options(
                                      headers: {
                                        'accept': 'application/json',
                                        'Content-Type': 'multipart/form-data',
                                      },
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  if (response.statusCode == 200) {
                                    _showPopup(
                                      context: context,
                                      title: 'Berhasil',
                                      message: 'Surat Registrasi BPJS Tambahan berhasil dikirim.',
                                    );
                                  } else {
                                    _showPopup(
                                      context: context,
                                      title: 'Gagal',
                                      message:
                                          'Gagal mengirim file. (${response.statusCode})\n${response.data}',
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  print('❌ Error kirim surat regis: $e');
                                  _showPopup(
                                    context: context,
                                    title: 'Gagal',
                                    message:
                                        'Terjadi kesalahan saat mengirim file.\n$e',
                                  );
                                }
                              },
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white),
                              label: const Text(
                                'Kirim Surat Registrasi BPJS Tambahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1572E8),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
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
>>>>>>> 886a118e1eca690253f55857ad9418a04d444e82
