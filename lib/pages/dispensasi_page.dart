import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indocement_apk/service/api_service.dart';
import 'package:path/path.dart' as path;

class DispensasiPage extends StatefulWidget {
  const DispensasiPage({super.key});

  @override
  _DispensasiPageState createState() => _DispensasiPageState();
}

class _DispensasiPageState extends State<DispensasiPage> {
  final _jenisDispensasiController = TextEditingController();
  final _keteranganController = TextEditingController();
  File? _suratKeteranganMeninggal;
  File? _ktp;
  File? _sim;
  File? _dokumenLain;
  bool _isLoading = false;

  @override
  void dispose() {
    _jenisDispensasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<bool> _checkNetwork() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print('No network connectivity');
      if (mounted) {
        _showErrorModal(
            'Tidak ada koneksi internet. Silakan cek jaringan Anda.');
      }
      return false;
    }
    return true;
  }

  void _showLoading(BuildContext context) {
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

  void _showErrorModal(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  'Gagal',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.red,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
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
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
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

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF1572E8),
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  'Berhasil',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF1572E8),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pengajuan dispensasi berhasil dikirim.',
                  style: GoogleFonts.poppins(
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
                      backgroundColor: const Color(0xFF1572E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context); // Return to previous screen
                    },
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
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

  Future<void> _pickFile(String field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        setState(() {
          switch (field) {
            case 'SuratKeteranganMeninggal':
              _suratKeteranganMeninggal = File(result.files.first.path!);
              break;
            case 'Ktp':
              _ktp = File(result.files.first.path!);
              break;
            case 'Sim':
              _sim = File(result.files.first.path!);
              break;
            case 'DokumenLain':
              _dokumenLain = File(result.files.first.path!);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorModal('Gagal memilih file: $e');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_jenisDispensasiController.text.trim().isEmpty) {
      if (mounted) {
        _showErrorModal('Jenis dispensasi tidak boleh kosong.');
      }
      return;
    }
    if (_keteranganController.text.trim().isEmpty) {
      if (mounted) {
        _showErrorModal('Keterangan tidak boleh kosong.');
      }
      return;
    }
    if (_suratKeteranganMeninggal == null) {
      if (mounted) {
        _showErrorModal('Surat Keterangan Meninggal wajib diunggah.');
      }
      return;
    }
    if (_ktp == null) {
      if (mounted) {
        _showErrorModal('KTP wajib diunggah.');
      }
      return;
    }
    if (_sim == null) {
      if (mounted) {
        _showErrorModal('SIM wajib diunggah.');
      }
      return;
    }

    if (!await _checkNetwork()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmployee = prefs.getInt('idEmployee');
      if (idEmployee == null || idEmployee <= 0) {
        if (mounted) {
          _showErrorModal('ID karyawan tidak valid. Silakan login ulang.');
        }
        setState(() => _isLoading = false);
        return;
      }

      final formData = FormData.fromMap({
        'IdEmployee': idEmployee.toString(),
        'JenisDispensasi': _jenisDispensasiController.text.trim(),
        'Keterangan': _keteranganController.text.trim(),
        if (_suratKeteranganMeninggal != null)
          'SuratKeteranganMeninggal': await MultipartFile.fromFile(
            _suratKeteranganMeninggal!.path,
            filename: path.basename(_suratKeteranganMeninggal!.path),
          ),
        if (_ktp != null)
          'Ktp': await MultipartFile.fromFile(
            _ktp!.path,
            filename: path.basename(_ktp!.path),
          ),
        if (_sim != null)
          'Sim': await MultipartFile.fromFile(
            _sim!.path,
            filename: path.basename(_sim!.path),
          ),
        if (_dokumenLain != null)
          'DokumenLain': await MultipartFile.fromFile(
            _dokumenLain!.path,
            filename: path.basename(_dokumenLain!.path),
          ),
      });

      _showLoading(context);

      final response = await ApiService.post(
        'http://103.31.235.237:5555/api/Dispensasi',
        data: formData,
        headers: {
          'Accept': 'application/json',
        },
        contentType: 'multipart/form-data',
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessModal();
        }
      } else {
        String errorMessage = 'Gagal mengajukan dispensasi';
        try {
          errorMessage = response.data['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.data.toString().isNotEmpty
              ? response.data.toString()
              : errorMessage;
        }
        if (mounted) {
          _showErrorModal(errorMessage);
        }
      }
    } catch (e) {
      print('Error: $e');
      Navigator.pop(context); // Close loading dialog if open
      if (mounted) {
        _showErrorModal('Terjadi kesalahan: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Pengajuan Dispensasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1572E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo2.png',
                        width: 200,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Pengajuan Dispensasi',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2035),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                      'Jenis Dispensasi', _jenisDispensasiController, 900),
                  _buildTextField('Keterangan', _keteranganController, 1000),
                  _buildFileField(
                    'Surat Keterangan Meninggal',
                    'SuratKeteranganMeninggal',
                    1100,
                  ),
                  _buildFileField('KTP', 'Ktp', 1200),
                  _buildFileField('SIM', 'Sim', 1300),
                  _buildFileField(
                      'Dokumen Lain (Opsional)', 'DokumenLain', 1400),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFF1572E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'KIRIM',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    int duration,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInLeft(
        duration: Duration(milliseconds: duration),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileField(String label, String field, int duration) {
    File? file;
    switch (field) {
      case 'SuratKeteranganMeninggal':
        file = _suratKeteranganMeninggal;
        break;
      case 'Ktp':
        file = _ktp;
        break;
      case 'Sim':
        file = _sim;
        break;
      case 'DokumenLain':
        file = _dokumenLain;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInLeft(
        duration: Duration(milliseconds: duration),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickFile(field),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        file != null
                            ? path.basename(file.path)
                            : 'Pilih file (JPG, PNG, PDF)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: file != null ? Colors.black : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.upload_file,
                      color: const Color(0xFF1572E8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
