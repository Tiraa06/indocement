import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:media_store_plus/media_store_plus.dart'; // Ensure this import is present
import 'package:shared_preferences/shared_preferences.dart';

class MedicPasutriPage extends StatefulWidget {
  const MedicPasutriPage({super.key});

  @override
  State<MedicPasutriPage> createState() => _MedicPasutriPageState();
}

class _MedicPasutriPageState extends State<MedicPasutriPage> {
  final String fileUrl =
      'http://213.35.123.110:5555/templates/medical.pdf'; // URL file
  bool isLoadingDownload =
      false; // Untuk menampilkan indikator loading download
  bool isDownloaded = false; // Status apakah file sudah didownload
  File? uploadedFile; // Menyimpan file yang diunggah
  bool isUploading = false; // Status apakah sedang mengunggah file

  @override
  void initState() {
    super.initState();
    fetchAndSaveIdEmployeeFromMedical(); // Ambil dan simpan IdEmployee saat halaman dimuat
  }

  Future<void> downloadFile() async {
    final dio = Dio();

    try {
      // Ambil IdEmployee dari SharedPreferences
      final idEmployee = await getIdEmployee();
      if (idEmployee == null) {
        throw Exception('ID Employee tidak ditemukan. Harap login ulang.');
      }

      // Tampilkan popup dengan progress bar
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Mengunduh File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                LinearProgressIndicator(),
                SizedBox(height: 16),
                Text('Sedang mengunduh file, harap tunggu...'),
              ],
            ),
          );
        },
      );

      final url =
          'http://213.35.123.110:5555/api/Medical/generate-medical-document/$idEmployee';

      final response = await dio.post(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      Navigator.of(this.context).pop(); // Tutup popup setelah selesai

      if (response.statusCode == 200) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        final filePath = '${directory.path}/medical_$idEmployee.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        // Tandai bahwa file sudah diunduh
        setState(() {
          isDownloaded = true;
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke $filePath')),
        );
      } else {
        throw Exception('Gagal mengunduh file: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(this.context).pop(); // Tutup popup jika terjadi kesalahan
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
            content: const Text('Anda harus memilih file terlebih dahulu.'),
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

    setState(() {
      isUploading = true; // Mulai proses upload
    });

    try {
      // Ambil IdEmployee dari SharedPreferences
      final idEmployee = await getIdEmployee();
      if (idEmployee == null) {
        throw Exception('ID Employee tidak ditemukan. Harap login ulang.');
      }

      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          uploadedFile!.path,
          filename: basename(uploadedFile!.path),
        ),
        'idEmployee': idEmployee,
      });

      final response = await dio.post(
        'http://213.35.123.110:5555/api/Medical/upload',
        data: formData,
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('File berhasil diupload!')),
        );
      } else {
        throw Exception('Gagal mengunggah file: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal upload file: $e')),
      );
    } finally {
      setState(() {
        isUploading = false; // Selesai proses upload
      });
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      // Izin diberikan
    } else {
      throw Exception('Izin penyimpanan tidak diberikan.');
    }
  }

  Future<void> saveIdEmployee(int idEmployee) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('idEmployee', idEmployee);
  }

  Future<int?> getIdEmployee() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('idEmployee');
  }

  Future<void> fetchAndSaveIdEmployee() async {
    try {
      // Panggil API untuk mendapatkan idEmployee
      final response = await Dio().get(
        'http://213.35.123.110:5555/api/Employee/get-id', // Ganti dengan endpoint API yang sesuai
      );

      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final idEmployee = response.data['idEmployee'];
        if (idEmployee != null) {
          // Simpan idEmployee ke SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('idEmployee', idEmployee);

          setState(() {
            // Perbarui state jika diperlukan
          });

          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('ID Employee berhasil disimpan: $idEmployee')),
          );
        } else {
          throw Exception('ID Employee tidak ditemukan di respons API.');
        }
      } else {
        throw Exception('Gagal mendapatkan ID Employee: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan ID Employee: $e')),
      );
    }
  }

  Future<void> fetchAndSaveIdEmployeeFromMedical() async {
    try {
      // Panggil API untuk mendapatkan data Medical
      final response = await Dio().get(
        'http://213.35.123.110:5555/api/Medical',
      );

      if (response.statusCode == 200) {
        // Periksa apakah respons adalah array
        if (response.data is List && response.data.isNotEmpty) {
          // Ambil elemen pertama dari array
          final firstItem = response.data[0];
          final idEmployee = firstItem['IdEmployee'];

          if (idEmployee != null) {
            // Simpan IdEmployee ke SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('idEmployee', idEmployee);

            setState(() {
              // Perbarui state jika diperlukan
            });
          } else {
            throw Exception('ID Employee tidak ditemukan di respons API.');
          }
        } else {
          throw Exception('Respons API kosong atau tidak valid.');
        }
      } else {
        throw Exception('Gagal mendapatkan ID Employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e'); // Log kesalahan
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan ID Employee: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: Colors.white), // Tombol back warna putih
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                        ? basename(uploadedFile!
                                            .path) // Hanya nama file
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
                      onPressed: isDownloaded && !isUploading ? uploadFile : null, // Tombol hanya aktif jika file sudah diunduh dan tidak sedang mengunggah
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDownloaded
                            ? const Color(0xFF1572E8) // Warna biru jika aktif
                            : Colors.grey, // Warna abu-abu jika tidak aktif
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
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
