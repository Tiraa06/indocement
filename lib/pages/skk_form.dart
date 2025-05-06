import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class SkkFormPage extends StatefulWidget {
  const SkkFormPage({super.key});

  @override
  State<SkkFormPage> createState() => _SkkFormPageState();
}

class _SkkFormPageState extends State<SkkFormPage> {
  int? idEmployee;
  String? employeeName;
  final TextEditingController _keperluanController = TextEditingController();
  List<Map<String, dynamic>> skkData = [];
  bool isLoading = false;
  final String baseUrl = 'http://213.35.123.110:5555';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    _loadSkkData();
    _fetchSkkData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _keperluanController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchSkkData();
      }
    });
  }

  void _loadEmployeeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
      employeeName = prefs.getString('employeeName') ?? 'Nama Tidak Diketahui';
    });
  }

  void _loadSkkData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? skkDataString = prefs.getString('skkData_$idEmployee');
    if (skkDataString != null) {
      try {
        final decodedData = jsonDecode(skkDataString);
        if (decodedData is List) {
          setState(() {
            skkData = List<Map<String, dynamic>>.from(decodedData)
                .where((data) => data['IdEmployee'] == idEmployee)
                .toList();
          });
        } else if (decodedData is Map) {
          if (decodedData['IdEmployee'] == idEmployee) {
            setState(() {
              skkData = [decodedData as Map<String, dynamic>];
            });
          } else {
            setState(() {
              skkData = [];
            });
          }
        }
      } catch (e) {
        setState(() {
          skkData = [];
        });
        print('Error decoding skkData: $e');
      }
    }
  }

  Future<void> _fetchSkkData() async {
    if (idEmployee == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/skk?IdEmployee=$idEmployee'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            skkData = List<Map<String, dynamic>>.from(data)
                .where((data) => data['IdEmployee'] == idEmployee)
                .toList();
            _saveSkkData();
          });
        }
      }
    } catch (e) {
      _showPopup(context, 'Error', 'Gagal mengambil data SKK: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _saveSkkData() async {
    if (idEmployee != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('skkData_$idEmployee', jsonEncode(skkData));
    }
  }

  Future<void> _submitSkk() async {
    if (idEmployee == null) {
      _showPopup(context, 'Gagal', 'ID karyawan tidak valid.');
      return;
    }

    if (_keperluanController.text.isEmpty) {
      _showPopup(context, 'Gagal', 'Keperluan harus diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/skk'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'IdEmployee': idEmployee,
          'Keperluan': _keperluanController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showPopup(context, 'Berhasil', 'Pengajuan SKK berhasil dikirim.');
        _keperluanController.clear();
        await _fetchSkkData();
      } else {
        _showPopup(context, 'Gagal',
            'Gagal mengirim pengajuan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showPopup(context, 'Gagal', 'Terjadi kesalahan: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          _showPermissionDeniedDialog();
          return false;
        }
      }

      if (Platform.version.split('.')[0].compareTo('11') >= 0 &&
          await Permission.manageExternalStorage.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
        return false;
      }
      return true;
    }
    return true; // iOS doesn't require explicit storage permission
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Ditolak'),
          content: const Text(
              'Izin penyimpanan ditolak. Silakan aktifkan izin di Pengaturan > Aplikasi > indocement_apk > Izin > Penyimpanan, lalu coba lagi.'),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Buka Pengaturan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadSkk(String? noSkk, String? urlSkk) async {
    if (noSkk == null || urlSkk == null) {
      _showPopup(context, 'Gagal', 'Data download tidak lengkap.');
      return;
    }

    final url = '$baseUrl$urlSkk';
    print('Attempting to download from: $url');

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      return;
    }

    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory dir;
        bool isExternal = false;
        if (Platform.isAndroid) {
          var status = await Permission.manageExternalStorage.status;
          if (status.isGranted) {
            dir = Directory('/storage/emulated/0/Download');
            isExternal = true;
          } else {
            dir = await getTemporaryDirectory();
          }
        } else if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          dir = await getTemporaryDirectory();
        }

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final filePath = '${dir.path}/skk-${noSkk}.pdf';
        final file = File(filePath);

        final httpResponse = await http.get(Uri.parse(url));
        if (httpResponse.statusCode == 200) {
          await file.writeAsBytes(httpResponse.bodyBytes);
          _showPopup(context, 'Berhasil',
              'File telah diunduh ke: $filePath${isExternal ? ' (akses di folder Downloads)' : ' (di dalam aplikasi, gunakan file manager untuk melihat)'}');

          final result = await OpenFile.open(filePath);
          if (result.type != ResultType.done) {
            _showPopup(context, 'Gagal',
                'Tidak dapat membuka file: ${result.message}');
          }
        } else {
          _showPopup(context, 'Gagal',
              'Gagal mengunduh file: ${httpResponse.statusCode} - ${httpResponse.reasonPhrase}');
        }
      } else {
        _showPopup(context, 'Gagal',
            'Gagal mengakses file: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      _showPopup(context, 'Gagal', 'Terjadi kesalahan saat mengunduh: $e');
    }
  }

  void _showPopup(BuildContext context, String title, String message) {
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

  Future<void> _refreshData() async {
    await _fetchSkkData();
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
        title: const Text(
          'Pengajuan SKK',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    border: Border.all(color: Colors.black, width: 1),
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
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surat Keterangan Kerja',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ajukan surat keterangan kerja untuk keperluan Anda.',
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
                if (skkData.isEmpty ||
                    skkData.any((data) => data['Status'] == 'Pending'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nama Karyawan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        employeeName ?? 'Memuat...',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Keperluan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keperluanController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan keperluan SKK',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitSkk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1572E8),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Ajukan SKK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1),
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
                        'Riwayat Pengajuan SKK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading && skkData.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (skkData.isEmpty)
                        const Text(
                          'Anda belum mengajukan SKK apapun.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        )
                      else
                        ...skkData
                            .map((data) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Keperluan: ${data['Keperluan'] ?? 'Tidak diketahui'}',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          'Status: ${data['Status'] ?? 'Tidak diketahui'}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    if (data['UrlSkk'] != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () => _downloadSkk(
                                              data['NoSkk'], data['UrlSkk']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1572E8),
                                            minimumSize:
                                                const Size(double.infinity, 40),
                                          ),
                                          child: const Text(
                                            'Download SKK',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                  ],
                                ))
                            .toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
