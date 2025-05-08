import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indocement_apk/pages/bpjs_page.dart';
import 'package:indocement_apk/pages/master.dart';
import 'chat.dart';
import 'form.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HRCareMenuPage extends StatefulWidget {
  const HRCareMenuPage({super.key});

  @override
  State<HRCareMenuPage> createState() => _HRCareMenuPageState();
}

class _HRCareMenuPageState extends State<HRCareMenuPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late String _dateTime;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateTime();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _updateTime();
      return true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    setState(() {
      _dateTime =
          "${now.day}/${now.month}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB";
    });
  }

  Future<void> _checkAccess(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? idEmployee = prefs.getInt('idEmployee');

      if (idEmployee == null) {
        throw Exception('ID pengguna tidak ditemukan. Silakan login ulang.');
      }

      final employeeResponse = await http.get(
        Uri.parse('http://213.35.123.110:5555/api/Employees/$idEmployee'),
      );

      if (employeeResponse.statusCode == 200) {
        final employeeData = json.decode(employeeResponse.body);
        final int idEsl = employeeData['IdEsl'];

        if (idEsl >= 1 && idEsl <= 4) {
          _showLoading(context);
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BPJSPage()),
            );
          });
        } else if (idEsl == 5 || idEsl == 6) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      "Akses Belum Diberikan",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Anda memerlukan izin dari PIC untuk mengakses halaman ini.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Tutup",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IdEsl tidak valid')),
          );
        }
      } else {
        throw Exception('Gagal memuat data Employee dari API');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final double paddingValue = screenWidth * 0.04; // 4% of screen width
        final double baseFontSize = screenWidth * 0.04; // 4% for font scaling

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MasterScreen()),
                );
              },
            ),
            title: Text(
              "HR Care",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.25, // ~20 on 500px screen
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1572E8),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _toggleMenu,
              ),
            ],
          ),
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(paddingValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: paddingValue),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/banner_hr.jpg',
                          width: double.infinity,
                          height: screenHeight * 0.2, // Responsive height
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      "Selamat datang di HR Care. Pilih salah satu menu di bawah untuk informasi lebih lanjut.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: baseFontSize * 0.9, // ~16 on 500px screen
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: paddingValue * 0.5),
                    Expanded(
                      child: ListView(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading:
                                  const Icon(Icons.message, color: Colors.blue),
                              title: const Text(
                                "Konsultasi Dengan HR",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ChatPage()),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading:
                                  const Icon(Icons.report, color: Colors.red),
                              title: const Text(
                                "Keluhan Karyawan",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const KeluhanPage()),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: paddingValue,
                              horizontal: paddingValue * 0.8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5FB),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Color(0xFF1572E8), size: 32),
                                SizedBox(width: paddingValue * 0.8),
                                Expanded(
                                  child: Text(
                                    _dateTime,
                                    style: GoogleFonts.roboto(
                                      fontSize: baseFontSize *
                                          1.0, // ~18 on 500px screen
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final ScrollController scrollController =
                            ScrollController();
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.all(16.0),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Scrollbar(
                              controller: scrollController,
                              thumbVisibility: false,
                              thickness: 3,
                              radius: const Radius.circular(10),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Frequently Asked Questions (FAQ)',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1572E8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFAQItem(
                                      icon: Icons.home,
                                      question: 'Apa fungsi halaman Home?',
                                      answer:
                                          'Halaman Home memberikan ringkasan informasi harian, seperti shift kerja, ulang tahun, dan pengingat penting.',
                                    ),
                                    _buildFAQItem(
                                      icon: Icons.category,
                                      question: 'Apa saja menu yang tersedia?',
                                      answer:
                                          'Menu yang tersedia meliputi BPJS, ID & Slip Gaji, SK Kerja & Medical, Layanan Karyawan, HR Care, dan lainnya.',
                                    ),
                                    _buildFAQItem(
                                      icon: Icons.info,
                                      question: 'Apa itu Info Harian?',
                                      answer:
                                          'Info Harian menampilkan informasi penting seperti shift kerja, ulang tahun karyawan, dan pengingat tugas.',
                                    ),
                                    _buildFAQItem(
                                      icon: Icons.help_outline,
                                      question:
                                          'Bagaimana cara mengakses menu BPJS?',
                                      answer:
                                          'Klik menu BPJS. Jika akses belum diberikan, Anda dapat meminta izin melalui tombol yang tersedia.',
                                    ),
                                    _buildFAQItem(
                                      icon: Icons.notifications,
                                      question:
                                          'Apa itu pengingat di Info Harian?',
                                      answer:
                                          'Pengingat adalah notifikasi untuk tugas penting, seperti pengajuan lembur atau dokumen yang harus diselesaikan.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Tutup',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  label: const Text(
                    "FAQ",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
              SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Menu",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        _buildMenuItem(
                          context,
                          title: "BPJS",
                          icon: Icons.health_and_safety,
                          color: Colors.blue,
                          onTap: () {
                            _checkAccess(context);
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          context,
                          title: "ID & Slip Salary",
                          icon: Icons.badge,
                          color: Colors.blue,
                          onTap: () {
                            // Aksi untuk ID & Slip Salary
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          context,
                          title: "SK Kerja & Medical",
                          icon: Icons.description,
                          color: Colors.blue,
                          onTap: () {
                            // Aksi untuk SK Kerja & Medical
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          context,
                          title: "Layanan Karyawan",
                          icon: Icons.support_agent,
                          color: Colors.blue,
                          onTap: () {
                            // Aksi untuk Layanan Karyawan
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({
    required IconData icon,
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1572E8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
