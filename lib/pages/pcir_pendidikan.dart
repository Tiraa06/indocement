import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class TambahDataPendidikanPage extends StatefulWidget {
  const TambahDataPendidikanPage({super.key});

  @override
  State<TambahDataPendidikanPage> createState() =>
      _TambahDataPendidikanPageState();
}

class _TambahDataPendidikanPageState extends State<TambahDataPendidikanPage> {
  int? idEmployee;
  File? selectedIjazah;

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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedIjazah = File(pickedFile.path);
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> uploadIjazah() async {
    if (idEmployee == null) {
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'ID karyawan tidak valid.',
      );
      return;
    }

    if (selectedIjazah == null || !selectedIjazah!.existsSync()) {
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'Anda harus mengunggah Ijazah yang valid.',
      );
      return;
    }

    showLoadingDialog(this.context);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'http://213.35.123.110:5555/api/Employees/$idEmployee/UrlIjazahTerbaru'),
      );

      request.headers['Accept'] = '*/*';
      // Placeholder for authentication, replace with actual token if required
      request.headers['Authorization'] = 'Bearer YOUR_AUTH_TOKEN_HERE';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Changed to 'file' to test server compatibility
          selectedIjazah!.path,
          filename:
              'UrlIjazahTerbaru_${idEmployee}_${DateTime.now().millisecondsSinceEpoch}${extension(selectedIjazah!.path)}',
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      Navigator.of(this.context).pop();

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showPopup(
          context: this.context,
          title: 'Berhasil',
          message: 'Ijazah berhasil diunggah.',
        );
      } else {
        _showPopup(
          context: this.context,
          title: 'Gagal',
          message:
              'Gagal mengunggah Ijazah: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      Navigator.of(this.context).pop();
      _showPopup(
        context: this.context,
        title: 'Gagal',
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
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
                          color: const Color.fromARGB(255, 255, 255, 255),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.school,
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
                            'Update Data Pendidikan',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Halaman ini digunakan untuk mengunggah dokumen Ijazah terbaru.',
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
              _buildBox(
                title: 'Upload Ijazah',
                onTap: pickImage,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: uploadIjazah,
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: 1,
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
                image: selectedIjazah != null
                    ? DecorationImage(
                        image: FileImage(selectedIjazah!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: selectedIjazah == null
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
                    selectedIjazah != null
                        ? basename(selectedIjazah!.path)
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
