import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:indocement_apk/pages/bpjs_karyawan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart'; // Untuk mendapatkan nama file utama
import 'package:dio/dio.dart';

class TambahDataAnakPage extends StatefulWidget {
  const TambahDataAnakPage({super.key});

  @override
  State<TambahDataAnakPage> createState() => _TambahDataAnakPageState();
}

class _TambahDataAnakPageState extends State<TambahDataAnakPage> {
  int? idEmployee;
  String? urlKk;
  String? urlAkteLahir;
  String? selectedAnakKe; // Menyimpan pilihan "Anak Ke"
  bool isLoading = false;
  Map<String, File?> selectedImages = {}; // Menyimpan gambar yang dipilih berdasarkan fieldName

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
    });
    if (idEmployee != null) {
      _fetchUploadedData();
    }
  }

  Future<void> _fetchUploadedData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Dio().get(
        'http://213.35.123.110:5555/api/Bpjs',
        queryParameters: {'idEmployee': idEmployee},
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;

        // Cari data berdasarkan AnggotaBpjs = "Anak"
        final data = dataList.firstWhere(
          (item) => item['AnggotaBpjs'] == 'Anak',
          orElse: () => null,
        );

        if (data != null) {
          // Simpan data ke SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('Id', data['Id']);
          await prefs.setInt('IdEmployee', data['IdEmployee']);
          await prefs.setString('AnggotaBpjs', data['AnggotaBpjs']);

          setState(() {
            urlKk = data['UrlKk'];
            urlAkteLahir = data['UrlAkteLahir'];
            selectedAnakKe = data['AnakKe'];
          });
        } else {
          // Jika data tidak ditemukan, buat ID baru
          await _createNewBpjsEntry();
        }
      } else {
        throw Exception('Gagal memuat data dari API.');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createNewBpjsEntry() async {
    try {
      final response = await Dio().post(
        'http://213.35.123.110:5555/api/Bpjs',
        data: {
          'IdEmployee': idEmployee,
          'AnggotaBpjs': 'Anak',
          'AnakKe': null, // Nilai default untuk AnakKe
          'UrlKk': null,
          'UrlAkteLahir': null,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;

        // Simpan data baru ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('Id', data['Id']);
        await prefs.setInt('IdEmployee', data['IdEmployee']);
        await prefs.setString('AnggotaBpjs', data['AnggotaBpjs']);

        setState(() {
          selectedAnakKe = data['AnakKe'];
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('ID baru berhasil dibuat untuk AnggotaBpjs "Anak".')),
        );
      } else {
        throw Exception('Gagal membuat ID baru: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat membuat ID baru: $e')),
      );
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

  Future<void> uploadDokumenAnak() async {
    try {
      setState(() => isLoading = true);

      // Ambil data dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? id = prefs.getInt('Id');
      final int? employeeId = prefs.getInt('IdEmployee');
      final String? anggotaBpjs = prefs.getString('AnggotaBpjs');

      if (id == null || employeeId == null || anggotaBpjs == null || selectedAnakKe == null) {
        throw Exception('Data ID, IdEmployee, AnggotaBpjs, atau AnakKe tidak ditemukan.');
      }

      // Siapkan data untuk dikirim ke API
      final formData = FormData();

      // Tambahkan file UrlKk ke FormData
      if (selectedImages['UrlKk'] != null) {
        formData.files.add(
          MapEntry(
            'Files',
            await MultipartFile.fromFile(
              selectedImages['UrlKk']!.path,
              filename: basename(selectedImages['UrlKk']!.path),
            ),
          ),
        );
      }

      // Tambahkan file UrlAkteLahir ke FormData
      if (selectedImages['UrlAkteLahir'] != null) {
        formData.files.add(
          MapEntry(
            'Files',
            await MultipartFile.fromFile(
              selectedImages['UrlAkteLahir']!.path,
              filename: basename(selectedImages['UrlAkteLahir']!.path),
            ),
          ),
        );
      }

      // Tambahkan field tambahan ke FormData
      formData.fields.addAll([
        MapEntry('idEmployee', employeeId.toString()),
        MapEntry('FileTypes', 'UrlKk'),
        MapEntry('FileTypes', 'UrlAkteLahir'),
        MapEntry('AnggotaBpjs', anggotaBpjs),
        MapEntry('AnakKe', selectedAnakKe!), // Tambahkan AnakKe
      ]);

      // Kirim data ke API dengan metode PUT
      final uploadResponse = await Dio().put(
        'http://213.35.123.110:5555/api/Bpjs/upload/$id',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('File berhasil diunggah.')),
        );
        await _fetchUploadedData(); // Refresh data setelah upload
      } else {
        throw Exception('Upload gagal: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Data Anak'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perbarui Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown untuk Anak Ke
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black), // Border warna hitam
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
                          items: List.generate(5, (index) => (index + 1).toString())
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

                    // Form Upload
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
                            'Upload Dokumen',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildBox(
                            title: 'Upload Kartu Keluarga',
                            fieldName: 'UrlKk',
                          ),
                          const SizedBox(height: 16),
                          _buildBox(
                            title: 'Upload Akte Lahir',
                            fieldName: 'UrlAkteLahir',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await uploadDokumenAnak();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1572E8),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Perbarui Data',
                              style: TextStyle(color: Colors.white),
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

  Widget _buildUploadedFileBox(String? url, String label) {
    if (url == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
          const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red), // Ikon PDF
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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