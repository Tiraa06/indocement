import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class MedicPasutriPage extends StatefulWidget {
  const MedicPasutriPage({super.key});

  @override
  State<MedicPasutriPage> createState() => _MedicPasutriPageState();
}

class _MedicPasutriPageState extends State<MedicPasutriPage> {
  final String fileUrl = 'http://213.35.123.110:5555/templates/medical.pdf'; // URL file
  bool isLoadingDownload = false; // Untuk menampilkan indikator loading download
  bool isDownloaded = false; // Status apakah file sudah didownload
  File? uploadedFile; // Menyimpan file yang diunggah

  Future<void> downloadFile() async {
    final dio = Dio();

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

      setState(() {
        isLoadingDownload = true;
      });

      // Download file menggunakan Dio
      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (Platform.isAndroid) {
        // Tentukan path folder Download
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        // Simpan file di folder Download
        final filePath = '${directory.path}/medical.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        setState(() {
          isLoadingDownload = false;
          isDownloaded = true; // Tandai bahwa file sudah didownload
        });

        // Tutup dialog loading
        Navigator.of(this.context).pop();

        // Tampilkan notifikasi berhasil
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke folder Download!')),
        );
      } else {
        // Jika bukan Android, gunakan path default untuk penyimpanan (iOS)
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/medical.pdf';
        final file = File(filePath);

        await file.writeAsBytes(response.data!);

        setState(() {
          isLoadingDownload = false;
          isDownloaded = true; // Tandai bahwa file sudah didownload
        });

        // Tutup dialog loading
        Navigator.of(this.context).pop();

        // Tampilkan notifikasi berhasil
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke $filePath')),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingDownload = false;
      });

      // Tutup dialog loading
      Navigator.of(this.context).pop();

      // Tampilkan notifikasi gagal
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal download file: $e')),
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

  Future<void> uploadFile() async {
    if (uploadedFile == null) {
      showDialog(
        context: this.context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Peringatan'),
            content: const Text('Anda harus mengunggah Surat Keterangan terlebih dahulu.'),
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
      return;
    }

    try {
      // Tampilkan notifikasi proses upload
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          uploadedFile!.path,
          filename: basename(uploadedFile!.path), // Nama file
          contentType: MediaType('application', 'pdf'), // Tipe file
        ),
        'idEmployee': 3, // ID karyawan
      });

      // Kirim permintaan POST ke API
      final response = await dio.post(
        'http://213.35.123.110:5555/api/Medical/upload',
        data: formData,
        options: Options(
          headers: {
            'accept': '/',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      Navigator.of(this.context).pop(); // Tutup dialog loading

      if (response.statusCode == 200) {
        showDialog(
          context: this.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Berhasil'),
              content: const Text('File berhasil diupload!'),
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
      } else {
        showDialog(
          context: this.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Gagal'),
              content: Text('Gagal mengunggah file: ${response.statusCode}'),
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
    } catch (e) {
      Navigator.of(this.context).pop(); // Tutup dialog loading
      showDialog(
        context: this.context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kesalahan'),
            content: Text('Terjadi kesalahan: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         iconTheme: const IconThemeData(color: Colors.white), // Tombol back warna putih
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container dengan Icon dan Teks
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.note,
                      size: 40,
                      color: Color(0xFF1572E8),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Instruksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Silakan download file terlebih dahulu, lalu upload file yang sudah ditandatangani.',
                            style: TextStyle(
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
              const SizedBox(height: 24),

              // Tombol Download
              ElevatedButton.icon(
                onPressed: isLoadingDownload ? null : downloadFile,
                icon: isLoadingDownload
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Download Medical PDF',
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

              // Upload Surat Keterangan
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
                    const Text(
                      'Upload Surat Keterangan yang Sudah di Tanda Tangan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickFile,
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
                                image: uploadedFile != null
                                    ? DecorationImage(
                                        image: FileImage(uploadedFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: uploadedFile == null
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
                                    uploadedFile != null
                                        ? basename(uploadedFile!.path) // Hanya nama file
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
                    ElevatedButton(
                      onPressed: isDownloaded ? uploadFile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDownloaded ? const Color(0xFF1572E8) : Colors.grey,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Kirim Surat Keterangan',
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
            ],
          ),
        ),
      ),
    );
  }
}
