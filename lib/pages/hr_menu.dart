import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _HRCareMenuPageState extends State<HRCareMenuPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late String _dateTime;

  @override
  void initState() {
    super.initState();

    // Inisialisasi AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Durasi animasi
    );

    // Inisialisasi Slide Animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Mulai dari luar layar (kanan)
      end: Offset.zero, // Berakhir di posisi normal
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Kurva animasi
    ));

    _updateTime();
    // Update setiap detik
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _updateTime();
      return true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // Hentikan controller saat widget dihancurkan
    super.dispose();
  }

  void _toggleMenu() {
    if (_animationController.isCompleted) {
      _animationController.reverse(); // Tutup menu
    } else {
      _animationController.forward(); // Buka menu
    }
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB
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
          _showLoading(context); // Tampilkan loading
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context); // Tutup loading
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BPJSPage()), // Navigasi ke halaman BPJSPage
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      child: const Text("Tutup", style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Ikon back warna putih
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MasterScreen()), // Navigasi ke halaman Master
            );
          },
        ),
        title: Text(
          "BPJS", // Ganti teks menjadi BPJS
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white, // Warna teks putih
          ),
        ),
        backgroundColor: const Color(0xFF1572E8), // Warna latar belakang header
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white), // Ikon menu garis tiga warna putih
            onPressed: () {
              _toggleMenu(); // Buka atau tutup menu
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/banner_hr.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // Deskripsi
                Text(
                  "Selamat datang di BPJS 👋\nSilakan pilih layanan yang Anda butuhkan.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),

                // Menu Konsultasi Dengan HR
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Sudut melengkung lebih besar
                  ),
                  elevation: 4, // Tambahkan sedikit bayangan
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Padding lebih besar
                    leading: CircleAvatar(
                      radius: 35, // Perbesar ukuran lingkaran ikon
                      backgroundColor: const Color(0xFF1572E8).withOpacity(0.2),
                      child: SvgPicture.asset(
                        'assets/icons/consultation.svg',
                        height: 40, // Perbesar ikon
                        width: 40,
                        color: const Color(0xFF1572E8),
                      ),
                    ),
                    title: Text(
                      "Konsultasi Dengan HR",
                      style: GoogleFonts.roboto(
                        fontSize: 18, // Ukuran teks tetap
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1572E8),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 28), // Perbesar ikon panah
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20), // Jarak antar menu

                // Menu Keluhan Karyawan
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Sudut melengkung lebih besar
                  ),
                  elevation: 4, // Tambahkan sedikit bayangan
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Padding lebih besar
                    leading: CircleAvatar(
                      radius: 35, // Perbesar ukuran lingkaran ikon
                      backgroundColor: const Color(0xFFDE2328).withOpacity(0.2),
                      child: SvgPicture.asset(
                        'assets/icons/complaint.svg',
                        height: 40, // Perbesar ikon
                        width: 40,
                        color: const Color(0xFFDE2328),
                      ),
                    ),
                    title: Text(
                      "Keluhan Karyawan",
                      style: GoogleFonts.roboto(
                        fontSize: 18, // Ukuran teks tetap
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDE2328),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 28), // Perbesar ikon panah
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KeluhanPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Jam dan Tanggal
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _dateTime,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
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

          // SlideTransition Menu
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white, // Background slider menjadi putih
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1), // Warna border lebih halus
                    width: 1, // Ketebalan border 1px
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
                          color: Colors.black, // Warna teks menu menjadi hitam
                        ),
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    _buildMenuItem(
                      context,
                      title: "BPJS",
                      icon: Icons.health_and_safety,
                      color: Colors.blue, // Warna menu menjadi biru
                      onTap: () {
                        _checkAccess(context); // Panggil fungsi akses
                      },
                    ),
                    const SizedBox(height: 16), // Jarak antar menu
                    _buildMenuItem(
                      context,
                      title: "ID & Slip Salary",
                      icon: Icons.badge,
                      color: Colors.blue, // Warna menu menjadi biru
                      onTap: () {
                        // Aksi untuk ID & Slip Salary
                      },
                    ),
                    const SizedBox(height: 16), // Jarak antar menu
                    _buildMenuItem(
                      context,
                      title: "SK Kerja & Medical",
                      icon: Icons.description,
                      color: Colors.blue, // Warna menu menjadi biru
                      onTap: () {
                        // Aksi untuk SK Kerja & Medical
                      },
                    ),
                    const SizedBox(height: 16), // Jarak antar menu
                    _buildMenuItem(
                      context,
                      title: "Layanan Karyawan",
                      icon: Icons.support_agent,
                      color: Colors.blue, // Warna menu menjadi biru
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
      elevation: 0, // Hilangkan shadow dengan mengatur elevation menjadi 0
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2), // Warna latar belakang ikon
          child: Icon(icon, color: color), // Ikon dengan warna biru
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color, // Warna teks menu menjadi biru
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
