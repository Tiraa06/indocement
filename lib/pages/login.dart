import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'register.dart';
import 'master.dart';
import 'forgot.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<Map<String, dynamic>> fetchEmployeeDetail(int idEmployee) async {
    final response = await http.get(
      Uri.parse('http://213.35.123.110:5555/api/Employees/$idEmployee'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data employee');
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    final Uri url = Uri.parse("http://213.35.123.110:5555/api/Users");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);

        final user = users.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => null,
        );

        if (user != null) {
          final int idEmployee = user['idEmployee'];
          final employeeData = await fetchEmployeeDetail(idEmployee);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('idEmployee', idEmployee); // Simpan idEmployee
          await prefs.setString('name', employeeData['employeeName']);
          await prefs.setString('jobTitle', employeeData['jobTitle']);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MasterScreen()),
          );
        } else {
          _showMessage("Email atau password salah.");
        }
      } else {
        _showMessage("Gagal mengambil data pengguna.");
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan: $e");
    }

    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                      "Login",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2035),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildField("Email", 900, controller: _emailController),
                  _buildField("Password", 1100,
                      obscure: true, controller: _passwordController),
                  const SizedBox(height: 30),
                  FadeInLeft(
                    duration: Duration(milliseconds: 1200),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot your password?",
                          style: TextStyle(color: Color(0xFF1A2035)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: Duration(milliseconds: 1300),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                "Login",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 1400),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Register(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 14),
                            children: [
                              TextSpan(text: "Belum punya akun? "),
                              TextSpan(
                                text: "Register",
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
    );
  }

  Widget _buildField(String hint, int duration,
      {bool obscure = false, required TextEditingController controller}) {
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
