import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indocement_apk/pages/register.dart';
import 'package:indocement_apk/pages/forgot.dart';
import 'package:indocement_apk/pages/master.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io'; // Added for exit functionality

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

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
                  onPressed: () => Navigator.pop(context),
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

  Future<Map<String, dynamic>?> _fetchIdEmployee(String email) async {
    try {
      _showLoading(context);
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees?email=$email'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      Navigator.pop(context); // Close loading dialog

      print('Fetch idEmployee Status: ${response.statusCode}');
      print('Fetch idEmployee Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
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
      Navigator.pop(context); // Close loading dialog
      return null;
    }
  }

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showErrorModal('Email harus diisi');
      return;
    }
    if (password.isEmpty) {
      _showErrorModal('Password harus diisi');
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

      final response = await http.post(
        Uri.parse('http://103.31.235.237:5555/api/User/login'),
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      Navigator.pop(context); // Close loading dialog

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
          final String role = user['Role'] ?? '';
          if (role.toLowerCase() != 'karyawan') {
            _showErrorModal(
                'Akses ditolak. Hanya pengguna dengan role Karyawan yang dapat login.');
            setState(() => _isLoading = false);
            return;
          }

          final employeeData = await _fetchIdEmployee(email) ?? {};

          if (employeeData.isEmpty && user['IdEmployee'] == null) {
            _showErrorModal('Gagal mengambil data karyawan. Silakan coba lagi.');
            setState(() => _isLoading = false);
            return;
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Remove specific keys to avoid stale data
          await prefs.remove('id');
          await prefs.remove('idEmployee');
          await prefs.remove('email');
          await prefs.remove('employeeName');
          await prefs.remove('jobTitle');
          await prefs.remove('telepon');
          await prefs.remove('urlFoto');
          await prefs.remove('livingArea');
          await prefs.remove('employeeNo');

          final int idEmployee =
              employeeData['idEmployee'] ?? user['IdEmployee'] ?? 0;
          if (idEmployee <= 0) {
            _showErrorModal('ID karyawan tidak valid. Silakan hubungi admin.');
            setState(() => _isLoading = false);
            return;
          }

          await prefs.setInt('id', user['Id'] as int);
          await prefs.setInt('idEmployee', idEmployee);
          await prefs.setString('email', user['Email'] ?? email);
          await prefs.setString('employeeName',
              user['employeeName'] ?? employeeData['employeeName'] ?? '');
          await prefs.setString(
              'jobTitle', user['Role'] ?? employeeData['jobTitle'] ?? '');
          await prefs.setString(
              'telepon', user['telepon'] ?? employeeData['telepon'] ?? '');
          await prefs.setString('livingArea', employeeData['livingArea'] ?? '');
          await prefs.setString('employeeNo',
              user['employeeNo'] ?? employeeData['employeeNo'] ?? '');

          if (employeeData['urlFoto'] != null) {
            await prefs.setString('urlFoto', employeeData['urlFoto']);
          }

          final savedEmployeeName = prefs.getString('employeeName');
          print('Saved employeeName: $savedEmployeeName');
          print(
              'Saved to SharedPreferences: ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(", ")}');

          if (savedEmployeeName == null || savedEmployeeName.isEmpty) {
            _showErrorModal(
                'Nama karyawan tidak tersedia. Silakan hubungi admin.');
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MasterScreen()),
            (route) => false,
          );
        } else {
          _showErrorModal('Akun tidak valid');
        }
      } else {
        String errorMessage = 'Akun tidak valid';
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        _showErrorModal(errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      _showErrorModal('Terjadi kesalahan. Silakan coba lagi.');
      Navigator.pop(context, false); // Close loading dialog if open
    }

    setState(() => _isLoading = false);
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
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14),
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
        size.width * 0.75, size.height * 0.15, size.width, size.height * 0.1);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}