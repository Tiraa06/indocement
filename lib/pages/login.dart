import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indocement_apk/pages/register.dart';
import 'package:indocement_apk/pages/forgot.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<Map<String, dynamic>?> _fetchIdEmployee(String email) async {
    try {
      final response = await http.get(
        Uri.parse('http://213.35.123.110:5555/api/Employees?email=$email'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Fetch idEmployee Status: ${response.statusCode}');
      print('Fetch idEmployee Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          // Cari karyawan yang email-nya benar-benar cocok
          final matchingEmployee = data.firstWhere(
            (employee) =>
                employee['Email']?.toLowerCase() == email.toLowerCase(),
            orElse: () => null,
          );

          if (matchingEmployee != null && matchingEmployee['Id'] != null) {
            print('Matching Employee Data: $matchingEmployee');
            return {
              'idEmployee': matchingEmployee['Id'] as int,
              'employeeName': matchingEmployee['EmployeeName'] ?? '',
              'jobTitle': matchingEmployee['JobTitle'] ?? '',
              'telepon': matchingEmployee['Telepon'] ?? '',
              'email': matchingEmployee['Email'] ?? email,
              'urlFoto': matchingEmployee['UrlFoto'],
              'livingArea': matchingEmployee['LivingArea'] ?? '',
            };
          }
          print('No matching employee found for email: $email');
          return null;
        }
        print('No valid employee data found in response: $data');
        return null;
      }
      print('Failed to fetch idEmployee: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching idEmployee: $e');
      return null;
    }
  }

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email tidak boleh kosong.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('Password tidak boleh kosong.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://213.35.123.110:5555/api/User/login'),
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Sending payload: ${json.encode({
            'email': email,
            'password': password
          })}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final user = json.decode(response.body);
        print('Parsed User: $user');

        if (user is Map<String, dynamic> && user['Id'] != null) {
          final employeeData = await _fetchIdEmployee(email) ?? {};

          if (employeeData.isEmpty && user['IdEmployee'] == null) {
            _showMessage('Gagal mengambil data karyawan. Silakan coba lagi.');
            setState(() => _isLoading = false);
            return;
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('id');
          await prefs.remove('idEmployee');
          await prefs.remove('email');
          await prefs.remove('employeeName');
          await prefs.remove('jobTitle');
          await prefs.remove('telepon');
          await prefs.remove('livingArea');
          await prefs.remove('urlFoto');
          print(
              'After manual clear - SharedPreferences: ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(", ")}');

          // Gunakan IdEmployee dari user jika employeeData kosong
          final int idEmployee =
              employeeData['idEmployee'] ?? user['IdEmployee'] ?? 0;
          if (idEmployee <= 0) {
            _showMessage('ID karyawan tidak valid. Silakan hubungi admin.');
            setState(() => _isLoading = false);
            return;
          }

          await prefs.setInt('id', user['Id'] as int);
          await prefs.setInt('idEmployee', idEmployee);
          await prefs.setString('email', user['email'] ?? email);
          await prefs.setString('employeeName',
              user['employeeName'] ?? employeeData['employeeName'] ?? '');
          await prefs.setString(
              'jobTitle', user['role'] ?? employeeData['jobTitle'] ?? '');
          await prefs.setString(
              'telepon', user['telepon'] ?? employeeData['telepon'] ?? '');
          await prefs.setString('livingArea', employeeData['livingArea'] ?? '');

          if (employeeData['urlFoto'] != null) {
            await prefs.setString('urlFoto', employeeData['urlFoto']);
          } else {
            await prefs.remove('urlFoto');
          }

          final savedEmployeeName = prefs.getString('employeeName');
          print('Saved employeeName: $savedEmployeeName');
          print(
              'Saved to SharedPreferences: ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(", ")}');

          if (savedEmployeeName == null || savedEmployeeName.isEmpty) {
            _showMessage(
                'Nama karyawan tidak tersedia. Silakan hubungi admin.');
          }

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/master',
            (route) => false,
          );
        } else {
          _showMessage('Data pengguna tidak valid: ID tidak ditemukan.');
        }
      } else {
        String errorMessage = 'Gagal login';
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        _showMessage(errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      _showMessage('Terjadi kesalahan: ${e.toString()}');
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
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2035),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildField('Email', 900, controller: _emailController),
                  _buildField('Password', 1100,
                      obscure: true, controller: _passwordController),
                  const SizedBox(height: 30),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1200),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot your password?',
                          style: TextStyle(color: Color(0xFF1A2035)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                'Login',
                                style: TextStyle(color: Colors.white),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Register(),
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 14),
                            children: [
                              TextSpan(text: 'Belum punya akun? '),
                              TextSpan(
                                text: 'Register',
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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
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
    _emailController.dispose();
    _passwordController.dispose();
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
