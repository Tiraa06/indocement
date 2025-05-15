import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  bool _isLoading = false;

  Future<void> registerUser(Map<String, dynamic> userData) async {
    try {
      print('Sending payload: ${json.encode(userData)}');
      final response = await http.post(
        Uri.parse(
            'http://192.168.100.140:5555/api/User/register'), // Perbaikan endpoint
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
          _showSuccessModal();
        } catch (e) {
          _showSuccessModal();
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

    if (nama.isEmpty) {
      _showMessage('Nama karyawan tidak boleh kosong.');
      return;
    }
    if (nomerid.isEmpty) {
      _showMessage('Nomor Karyawan tidak boleh kosong.');
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
      final userData = {
        "employeeName": nama,
        "employeeNo": nomerid,
        "email": email,
        "password": password,
        "telepon": telp,
      };

      await registerUser(userData);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil!'),
        content: const Text('Akun berhasil dibuat.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              );
            },
            child: const Text('OK'),
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
                  _buildField('Nama', _namaController, 900),
                  _buildField('Nomor Karyawan', _nomoridController, 900),
                  _buildField('Email', _emailController, 900),
                  _buildField('Password', _passwordController, 1100,
                      obscure: true),
                  _buildField('Nomor Telepon', _telpController, 900,
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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
