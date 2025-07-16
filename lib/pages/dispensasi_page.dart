import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class DispensasiPage extends StatefulWidget {
  const DispensasiPage({super.key});

  @override
  _DispensasiPageState createState() => _DispensasiPageState();
}

class _DispensasiPageState extends State<DispensasiPage> {
  final _jenisDispensasiController = TextEditingController();
  final _keteranganController = TextEditingController();
  PlatformFile? _suratKeteranganMeninggal;
  PlatformFile? _ktp;
  PlatformFile? _sim;
  PlatformFile? _dokumenLain;
  bool _isLoading = false;

  @override
  void dispose() {
    _jenisDispensasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<bool> _checkNetwork() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No network connectivity');
        return false;
      }

      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      print('Network check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Network check failed: $e');
      return false;
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  "Mengirim...",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Harap tunggu sebentar",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
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

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          switch (field) {
            case 'SuratKeteranganMeninggal':
              _suratKeteranganMeninggal = result.files.first;
              break;
            case 'Ktp':
              _ktp = result.files.first;
              break;
            case 'Sim':
              _sim = result.files.first;
              break;
            case 'DokumenLain':
              _dokumenLain = result.files.first;
              break;
          }
        });
      }
    } catch (e) {
      _showMessage('Gagal memilih file: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_jenisDispensasiController.text.trim().isEmpty) {
      _showMessage('Jenis dispensasi tidak boleh kosong.');
      return;
    }
    if (_keteranganController.text.trim().isEmpty) {
      _showMessage('Keterangan tidak boleh kosong.');
      return;
    }
    if (_suratKeteranganMeninggal == null) {
      _showMessage('Surat Keterangan Meninggal wajib diunggah.');
      return;
    }
    if (_ktp == null) {
      _showMessage('KTP wajib diunggah.');
      return;
    }
    if (_sim == null) {
      _showMessage('SIM wajib diunggah.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hasNetwork = await _checkNetwork();
      if (!hasNetwork) {
        _showMessage('Tidak ada koneksi internet. Silakan cek jaringan Anda.');
        setState(() => _isLoading = false);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final idEmployee = prefs.getInt('idEmployee');
      if (idEmployee == null || idEmployee <= 0) {
        _showMessage('ID karyawan tidak valid. Silakan login ulang.');
        setState(() => _isLoading = false);
        return;
      }

      _showLoading(context);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://103.31.235.237:5555/api/Dispensasi'),
      );

      request.headers['accept'] = 'text/plain';
      request.fields['IdEmployee'] = idEmployee.toString();
      request.fields['JenisDispensasi'] =
          _jenisDispensasiController.text.trim();
      request.fields['Keterangan'] = _keteranganController.text.trim();

      // Add files
      if (_suratKeteranganMeninggal != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'SuratKeteranganMeninggal',
          _suratKeteranganMeninggal!.path!,
          filename: path.basename(_suratKeteranganMeninggal!.path!),
        ));
      }
      if (_ktp != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'Ktp',
          _ktp!.path!,
          filename: path.basename(_ktp!.path!),
        ));
      }
      if (_sim != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'Sim',
          _sim!.path!,
          filename: path.basename(_sim!.path!),
        ));
      }
      if (_dokumenLain != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'DokumenLain',
          _dokumenLain!.path!,
          filename: path.basename(_dokumenLain!.path!),
        ));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessModal();
      } else {
        String errorMessage = 'Gagal mengajukan dispensasi';
        try {
          final decoded = json.decode(responseBody);
          errorMessage = decoded['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = responseBody.isNotEmpty ? responseBody : errorMessage;
        }
        _showMessage(errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      Navigator.pop(context); // Close loading dialog if open
      _showMessage('Terjadi kesalahan: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Berhasil!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Pengajuan dispensasi berhasil dikirim.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(
                  context); // Return to previous screen (e.g., MasterScreen)
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1572E8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
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
                  _buildFileField('Surat Keterangan Meninggal',
                      'SuratKeteranganMeninggal', 1100),
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
                                color: Colors.white)
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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: WavePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String hint, TextEditingController controller, int duration) {
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
    PlatformFile? file;
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
                            ? path.basename(file.path!)
                            : 'Pilih file (JPG, PNG, PDF)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: file != null ? Colors.black : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.upload_file, color: const Color(0xFF1572E8)),
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

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;

    Path path = Path();
    Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF0E5AB7), Color(0xFF1572E8), Color(0xFF5A9DF3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.15));

    path.moveTo(0, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.05,
        size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.15, size.width, size.height * 0.1);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
