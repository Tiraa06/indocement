import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FileAktifPage extends StatefulWidget {
  const FileAktifPage({super.key});

  @override
  State<FileAktifPage> createState() => _FileAktifPageState();
}

class _FileAktifPageState extends State<FileAktifPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noFileController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();

  XFile? _selectedFile;
  int? _idEmployee;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _submissionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? idEmployee = prefs.getInt('idEmployee');

    if (idEmployee == null || idEmployee <= 0) {
      setState(() {
        _errorMessage = 'ID karyawan tidak valid. Silakan login ulang.';
        _employeeNameController.text = '';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees/$idEmployee'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employeeName = data['EmployeeName'] ?? 'Nama Tidak Diketahui';

        setState(() {
          _idEmployee = idEmployee;
          _employeeNameController.text = employeeName;
        });

        await prefs.setString('employeeName', employeeName);
        await prefs.setInt('idEmployee', idEmployee);
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data: ${response.statusCode}';
          _employeeNameController.text = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _employeeNameController.text = '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = pickedFile;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap lengkapi semua field dan pilih file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final idEmployee = prefs.getInt('idEmployee');

    if (idEmployee == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID Karyawan tidak ditemukan.';
      });
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://103.31.235.237:5555/api/FileAktif/request'),
      )
        ..headers['accept'] = '*/*'
        ..headers['Content-Type'] = 'multipart/form-data'
        ..fields['IdEmployee'] = idEmployee.toString()
        ..fields['NoFileAktif'] = _noFileController.text;

      final file = await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        filename: path.basename(_selectedFile!.path),
      );

      request.files.add(file);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        setState(() {
          _submissionHistory.add({
            'noFileAktif': _noFileController.text,
            'status': 'Pengajuan telah selesai',
            'url': jsonResponse['UrlFileAktif'],
            'date': DateTime.now().toString(),
          });
          _noFileController.clear();
          _selectedFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan File Aktif berhasil!')),
        );
      } else {
        setState(() {
          _submissionHistory.add({
            'noFileAktif': _noFileController.text,
            'status': 'Pengajuan sedang diproses',
            'url': null,
            'date': DateTime.now().toString(),
          });
          _noFileController.clear();
          _selectedFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan dikirim, sedang diproses')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengunggah: $e';
        _submissionHistory.add({
          'noFileAktif': _noFileController.text,
          'status': 'Pengajuan sedang diproses',
          'url': null,
          'date': DateTime.now().toString(),
        });
        _noFileController.clear();
        _selectedFile = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noFileController.dispose();
    _employeeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingValue = screenWidth * 0.04;
    final double baseFontSize = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengajuan File Aktif',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.25,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1572E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/banner_file_aktif.jpg',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Form Pengajuan File Aktif',
                    style: GoogleFonts.poppins(
                      fontSize: baseFontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: baseFontSize * 0.9,
                        ),
                      ),
                    ),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Karyawan',
                              style: GoogleFonts.poppins(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _employeeNameController,
                              readOnly: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nomor File Aktif',
                              style: GoogleFonts.poppins(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noFileController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan nomor file aktif',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nomor file aktif harus diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unggah File',
                              style: GoogleFonts.poppins(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                child: Center(
                                  child: _selectedFile == null
                                      ? Text(
                                          'Ketuk untuk memilih file',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                          ),
                                        )
                                      : Text(
                                          path.basename(_selectedFile!.path),
                                          style: GoogleFonts.poppins(),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1572E8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Ajukan',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: baseFontSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Riwayat Pengajuan',
                    style: GoogleFonts.poppins(
                      fontSize: baseFontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _submissionHistory.isEmpty
                      ? Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Belum ada pengajuan',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _submissionHistory.length,
                          itemBuilder: (context, index) {
                            final submission = _submissionHistory[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  submission['status'] ==
                                          'Pengajuan telah selesai'
                                      ? Icons.check_circle
                                      : Icons.hourglass_empty,
                                  color: submission['status'] ==
                                          'Pengajuan telah selesai'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                title: Text(
                                  'No. ${submission['noFileAktif']}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: baseFontSize,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      submission['status'],
                                      style: GoogleFonts.poppins(
                                        fontSize: baseFontSize * 0.9,
                                        color: submission['status'] ==
                                                'Pengajuan telah selesai'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Tanggal: ${submission['date'].substring(0, 10)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: baseFontSize * 0.8,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: submission['url'] != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Color(0xFF1572E8),
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Memulai unduhan...')));
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
