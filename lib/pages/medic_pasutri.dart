import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
// Ensure this import is present
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Tambahkan di bagian import jika belum

class MedicPasutriPage extends StatefulWidget {
  const MedicPasutriPage({super.key});

  @override
  State<MedicPasutriPage> createState() => _MedicPasutriPageState();
}

class _MedicPasutriPageState extends State<MedicPasutriPage> {
  final String fileUrl =
      'http://192.168.100.140:5555/templates/medical.pdf'; // URL file
  bool isLoadingDownload =
      false; // Untuk menampilkan indikator loading download
  bool isDownloaded = false; // Status apakah file sudah didownload
  File? uploadedFile; // Menyimpan file yang diunggah
  bool isUploading = false; // Status apakah sedang mengunggah file
  bool isDownloadEnabled = false; // Status apakah tombol download diaktifkan
  // Tambahkan variabel state untuk loading kirim surat
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    fetchAndSaveIdEmployeeFromMedical().then((_) {
      fetchAndFillEmployeeData();
    });

    // Set tanggal surat otomatis saat init
    final now = DateTime.now();
    tanggalSuratController.text =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    tahunController.text = now.year.toString();
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
          'http://192.168.100.140:5555/api/Medical/generate-medical-document/$idEmployee';

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

        // Tutup dropdown jika masih terbuka
        FocusScope.of(this.context).unfocus();

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('File berhasil didownload ke $filePath')),
        );

        // Reload halaman setelah download selesai
        Navigator.of(this.context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MedicPasutriPage(),
          ),
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
        'http://192.168.100.140:5555/api/Medical/upload',
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

  // Fungsi untuk menyimpan id employee ke SharedPreferences
  Future<void> saveIdEmployeeToPrefs(int idEmployee) async {
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
        'http://192.168.100.140:5555/api/Employee/get-id', // Ganti dengan endpoint API yang sesuai
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
        'http://192.168.100.140:5555/api/Medical',
      );

      if (response.statusCode == 200) {
        if (response.data is List && response.data.isNotEmpty) {
          final firstItem = response.data[0];
          final idEmployee = firstItem['IdEmployee'];

          if (idEmployee != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('idEmployee', idEmployee);

            setState(() {});
          }
        }
      }
    } catch (e) {
      // error handling
    }
  }

  // Tambahkan fungsi untuk fetch data employee dan isi otomatis form

  Future<void> fetchAndFillEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmployee = prefs.getInt('idEmployee');
      if (idEmployee == null) return;

      // Ambil data employee
      final response = await Dio().get(
        'http://192.168.100.140:5555/api/Employees/$idEmployee',
        options: Options(headers: {'accept': 'text/plain'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final user = response.data;

        // Data Pegawai
        namaKaryawanController.text = user['EmployeeName'] ?? '';
        nikPegawaiController.text = user['EmployeeNo'] ?? '';
        tempatLahirKaryawanController.text = user['BirthPlace'] ?? '';
        tanggalLahirKaryawanController.text = user['BirthDate'] ?? '';
        alamatKaryawanController.text = user['LivingArea'] ?? '';
        tglMulaiKerjaController.text = user['ServiceDate'] ?? '';
        jabatanTerakhirController.text = user['JobTitle'] ?? '';
        idEslController.text = user['IdEsl']?.toString() ?? '';
        tahunController.text = DateTime.now().year.toString();

        // Data Perusahaan (jika ada di API)
        namaPerusahaanController.text = user['CompanyName'] ?? '';
        alamatPerusahaanController.text = user['CompanyAddress'] ?? '';

        // Data Unit/Departement/Section
        sectionController.text = user['SectionName'] ?? '';
        plandivController.text = user['PlantDivisionName'] ?? '';
        departementController.text = user['DepartementName'] ?? '';
        unitController.text = user['UnitName'] ?? '';
        idSectionController.text = user['IdSection']?.toString() ?? '';

        // Data Atasan (ambil dari field Atasan di API employee, BUKAN dari Section/PIC)
        namaAtasanController.text = user['AtasanName'] ?? '';
        jabatanAtasanController.text = user['AtasanJobTitle'] ?? '';

        // Data Pasangan
        final List familyEmployees = user['FamilyEmployees'] ?? [];
        final pasangan = familyEmployees.isNotEmpty ? familyEmployees[0] : null;
        if (pasangan != null) {
          namaPasanganController.text = pasangan['NamaPasangan'] ?? '';
          statusPasanganController.text = pasangan['StatusPasangan'] ?? '';
          tempatLahirPasanganController.text = pasangan['AlamatPasangan'] ?? '';
          tanggalLahirPasanganController.text = pasangan['TglLahirPasangan'] ?? '';
        } else {
          namaPasanganController.clear();
          statusPasanganController.clear();
          tempatLahirPasanganController.clear();
          tanggalLahirPasanganController.clear();
        }

        // Data Anak
        final List children = pasangan != null && pasangan['Children'] != null
            ? pasangan['Children'] as List
            : [];
        if (children.isNotEmpty) {
          namaAnak1Controller.text = children.length > 0 ? (children[0]['NamaAnak'] ?? '') : '';
          ttlAnak1Controller.text = children.length > 0 ? (children[0]['TglLahirAnak'] ?? '') : '';
          tempatLahirAnak1Controller.text = children.length > 0 ? (children[0]['TempatLahirAnak'] ?? '') : '';
          pendidikanAnak1Controller.text = children.length > 0 ? (children[0]['PendidikanAnak'] ?? '') : '';
          namaAnak2Controller.text = children.length > 1 ? (children[1]['NamaAnak'] ?? '') : '';
          ttlAnak2Controller.text = children.length > 1 ? (children[1]['TglLahirAnak'] ?? '') : '';
          tempatLahirAnak2Controller.text = children.length > 1 ? (children[1]['TempatLahirAnak'] ?? '') : '';
          pendidikanAnak2Controller.text = children.length > 1 ? (children[1]['PendidikanAnak'] ?? '') : '';
          namaAnak3Controller.text = children.length > 2 ? (children[2]['NamaAnak'] ?? '') : '';
          ttlAnak3Controller.text = children.length > 2 ? (children[2]['TglLahirAnak'] ?? '') : '';
          tempatLahirAnak3Controller.text = children.length > 2 ? (children[2]['TempatLahirAnak'] ?? '') : '';
          pendidikanAnak3Controller.text = children.length > 2 ? (children[2]['PendidikanAnak'] ?? '') : '';
        } else {
          namaAnak1Controller.clear();
          ttlAnak1Controller.clear();
          tempatLahirAnak1Controller.clear();
          pendidikanAnak1Controller.clear();
          namaAnak2Controller.clear();
          ttlAnak2Controller.clear();
          tempatLahirAnak2Controller.clear();
          pendidikanAnak2Controller.clear();
          namaAnak3Controller.clear();
          ttlAnak3Controller.clear();
          tempatLahirAnak3Controller.clear();
          pendidikanAnak3Controller.clear();
        }

        // Data ESL (jika perlu ambil dari API lain, lakukan di sini)
        if (idEslController.text.isNotEmpty) {
          final eslResp = await Dio().get(
            'http://192.168.100.140:5555/api/Esls',
            options: Options(headers: {'accept': 'text/plain'}),
          );
          if (eslResp.statusCode == 200 && eslResp.data is List) {
            final List esls = eslResp.data;
            final esl = esls.firstWhere(
              (e) => e['Id'].toString() == idEslController.text,
              orElse: () => null,
            );
            if (esl != null) {
              namaEslController.text = esl['Jabatan'] ?? '';
            }
          }
        }
      }
      setState(() {});
    } catch (e) {
      print('Gagal fetch data employee: $e');
    }
  }

  String? selectedJenisSurat;
  final _formKey = GlobalKey<FormState>();

  // Controller untuk field wajib
  final TextEditingController namaAtasanController = TextEditingController();
  final TextEditingController jabatanAtasanController = TextEditingController();
  final TextEditingController namaPerusahaanController = TextEditingController();
  final TextEditingController alamatPerusahaanController = TextEditingController();
  final TextEditingController namaKaryawanController = TextEditingController();
  final TextEditingController tempatLahirKaryawanController = TextEditingController();
  final TextEditingController tanggalLahirKaryawanController = TextEditingController();
  final TextEditingController alamatKaryawanController = TextEditingController();
  final TextEditingController tglMulaiKerjaController = TextEditingController();
  final TextEditingController jabatanTerakhirController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();

  // Controller untuk pasangan & anak (opsional)
  final TextEditingController namaPasanganController = TextEditingController();
  final TextEditingController statusPasanganController = TextEditingController();
  final TextEditingController tempatLahirPasanganController = TextEditingController();
  final TextEditingController tanggalLahirPasanganController = TextEditingController();

  final TextEditingController namaAnak1Controller = TextEditingController();
  final TextEditingController ttlAnak1Controller = TextEditingController();
  final TextEditingController namaAnak2Controller = TextEditingController();
  final TextEditingController ttlAnak2Controller = TextEditingController();
  final TextEditingController namaAnak3Controller = TextEditingController();
  final TextEditingController ttlAnak3Controller = TextEditingController();

  // Tambahkan controller baru untuk Unit dan Tanggal Surat
  final TextEditingController unitController = TextEditingController();
  final TextEditingController tanggalSuratController = TextEditingController();

  // Controller tambahan untuk Surat Pernyataan
  final TextEditingController idEslController = TextEditingController();
  final TextEditingController namaEslController = TextEditingController();
  final TextEditingController plandivController = TextEditingController();
  final TextEditingController departementController = TextEditingController();
  final TextEditingController tahunController = TextEditingController();
  final TextEditingController namaSuamiController = TextEditingController();
  final TextEditingController tempatLahirSuamiController = TextEditingController();
  final TextEditingController tanggalLahirSuamiController = TextEditingController();
  final TextEditingController bidangUsahaController = TextEditingController();
  final TextEditingController tempatLahirAnak1Controller = TextEditingController();
  final TextEditingController pendidikanAnak1Controller = TextEditingController();
  final TextEditingController tempatLahirAnak2Controller = TextEditingController();
  final TextEditingController pendidikanAnak2Controller = TextEditingController();
  final TextEditingController tempatLahirAnak3Controller = TextEditingController();
  final TextEditingController pendidikanAnak3Controller = TextEditingController();

  // 1. Tambahkan controller baru
  final TextEditingController nikPegawaiController = TextEditingController();
  final TextEditingController tanggalSuamiController = TextEditingController();
  final TextEditingController idSectionController = TextEditingController();

  @override
  void dispose() {
    // Dispose semua controller
    namaAtasanController.dispose();
    jabatanAtasanController.dispose();
    namaPerusahaanController.dispose();
    alamatPerusahaanController.dispose();
    namaKaryawanController.dispose();
    tempatLahirKaryawanController.dispose();
    tanggalLahirKaryawanController.dispose();
    alamatKaryawanController.dispose();
    tglMulaiKerjaController.dispose();
    jabatanTerakhirController.dispose();
    sectionController.dispose();
    namaPasanganController.dispose();
    statusPasanganController.dispose();
    tempatLahirPasanganController.dispose();
    tanggalLahirPasanganController.dispose();
    namaAnak1Controller.dispose();
    ttlAnak1Controller.dispose();
    namaAnak2Controller.dispose();
    ttlAnak2Controller.dispose();
    namaAnak3Controller.dispose();
    ttlAnak3Controller.dispose();
    // Dispose controller baru
    unitController.dispose();
    tanggalSuratController.dispose();
    nikPegawaiController.dispose();
    tanggalSuamiController.dispose();
    idSectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          'Pembuatan Surat Medic',
          style: TextStyle(color: Colors.white),
        ),
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
                  children: const [
                    Icon(
                      Icons.note,
                      size: 40,
                      color: Color(0xFF1572E8),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instruksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Silakan pilih jenis surat pada dropdown di bawah, kemudian isi data yang diperlukan pada form sesuai jenis surat yang dipilih.',
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

              // Card berisi dua menu
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul dengan icon di kiri
                      Row(
                        children: const [
                          Icon(Icons.edit_document, color: Color(0xFF1572E8), size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Pembuatan Surat Medis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1572E8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown pengganti menu
                      Row(
                        children: [
                          const Icon(Icons.menu_book, color: Color(0xFF1572E8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Pilih Jenis Surat',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              value: selectedJenisSurat,
                              items: const [
                                DropdownMenuItem(
                                  value: 'keterangan',
                                  child: Text('Surat Keterangan'),
                                ),
                                DropdownMenuItem(
                                  value: 'pernyataan',
                                  child: Text('Surat Pernyataan'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedJenisSurat = value;
                                });
                                // Jika ingin menambah logic validasi, tambahkan di sini nanti.
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // =====================
                      // FORM SURAT KETERANGAN
                      // =====================
                      if (selectedJenisSurat == 'keterangan')
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // === Data Atasan ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.person, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Atasan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAtasanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Atasan *',
                                          prefixIcon: Icon(Icons.badge_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: jabatanAtasanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Jabatan Atasan *',
                                          prefixIcon: Icon(Icons.work_outline),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Perusahaan ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.business, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Perusahaan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaPerusahaanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Perusahaan *',
                                          prefixIcon: Icon(Icons.apartment),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: alamatPerusahaanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Alamat Perusahaan *',
                                          prefixIcon: Icon(Icons.location_on_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: unitController,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit *',
                                          prefixIcon: Icon(Icons.account_tree_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Karyawan ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.account_circle, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Karyawan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaKaryawanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Karyawan *',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // Tambahkan ini
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirKaryawanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Karyawan *',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalLahirKaryawanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Karyawan *',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: tanggalLahirKaryawanController.text.isNotEmpty
                                                ? DateTime.tryParse(tanggalLahirKaryawanController.text) ?? DateTime.now()
                                                : DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            tanggalLahirKaryawanController.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: alamatKaryawanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Alamat Karyawan *',
                                          prefixIcon: Icon(Icons.home_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tglMulaiKerjaController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Mulai Kerja *',
                                          prefixIcon: Icon(Icons.date_range_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: jabatanTerakhirController,
                                        decoration: const InputDecoration(
                                          labelText: 'Jabatan Terakhir *',
                                          prefixIcon: Icon(Icons.work_history_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: sectionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Section *',
                                          prefixIcon: Icon(Icons.layers_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalSuratController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Surat',
                                          prefixIcon: Icon(Icons.event_note_outlined),
                                        ),
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Pasangan (WAJIB) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.family_restroom, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Pasangan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaPasanganController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Pasangan *',
                                          prefixIcon: Icon(Icons.person_2_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: statusPasanganController,
                                        decoration: const InputDecoration(
                                          labelText: 'Status Pasangan (Suami/Istri) *',
                                          prefixIcon: Icon(Icons.transgender),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirPasanganController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Pasangan *',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalLahirPasanganController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Pasangan *',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: tanggalLahirPasanganController.text.isNotEmpty
                                                ? DateTime.tryParse(tanggalLahirPasanganController.text) ?? DateTime.now()
                                                : DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            tanggalLahirPasanganController.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 1 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Pertama (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Pertama',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Pertama',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Pertama',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak1Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Pertama',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 2 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Kedua (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Kedua',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Kedua',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Kedua',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak2Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Kedua',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 3 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Ketiga (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Ketiga',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Ketiga',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Ketiga',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak3Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Ketiga',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Lainnya ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.info, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Lainnya',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: unitController,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit *',
                                          prefixIcon: Icon(Icons.account_tree_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalSuratController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Surat',
                                          prefixIcon: Icon(Icons.event_note_outlined),
                                        ),
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Tombol Kirim Data
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: isSending
                                    ? null
                                    : () async {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          setState(() {
                                            isSending = true;
                                          });
                                          try {
                                            final prefs = await SharedPreferences.getInstance();
                                            final idEmployee = prefs.getInt('idEmployee');
                                            if (idEmployee == null) {
                                              throw Exception('ID Employee tidak ditemukan. Harap login ulang.');
                                            }

                                            // Tampilkan loading dialog
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => AlertDialog(
                                                content: Row(
                                                  children: const [
                                                    SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Expanded(
                                                      child: Text(
                                                        'Mohon tunggu, surat sedang diproses...',
                                                        style: TextStyle(fontSize: 15),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );

                                            // Tentukan endpoint dan data sesuai jenis surat
                                            String jenisSurat = selectedJenisSurat ?? 'keterangan';
                                            String url =
                                                'http://192.168.100.140:5555/api/Medical/generate-medical-document?jenisSurat=$jenisSurat';

                                            Map<String, dynamic> data;
                                            if (jenisSurat == 'pernyataan') {
                                              data = buildDataPernyataan(idEmployee: idEmployee);
                                            } else {
                                              data = buildDataKeterangan(idEmployee: idEmployee);
                                            }

                                            final response = await Dio().post(
                                              url,
                                              options: Options(
                                                headers: {
                                                  'accept': '*/*',
                                                  'Content-Type': 'application/json',
                                                },
                                                responseType: ResponseType.bytes,
                                              ),
                                              data: data,
                                            );

                                            Navigator.of(context).pop(); // Tutup dialog loading

                                            if (response.statusCode == 200) {
                                              final directory = Directory('/storage/emulated/0/Download');
                                              if (!directory.existsSync()) {
                                                directory.createSync(recursive: true);
                                              }
                                              final filePath = '${directory.path}/medical_$idEmployee.pdf';
                                              final file = File(filePath);
                                              await file.writeAsBytes(response.data!);

                                              setState(() {
                                                isDownloaded = true;
                                                isLoadingDownload = false;
                                                isDownloadEnabled = true;
                                              });

                                              // Tutup dropdown jika masih terbuka
                                              FocusScope.of(context).unfocus();

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('File berhasil didownload ke $filePath')),
                                              );

                                              // Reload halaman setelah download selesai
                                              Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) => const MedicPasutriPage(),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Gagal mengirim data: ${response.statusCode}')),
                                              );
                                            }
                                          } catch (e) {
                                            Navigator.of(context).pop(); // Tutup dialog loading jika error
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Terjadi kesalahan: $e')),
                                            );
                                          } finally {
                                            setState(() {
                                              isSending = false;
                                            });
                                          }
                                        } else {
                                          // Tampilkan popup jika ada field wajib yang belum diisi
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Lengkapi Data'),
                                              content: const Text('Silakan lengkapi semua data yang wajib diisi sebelum mengirim.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.description, color: Colors.white),
                                label: Text(
                                  selectedJenisSurat == 'pernyataan'
                                      ? 'Buat Surat Pernyataan'
                                      : 'Buat Surat Keterangan',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Keterangan di bawah tombol kirim data
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Data yang Anda isi akan dimasukkan ke dalam surat pernyataan.',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // =====================
                      // FORM SURAT PERNYATAAN
                      // =====================
                      if (selectedJenisSurat == 'pernyataan')
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // === Data Pegawai ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.account_circle, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Pegawai',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaKaryawanController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Pegawai *',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: nikPegawaiController,
                                        decoration: const InputDecoration(
                                          labelText: 'NIK Pegawai *',
                                          prefixIcon: Icon(Icons.credit_card),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: idEslController,
                                        decoration: const InputDecoration(
                                          labelText: 'ID ESL',
                                          prefixIcon: Icon(Icons.numbers),
                                        ),
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: namaEslController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama ESL',
                                          prefixIcon: Icon(Icons.badge),
                                        ),
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: plandivController,
                                        decoration: const InputDecoration(
                                          labelText: 'Plant Division',
                                          prefixIcon: Icon(Icons.factory),
                                        ),
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: departementController,
                                        decoration: const InputDecoration(
                                          labelText: 'Departement',
                                          prefixIcon: Icon(Icons.apartment),
                                        ),
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: sectionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Section',
                                          prefixIcon: Icon(Icons.layers),
                                        ),
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tahunController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tahun',
                                          prefixIcon: Icon(Icons.calendar_today),
                                        ),
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Suami ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.family_restroom, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Suami',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaSuamiController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Suami *',
                                          prefixIcon: Icon(Icons.person_2_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirSuamiController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Suami *',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalLahirSuamiController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Suami *',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: tanggalLahirSuamiController.text.isNotEmpty
                                                ? DateTime.tryParse(tanggalLahirSuamiController.text) ?? DateTime.now()
                                                : DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            tanggalLahirSuamiController.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: bidangUsahaController,
                                        decoration: const InputDecoration(
                                          labelText: 'Bidang Usaha Suami',
                                          prefixIcon: Icon(Icons.business_center_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalSuamiController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Berhenti Kerja Suami',
                                          prefixIcon: Icon(Icons.event_busy),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            tanggalSuamiController.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 1 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Pertama (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Pertama',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Pertama',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Pertama',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak1Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak1Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Pertama',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 2 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Kedua (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Kedua',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Kedua',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Kedua',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak2Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak2Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Kedua',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Anak 3 (Opsional) ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.child_care, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Anak Ketiga (Opsional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: namaAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Anak Ketiga',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tempatLahirAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tempat Lahir Anak Ketiga',
                                          prefixIcon: Icon(Icons.place_outlined),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: ttlAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Lahir Anak Ketiga',
                                          prefixIcon: Icon(Icons.cake_outlined),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            ttlAnak3Controller.text =
                                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                          }
                                        },
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: pendidikanAnak3Controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Pendidikan Anak Ketiga',
                                          prefixIcon: Icon(Icons.school_outlined),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === Data Lainnya ===
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.info, color: Color(0xFF1572E8)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Data Lainnya',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xFF1572E8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      TextFormField(
                                        controller: unitController,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit *',
                                          prefixIcon: Icon(Icons.account_tree_outlined),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: tanggalSuratController,
                                        decoration: const InputDecoration(
                                          labelText: 'Tanggal Surat',
                                          prefixIcon: Icon(Icons.event_note_outlined),
                                        ),
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Tombol Kirim Data
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: isSending
                                    ? null
                                    : () async {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          setState(() {
                                            isSending = true;
                                          });
                                          try {
                                            final prefs = await SharedPreferences.getInstance();
                                            final idEmployee = prefs.getInt('idEmployee');
                                            if (idEmployee == null) {
                                              throw Exception('ID Employee tidak ditemukan. Harap login ulang.');
                                            }

                                            // Tampilkan loading dialog
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => AlertDialog(
                                                content: Row(
                                                  children: const [
                                                    SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Expanded(
                                                      child: Text(
                                                        'Mohon tunggu, surat sedang diproses...',
                                                        style: TextStyle(fontSize: 15),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );

                                            String url =
                                                'http://192.168.100.140:5555/api/Medical/generate-medical-document?jenisSurat=pernyataan';

                                            final data = buildDataPernyataan(idEmployee: idEmployee);

                                            final response = await Dio().post(
                                              url,
                                              options: Options(
                                                headers: {
                                                  'accept': '*/*',
                                                  'Content-Type': 'application/json',
                                                },
                                                responseType: ResponseType.bytes,
                                              ),
                                              data: data,
                                            );

                                            Navigator.of(context).pop(); // Tutup dialog loading

                                            if (response.statusCode == 200) {
                                              final directory = Directory('/storage/emulated/0/Download');
                                              if (!directory.existsSync()) {
                                                directory.createSync(recursive: true);
                                              }
                                              final filePath = '${directory.path}/medical_$idEmployee.pdf';
                                              final file = File(filePath);
                                              await file.writeAsBytes(response.data!);

                                              setState(() {
                                                isDownloaded = true;
                                                isLoadingDownload = false;
                                                isDownloadEnabled = true;
                                              });

                                              FocusScope.of(context).unfocus();

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('File berhasil didownload ke $filePath')),
                                              );

                                              Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) => const MedicPasutriPage(),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Gagal mengirim data: ${response.statusCode}')),
                                              );
                                            }
                                          } catch (e) {
                                            Navigator.of(context).pop(); // Tutup dialog loading jika error
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Terjadi kesalahan: $e')),
                                            );
                                          } finally {
                                            setState(() {
                                              isSending = false;
                                            });
                                          }
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Lengkapi Data'),
                                              content: const Text('Silakan lengkapi semua data yang wajib diisi sebelum mengirim.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.description, color: Colors.white),
                                label: const Text(
                                  'Buat Surat Pernyataan',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Data yang Anda isi akan dimasukkan ke dalam surat pernyataan.',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Semua Future<void> di bawah ini hanya ADA SATU KALI dan di dalam class ---

  Future<void> isiIdEslDanNamaEslDariEmployee(int idEmployee) async {
    try {
      final empResp = await Dio().get(
        'http://192.168.100.140:5555/api/Employees/$idEmployee',
        options: Options(headers: {'accept': 'text/plain'}),
      );
      if (empResp.statusCode == 200 && empResp.data != null) {
        final idEsl = empResp.data['IdEsl']?.toString() ?? '';
        idEslController.text = idEsl;
        nikPegawaiController.text = empResp.data['EmployeeNo'] ?? '';

        if (idEsl.isNotEmpty) {
          final eslResp = await Dio().get(
            'http://192.168.100.140:5555/api/Esls',
            options: Options(headers: {'accept': 'text/plain'}),
          );
          if (eslResp.statusCode == 200 && eslResp.data is List) {
            final List esls = eslResp.data;
            final esl = esls.firstWhere(
              (e) => e['Id'].toString() == idEsl,
              orElse: () => null,
            );
            if (esl != null) {
              namaEslController.text = esl['Jabatan'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      namaEslController.text = '';
      idEslController.text = '';
      nikPegawaiController.text = '';
    }
  }

  Future<void> isiPlandivDanDepartementDariEmployee(int idEmployee) async {
    try {
      final empResp = await Dio().get(
        'http://192.168.100.140:5555/api/Employees/$idEmployee',
        options: Options(headers: {'accept': 'text/plain'}),
      );
      if (empResp.statusCode == 200 && empResp.data != null) {
        final idSection = empResp.data['IdSection']?.toString() ?? '';
        if (idSection.isNotEmpty) {
          final unitsResp = await Dio().get(
            'http://192.168.100.140:5555/api/Units',
            options: Options(headers: {'accept': 'text/plain'}),
          );
          if (unitsResp.statusCode == 200 && unitsResp.data is List) {
            final List units = unitsResp.data;
            String? plandiv, departement, section;
            for (final unit in units) {
              if (unit['PlantDivisions'] is List) {
                for (final pd in unit['PlantDivisions']) {
                  if (pd['Departements'] is List) {
                    for (final dept in pd['Departements']) {
                      if (dept['Sections'] is List) {
                        for (final sec in dept['Sections']) {
                          if (sec['IdSection']?.toString() == idSection) {
                            plandiv = pd['NamaPlantDivision'];
                            departement = dept['NamaDepartement'];
                            section = sec['NamaSection'];
                            break;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            plandivController.text = plandiv ?? '';
            departementController.text = departement ?? '';
            sectionController.text = section ?? '';
          }
        }
      }
    } catch (e) {
      plandivController.text = '';
      departementController.text = '';
      sectionController.text = '';
    }
  }

  Future<void> isiOtomatisDataSuamiDanAnak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmployee = prefs.getInt('idEmployee');
      if (idEmployee == null) return;

      final response = await Dio().get(
        'http://192.168.100.140:5555/api/Employees/$idEmployee',
        options: Options(headers: {'accept': 'text/plain'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List familyEmployees = response.data['FamilyEmployees'] ?? [];
        final pasangan = familyEmployees.isNotEmpty ? familyEmployees[0] : null;

        if (pasangan != null) {
          namaSuamiController.text = pasangan['NamaPasangan'] ?? '';
          tanggalLahirSuamiController.text = pasangan['TglLahirPasangan'] ?? '';

          final List children = pasangan['Children'] ?? [];
          pendidikanAnak1Controller.text = children.length > 0 ? (children[0]['PendidikanAnak'] ?? '') : '';
          pendidikanAnak2Controller.text = children.length > 1 ? (children[1]['PendidikanAnak'] ?? '') : '';
          pendidikanAnak3Controller.text = children.length > 2 ? ( children[2]['PendidikanAnak'] ?? '') : '';
        }
      }
    } catch (e) {
      namaSuamiController.text = '';
      tanggalLahirSuamiController.text = '';
      pendidikanAnak1Controller.text = '';
      pendidikanAnak2Controller.text = '';
      pendidikanAnak3Controller.text = '';
    }
  }

  Future<void> isiOtomatisAtasanPICDariSection() async {
  try {
    final idSection = idSectionController.text; // Pastikan sudah diisi dari data employee
    if (idSection.isEmpty) return;

    final response = await Dio().get(
      'http://192.168.100.140:5555/api/Sections',
      options: Options(headers: {'accept': 'text/plain'}),
    );

    if (response.statusCode == 200 && response.data is List) {
      final List sections = response.data;
      // Cari section dengan Id yang sama
      final section = sections.firstWhere(
        (s) => (s['Id']?.toString() ?? '') == idSection,
        orElse: () => null,
      );
      if (section != null && section['Employees'] is List) {
        // Cari employee dengan JobTitle "PIC"
        final pic = (section['Employees'] as List).firstWhere(
          (e) => (e['JobTitle'] ?? '').toString().toUpperCase() == 'PIC',
          orElse: () => null,
        );
        if (pic != null) {
          namaAtasanController.text = pic['EmployeeName'] ?? '';
          jabatanAtasanController.text = pic['JobTitle'] ?? '';
        }
      }
    }
  } catch (e) {
    namaAtasanController.text = '';
    jabatanAtasanController.text = '';
  }
}

  Map<String, dynamic> buildDataPernyataan({
    required int idEmployee,
  }) {
    return {
      "{{id_employee}}": idEmployee.toString(),
      "{{nik_pegawai}}": nikPegawaiController.text,
      "{{nama_pemberi_keterangan}}": namaAtasanController.text,
      "{{jabatan_pemberi_keterangan}}": jabatanAtasanController.text,
      "{{nama_perusahaan}}": namaPerusahaanController.text,
      "{{alamat_perusahaan}}": alamatPerusahaanController.text,
      "{{nama_pegawai}}": namaKaryawanController.text,


      "{{id_esl_pegawai}}": idEslController.text,
      "{{nama_esl}}": namaEslController.text,
      "{{plandiv}}": plandivController.text,
      "{{departement}}": departementController.text,
      "{{section}}": sectionController.text,
      "{{tahun}}": tahunController.text,
      "{{nama_suami}}": namaSuamiController.text,
      "{{tempat_lahir_suami}}": tempatLahirSuamiController.text,
      "{{ttl_suami}}": tanggalLahirSuamiController.text,
      "{{tanggal_suami}}": tanggalSuamiController.text,
      "{{usaha_suami}}": bidangUsahaController.text,
      // Data Anak 1
      "{{nama_anak1}}": namaAnak1Controller.text,
      "{{tempat_lahir_anak1}}": tempatLahirAnak1Controller.text,
      "{{ttl_anak1}}": ttlAnak1Controller.text,
      "{{pendidikan_anak1}}": pendidikanAnak1Controller.text,
      // Data Anak 2
      "{{nama_anak2}}": namaAnak2Controller.text,
      "{{tempat_lahir_anak2}}": tempatLahirAnak2Controller.text,
      "{{ttl_anak2}}": ttlAnak2Controller.text,
      "{{pendidikan_anak2}}": pendidikanAnak2Controller.text,
      // Data Anak 3
      "{{nama_anak3}}": namaAnak3Controller.text,
      "{{tempat_lahir_anak3}}": tempatLahirAnak3Controller.text,
      "{{ttl_anak3}}": ttlAnak3Controller.text,
      "{{pendidikan_anak3}}": pendidikanAnak3Controller.text,
      // Data Unit & Tanggal Surat
      "{{Unit}}": unitController.text,
      "{{tanggal_surat}}": tanggalSuratController.text,
    };
  }

  Map<String, dynamic> buildDataKeterangan({
    required int idEmployee,
  }) {
    return {
      "{{id_employee}}": idEmployee.toString(),
      "{{nama_pemberi_keterangan}}": namaAtasanController.text,
      "{{jabatan_pemberi_keterangan}}": jabatanAtasanController.text,
      "{{nama_perusahaan}}": namaPerusahaanController.text,
      "{{alamat_perusahaan}}": alamatPerusahaanController.text,
      "{{Unit}}": unitController.text,
      "{{nama_pegawai}}": namaKaryawanController.text,
      "{{tempat_lahir_pegawai}}": tempatLahirKaryawanController.text,
      "{{tanggal_lahir_pegawai}}": tanggalLahirKaryawanController.text,
      "{{alamat_pegawai}}": alamatKaryawanController.text,
      "{{tanggal_mulai_kerja}}": tglMulaiKerjaController.text,
      "{{jabatan_terakhir}}": jabatanTerakhirController.text,
      "{{section}}": sectionController.text,
      "{{status_pasangan}}": statusPasanganController.text,
      "{{nama_pasangan}}": namaPasanganController.text,
      "{{tempat_lahir_pasangan}}": tempatLahirPasanganController.text,
      "{{ttl_pasangan}}": tanggalLahirPasanganController.text,
      // Data Anak 1
      "{{nama_anak1}}": namaAnak1Controller.text,
      "{{tempat_lahir_anak1}}": tempatLahirAnak1Controller.text,
      "{{ttl_anak1}}": ttlAnak1Controller.text,
      "{{pendidikan_anak1}}": pendidikanAnak1Controller.text,
      // Data Anak 2
      "{{nama_anak2}}": namaAnak2Controller.text,
      "{{tempat_lahir_anak2}}": tempatLahirAnak2Controller.text,
      "{{ttl_anak2}}": ttlAnak2Controller.text,
      "{{pendidikan_anak2}}": pendidikanAnak2Controller.text,
      // Data Anak 3
      "{{nama_anak3}}": namaAnak3Controller.text,
      "{{tempat_lahir_anak3}}": tempatLahirAnak3Controller.text,
      "{{ttl_anak3}}": ttlAnak3Controller.text,
      "{{pendidikan_anak3}}": pendidikanAnak3Controller.text,
      "{{tanggal_surat}}": tanggalSuratController.text,
    };
  }

  Future<void> fetchAndSaveIdEmployeeFromEmployee(int idEmployee) async {
  try {
    final response = await Dio().get(
      'http://192.168.100.140:5555/api/Employees/$idEmployee',
      options: Options(headers: {'accept': 'text/plain'}),
    );

    if (response.statusCode == 200 && response.data != null) {
      final employee = response.data;
      final id = employee['id']; // atau 'Id'
      if (id != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('idEmployee', id);
        setState(() {});
      }
    }
  } catch (e) {
    // error handling
  }
}}