import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  List<dynamic> _submissionHistory = [];

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _fetchEmployeeData();
    await _fetchSubmissionHistory();
  }

  Future<void> _fetchEmployeeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? idEmployee = prefs.getInt('idEmployee');
    if (idEmployee == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees/$idEmployee'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _idEmployee = idEmployee;
          _employeeNameController.text = data['EmployeeName'] ?? '-';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat data karyawan: $e');
    }
  }

  Future<void> _fetchSubmissionHistory() async {
    if (_idEmployee == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/FileAktif'),
      );
      final List data = jsonDecode(response.body);
      final filtered = data
          .where((item) => item["IdEmployee"] == _idEmployee)
          .toList()
          .cast<dynamic>();
      setState(() {
        _submissionHistory = filtered;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat riwayat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final chosenFile = await picker.pickImage(source: ImageSource.gallery);
    if (chosenFile != null) {
      setState(() => _selectedFile = chosenFile);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lengkapi semua informasi dan unggah file.')));
      return;
    }

    final String noFile = _noFileController.text;
    final String fileName = path.basename(_selectedFile!.path);
    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://103.31.235.237:5555/api/FileAktif/request'),
      )
        ..fields['IdEmployee'] = _idEmployee.toString()
        ..fields['NoFileAktif'] = noFile
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path,
          filename: fileName,
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        _showPopup(context, 'Berhasil', 'Pengajuan berhasil dikirim.');
        _noFileController.clear();
        setState(() => _selectedFile = null);
        await _fetchSubmissionHistory();
      } else {
        _showPopup(context, 'Gagal', 'Pengajuan gagal. Coba lagi.');
      }
    } catch (e) {
      _showPopup(context, 'Error', 'Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi permintaan permission yang kompatibel Android 13+ dan versi lama
  Future<bool> _requestStoragePermission() async {
    final info = DeviceInfoPlugin();
    final androidInfo = await info.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+, minta izin READ_MEDIA_*
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      final audio = await Permission.audio.request();
      return photos.isGranted && videos.isGranted && audio.isGranted;
    } else {
      // Android 12 ke bawah, minta izin storage
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
  }

  Future<void> _downloadFileAktif(String? noFile, String? urlPath) async {
    if (noFile == null || urlPath == null) {
      _showPopup(context, 'Gagal', 'Data file tidak lengkap.');
      return;
    }

    final String baseUrl = 'http://103.31.235.237:5555';
    final String fullUrl = '$baseUrl$urlPath';

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showPopup(context, 'Gagal', 'Izin penyimpanan ditolak.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200) {
        _showPopup(context, 'Gagal', 'File tidak ditemukan di server.');
        setState(() => _isLoading = false);
        return;
      }

      Directory dir;
      if (Platform.isAndroid) {
        // Simpan di folder app-specific external dir yang aman di Android 10+
        dir = await getExternalStorageDirectory() ??
            await getTemporaryDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      String ext = path.extension(urlPath);
      if (ext.isEmpty) ext = '.pdf';

      final filePath = path.join(dir.path, 'fileaktif-$noFile$ext');
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      _showPopup(context, 'Berhasil', 'File berhasil diunduh ke:\n$filePath');

      await OpenFile.open(file.path);
    } catch (e) {
      _showPopup(context, 'Gagal', 'Gagal mengunduh file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'DiUpload':
        return Icons.upload_file;
      case 'Diproses':
        return Icons.hourglass_top;
      case 'Selesai':
        return Icons.check_circle;
      case 'Ditolak':
        return Icons.cancel;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'DiUpload':
        return Colors.blueGrey;
      case 'Diproses':
        return Colors.orange;
      case 'Selesai':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget formSection() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _employeeNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Karyawan',
                  filled: true,
                  fillColor: Color(0xFFF1F3F4),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noFileController,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                decoration: const InputDecoration(
                  labelText: 'Nomor File Aktif',
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _selectedFile == null
                        ? const Text("Ketuk untuk memilih file")
                        : Text(path.basename(_selectedFile!.path)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text("Ajukan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noFileController.dispose();
    _employeeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Aktif', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSubmissionHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Image.asset('assets/images/banner_file_aktif.jpg',
                      height: 180, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  formSection(),
                  const SizedBox(height: 20),
                  const Text(
                    "Riwayat Pengajuan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  if (_submissionHistory.isEmpty)
                    const Center(child: Text("Belum ada pengajuan."))
                  else
                    ..._submissionHistory.map((data) => Card(
                          child: ListTile(
                            leading: Icon(
                              _statusIcon(data['Status']),
                              color: _statusColor(data['Status']),
                            ),
                            title: Text(
                                'No: ${data['NoFileAktif'] ?? 'Tidak Ada'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${data['Status']}'),
                                Text(
                                    'Tanggal: ${data['CreatedAt']?.substring(0, 10) ?? ''}'),
                              ],
                            ),
                            trailing: (data['Status'] != 'DiUpload' &&
                                    data['UrlFileAktif'] != null)
                                ? IconButton(
                                    icon: const Icon(Icons.download,
                                        color: Color(0xFF1572E8)),
                                    onPressed: () {
                                      _downloadFileAktif(data['NoFileAktif'],
                                          data['UrlFileAktif']);
                                    },
                                  )
                                : null,
                          ),
                        )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
