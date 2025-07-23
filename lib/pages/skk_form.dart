import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:indocement_apk/utils/network_helper.dart'; // Tambahkan import ini

class SkkFormPage extends StatefulWidget {
  const SkkFormPage({super.key});

  @override
  State<SkkFormPage> createState() => _SkkFormPageState();
}

class _SkkFormPageState extends State<SkkFormPage> {
  int? idEmployee;
  String? employeeName;
  String? employeeNo;
  final TextEditingController _keperluanController = TextEditingController();
  List<Map<String, dynamic>> skkData = [];
  bool isLoading = false;
  bool isEmployeeDataLoading = true;
  final String baseUrl = 'http://103.31.235.237:5555';
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

  Future<void> _loadEmployeeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEmployee = prefs.getInt('idEmployee');
      employeeName = prefs.getString('employeeName') ?? 'Nama Tidak Diketahui';
      employeeNo = prefs.getString('employeeNo') ?? 'NIK Tidak Diketahui';
      isEmployeeDataLoading = false;
    });

    // Fetch employee data regardless of what's in SharedPreferences to ensure freshness
    await _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? employeeId = prefs.getInt('idEmployee');

    if (employeeId == null || employeeId <= 0) {
      if (mounted) {
        _showPopup(
            context, 'Gagal', 'ID karyawan tidak valid, silakan login ulang');
        Navigator.pushReplacementNamed(
            context, '/login'); // Adjust based on your app's navigation setup
      }
      return;
    }

    setState(() {
      isEmployeeDataLoading = true;
    });

    try {
      final response = await safeRequest(
        context,
        () => http.get(
          Uri.parse('$baseUrl/api/Employees/$employeeId'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response == null) return; // Sudah redirect ke error

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          employeeName =
              data['EmployeeName']?.toString() ?? 'Nama Tidak Diketahui';
          employeeNo = data['EmployeeNo']?.toString() ?? 'NIK Tidak Diketahui';
          idEmployee = employeeId;
          isEmployeeDataLoading = false;
        });

        // Save to SharedPreferences for future use
        await prefs.setInt('idEmployee', idEmployee!);
        await prefs.setString('employeeName', employeeName!);
        await prefs.setString('employeeNo', employeeNo!);
      } else {
        if (mounted) {
          _showPopup(context, 'Gagal',
              'Gagal memuat data karyawan: ${response.statusCode}');
          setState(() {
            isEmployeeDataLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(context, 'Gagal', 'Terjadi kesalahan: $e');
        setState(() {
          isEmployeeDataLoading = false;
        });
      }
    }
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

      if (response.statusCode == 200 && mounted) {
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
      if (mounted) {
        _showPopup(context, 'Error', 'Gagal mengambil data SKK: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
        if (mounted) {
          _showPopup(context, 'Berhasil', 'Pengajuan SKK berhasil dikirim.');
          _keperluanController.clear();
          await _fetchSkkData();
        }
      } else {
        if (mounted) {
          _showPopup(context, 'Gagal',
              'Gagal mengirim pengajuan: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(context, 'Gagal', 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    return true;
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

        final filePath = '${dir.path}/skk-$noSkk.pdf';
        final file = File(filePath);

        final httpResponse = await http.get(Uri.parse(url));
        if (httpResponse.statusCode == 200) {
          await file.writeAsBytes(httpResponse.bodyBytes);
          if (mounted) {
            _showPopup(context, 'Berhasil',
                'File telah diunduh ke: $filePath${isExternal ? ' (akses di folder Downloads)' : ' (di dalam aplikasi, gunakan file manager untuk melihat)'}');

            final result = await OpenFile.open(filePath);
            if (result.type != ResultType.done) {
              _showPopup(context, 'Gagal',
                  'Tidak dapat membuka file: ${result.message}');
            }
          }
        } else {
          if (mounted) {
            _showPopup(context, 'Gagal',
                'Gagal mengunduh file: ${httpResponse.statusCode} - ${httpResponse.reasonPhrase}');
          }
        }
      } else {
        if (mounted) {
          _showPopup(context, 'Gagal',
              'Gagal mengakses file: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(context, 'Gagal', 'Terjadi kesalahan saat mengunduh: $e');
      }
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

  void _showReturnModal(BuildContext context, String keperluan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pengajuan Ditolak'),
          content: const Text('Silahkan mengajukan ulang permintaan SKK ini'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _keperluanController.text = keperluan;
                });
              },
              child: const Text('Ajukan Ulang'),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1572E8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surat Keterangan Kerja',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajukan surat keterangan kerja untuk keperluan Anda.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Form Pengajuan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nama Karyawan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      isEmployeeDataLoading
                          ? const Text(
                              'Memuat...',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            )
                          : Text(
                              employeeName ?? 'Nama Tidak Diketahui',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                      const SizedBox(height: 16),
                      const Text(
                        'NIK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      isEmployeeDataLoading
                          ? const Text(
                              'Memuat...',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            )
                          : Text(
                              employeeNo ?? 'NIK Tidak Diketahui',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                      const SizedBox(height: 16),
                      const Text(
                        'Keperluan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keperluanController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF1572E8), width: 2),
                          ),
                          hintText: 'Masukkan keperluan SKK',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isEmployeeDataLoading ? null : _submitSkk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1572E8),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isEmployeeDataLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
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
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Pengajuan SKK',
                        style: TextStyle(
                          fontSize: 18,
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
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: skkData.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 24,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                          itemBuilder: (context, index) {
                            final data = skkData[index];
                            print(
                                'Keperluan [$index]: ${data['Keperluan']?.toString() ?? 'Tidak diketahui'}');
                            print(
                                'Status [$index]: ${data['Status']?.toString() ?? 'Tidak diketahui'}');
                            print(
                                'UrlSkk [$index]: ${data['UrlSkk']?.toString() ?? 'Tidak ada'}');

                            Color statusColor;
                            bool isClickable = false;
                            switch (data['Status']?.toString().toLowerCase()) {
                              case 'diajukan':
                                statusColor = Colors.grey;
                                break;
                              case 'diapprove':
                                statusColor = Colors.green;
                                break;
                              case 'return':
                                statusColor = Colors.red;
                                isClickable = true;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message:
                                            data['Keperluan']?.toString() ??
                                                'Tidak diketahui',
                                        child: Text(
                                          'Keperluan: ${data['Keperluan']?.toString() ?? 'Tidak diketahui'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (data['Status']?.toLowerCase() ==
                                            'diapprove' &&
                                        data['UrlSkk'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.download,
                                            color: Color(0xFF1572E8),
                                            size: 24,
                                          ),
                                          onPressed: () => _downloadSkk(
                                            data['NoSkk'],
                                            data['UrlSkk'],
                                          ),
                                          tooltip: 'Download SKK',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: isClickable
                                      ? () => _showReturnModal(
                                            context,
                                            data['Keperluan']?.toString() ?? '',
                                          )
                                      : null,
                                  child: Text(
                                    'Status: ${data['Status'] ?? 'Tidak diketahui'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: statusColor,
                                      fontWeight: isClickable
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      decoration: isClickable
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
