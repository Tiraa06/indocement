import 'dart:convert';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login.dart';

User? _user;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class User {
  final int id;
  final String email;
  final String jobTitle;
  final int idEmployee;

  User({
    required this.id,
    required this.email,
    required this.jobTitle,
    required this.idEmployee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      idEmployee: json['idEmployee'] ?? 0,
    );
  }
}

class _RegisterState extends State<Register> {
  final _namaController = TextEditingController();
  final _nomoridController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telpController = TextEditingController();
  String? _selectedSectionId;
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fetchSections();
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
                const Text(
                  "Memuat...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Harap tunggu sebentar",
                  style: TextStyle(
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

  void _showErrorModal(String message) {
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
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1572E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkNetwork() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
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

  Future<void> _fetchSections() async {
    try {
      final hasNetwork = await _checkNetwork();
      if (!hasNetwork) {
        if (mounted) {
          _showErrorModal('Tidak ada koneksi internet. Silakan cek jaringan Anda.');
        }
        setState(() {
          _sections = [];
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Sections'),
        headers: {'accept': 'text/plain'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _sections = data
              .cast<Map<String, dynamic>>()
              .where((section) => section['NamaSection'] != 'Unknown')
              .toList();
        });
      } else {
        if (mounted) {
          _showErrorModal('Gagal memuat daftar section');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorModal('Terjadi kesalahan saat memuat section: $e');
      }
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    try {
      print('Sending payload: ${json.encode(userData)}');
      final response = await http.post(
        Uri.parse('http://103.31.235.237:5555/api/User/register'),
        body: json.encode(userData),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map<String, dynamic> &&
              responseBody.containsKey('id')) {
            _user = User.fromJson(responseBody);
          }
          if (mounted) {
            _showSuccessModal();
          }
        } catch (e) {
          if (mounted) {
            _showSuccessModal();
          }
        }
      } else {
        String errorMessage = 'Gagal membuat akun';
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Registrasi gagal: ${e.toString()}');
    }
  }

  Future<void> _handleRegister() async {
    final nama = _namaController.text.trim();
    final nomerid = _nomoridController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final telp = _telpController.text.trim();
    final sectionId = _selectedSectionId;

    if (nama.isEmpty) {
      _showErrorModal('Nama karyawan harus diisi');
      return;
    }
    if (nomerid.isEmpty) {
      _showErrorModal('Nomor Karyawan harus diisi');
      return;
    }
    if (sectionId == null) {
      _showErrorModal('Section harus diisi');
      return;
    }
    if (email.isEmpty) {
      _showErrorModal('Email harus diisi');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorModal('Format email tidak valid');
      return;
    }
    if (password.isEmpty) {
      _showErrorModal('Password harus diisi');
      return;
    }
    if (password.length < 6) {
      _showErrorModal('Password minimal 6 karakter');
      return;
    }
    if (telp.isEmpty) {
      _showErrorModal('Nomor telepon harus diisi');
      return;
    }
    if (!RegExp(r'^\d{10,13}$').hasMatch(telp)) {
      _showErrorModal('Nomor telepon harus 10-13 digit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hasNetwork = await _checkNetwork();
      if (!hasNetwork) {
        _showErrorModal('Tidak ada koneksi internet. Silakan cek jaringan Anda.');
        setState(() => _isLoading = false);
        return;
      }

      _showLoading(context);

      final userData = {
        "employeeName": nama,
        "employeeNo": nomerid,
        "email": email,
        "password": password,
        "telepon": telp,
        "idSection": int.parse(sectionId),
        "gender": "L", // <-- gender selalu "L" saat dikirim ke API
      };

      await registerUser(userData);
    } catch (e) {
      if (mounted) {
        _showErrorModal(e.toString().replaceFirst('Exception: ', ''));
      }
      Navigator.of(context).pop(); // Close loading dialog if open
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Berhasil!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akun berhasil dibuat.',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed
        exit(0);
        return false;
      },
      child: Scaffold(
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
                        'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A2035),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildField('Nama', _namaController, 900),
                    _buildField('Nomor Karyawan', _nomoridController, 900),
                    _buildSectionField(1000),
                    _buildField('Email', _emailController, 1100),
                    _buildField('Password', _passwordController, 1200,
                        obscure: true),
                    _buildField('Nomor Telepon', _telpController, 1300,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 30),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1300),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  'REGISTER',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1400),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                  color: Colors.black, fontSize: 14),
                              children: const [
                                TextSpan(text: 'Sudah punya akun? '),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
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
      ),
    );
  }

  Widget _buildField(
      String hint, TextEditingController controller, int duration,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
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
            obscureText: obscure ? _obscurePassword : false,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
              suffixIcon: obscure
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionField(int duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInLeft(
        duration: Duration(milliseconds: duration),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedSectionId,
            hint: Text(
              'Pilih Section',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            items: _sections.map((section) {
              return DropdownMenuItem<String>(
                value: section['Id'].toString(),
                child: Text(
                  section['NamaSection'],
                  style: GoogleFonts.poppins(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSectionId = value;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomoridController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telpController.dispose();
    super.dispose();
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;

    Path path = Path();
    Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF0E5AB7),
          Color(0xFF1572E8),
          Color(0xFF5A9DF3)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.15));

    path.moveTo(0, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.05,
        size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.15, size.width, size.height * 0.15);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}