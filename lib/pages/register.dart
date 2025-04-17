import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _namaController = TextEditingController();
  final _nomeridController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telpController = TextEditingController();

  bool _isLoading = false;

  Future<int> registerEmployee(Map<String, dynamic> employeeData) async {
    final response = await http.post(
      Uri.parse('http://213.35.123.110:5555/api/Employees'),
      body: json.encode(employeeData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      return responseBody['id']; // id dari karyawan baru
    } else {
      throw Exception('Gagal membuat data karyawan: ${response.body}');
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('http://213.35.123.110:5555/api/Users'),
      body: json.encode(userData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal membuat akun user: ${response.body}');
    }
  }

  Future<void> _handleRegister() async {
    final nama = _namaController.text.trim();
    final nomerid = _nomeridController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final telp = _telpController.text.trim();

    // Validasi input seperti sebelumnya...
    if (nama.isEmpty) {
      _showMessage('Nama karyawan tidak boleh kosong.');
      return;
    }
    if (email.isEmpty) {
      _showMessage('Email tidak boleh kosong.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage('Format email tidak valid.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('Password tidak boleh kosong.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }
    if (telp.isEmpty) {
      _showMessage('Nomor telepon tidak boleh kosong.');
      return;
    }
    if (!RegExp(r'^\d{10,13}$').hasMatch(telp)) {
      _showMessage('Nomor telepon harus 10-13 digit.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buat Employee
      final employeeData = {
        "employeeName": nama,
        "employeeNo": nomerid,
        "email": email,
        "telepon": telp,
        "gender": "",
        "noBpjs": "",
        "jobTitle": "",
        "education": "",
        "workLocation": "",
        "birthDate": "2000-01-01",
        "startDate": "2025-01-01"
      };
      final idEmployee = await registerEmployee(employeeData);
      // 2. Buat User
      final userData = {
        "idEmployee": idEmployee,
        "email": email,
        "password": password,
        "role": "karyawan"
      };
      await registerUser(userData);

      _showSuccessModal();
    } catch (e) {
      print('Error: $e');
      _showMessage('Registrasi gagal: ${e.toString()}');
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Berhasil!'),
        content: Text('Akun berhasil dibuat.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  FadeInDown(
                    duration: Duration(milliseconds: 800),
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
                    duration: Duration(milliseconds: 800),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2035),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildField('Nama Karyawan', _namaController, 900),
                  _buildField('Nomer Karyawan', _nomeridController, 900),
                  _buildField('Email', _emailController, 900),
                  _buildField('Password', _passwordController, 1100,
                      obscure: true),
                  _buildField('Nomor Telepon', _telpController, 900,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: Duration(milliseconds: 1300),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Color(0xFF1572E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'REGISTER',
                                style: TextStyle(color: Colors.white),
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
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
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
        colors: [Color(0xFF0E5AB7), Color(0xFF1572E8), Color(0xFF5A9DF3)],
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
