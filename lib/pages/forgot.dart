import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Forgot Password"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeText(
              title: "Forgot Password",
              text:
                  "Enter your email address and we will send you a reset instructions.",
            ),
            const SizedBox(height: 16),
            ForgotPassForm(),
          ],
        ),
      ),
    );
  }
}

class WelcomeText extends StatelessWidget {
  final String title, text;

  const WelcomeText({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ForgotPassForm extends StatefulWidget {
  const ForgotPassForm({super.key});

  @override
  State<ForgotPassForm> createState() => _ForgotPassFormState();
}

class _ForgotPassFormState extends State<ForgotPassForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _canResendOtp = false;
  String? _email;
  Timer? _otpTimer;
  final String _baseUrl = 'http://192.168.100.140:5555';

  @override
  void initState() {
    super.initState();
    _startOtpTimer();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _canResendOtp = false;
    });
    _otpTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _canResendOtp = true;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/User/forgot-password/request'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sent'] == true) {
          if (mounted) {
            setState(() {
              _isOtpSent = true;
              _email = _emailController.text;
            });
            _showPopup(context, 'Success', data['message']);
            _startOtpTimer();
          }
        } else {
          if (mounted) {
            _showPopup(
                context, 'Error', 'Failed to send OTP. Please try again.');
          }
        }
      } else {
        if (mounted) {
          _showPopup(context, 'Error', 'User tidak ditemukan.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(context, 'Error', 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/User/forgot-password/verify'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': _email,
          'Otp': _otpController.text,
          'NewPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          _showPopup(context, 'Success', data['message'], onClose: () {
            Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          _showPopup(context, 'Error', 'Gagal mereset password. Coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(context, 'Error', 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPopup(BuildContext context, String title, String message,
      {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1572E8),
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onClose != null) {
                onClose();
              }
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF1572E8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your email address";
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return "Please enter a valid email address";
              }
              return null;
            },
            readOnly: _isOtpSent,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Email Address",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF1572E8), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          if (_isOtpSent) ...[
            // OTP Field
            TextFormField(
              controller: _otpController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter the OTP";
                }
                if (value.length != 6) {
                  return "OTP must be 6 digits";
                }
                return null;
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter OTP",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF1572E8), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // New Password Field
            TextFormField(
              controller: _newPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a new password";
                }
                if (value.length < 4) {
                  return "Password must be at least 4 characters";
                }
                return null;
              },
              obscureText: true,
              decoration: InputDecoration(
                hintText: "New Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF1572E8), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1572E8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isLoading
                ? null
                : (_isOtpSent ? _verifyOtpAndResetPassword : _sendOtp),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isOtpSent ? "Verify and Reset" : "Send OTP"),
          ),

          if (_isOtpSent) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isOtpSent = false;
                            _otpController.clear();
                            _newPasswordController.clear();
                            _canResendOtp = false;
                          });
                          _otpTimer?.cancel();
                        },
                  child: const Text(
                    "Change Email",
                    style: TextStyle(color: Color(0xFF1572E8)),
                  ),
                ),
                if (_canResendOtp)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _otpController.clear();
                            _sendOtp();
                          },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(color: Color(0xFF1572E8)),
                    ),
                  ),
              ],
            ),
            if (!_canResendOtp)
              const Text(
                "OTP expires in 5 minutes",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}
