import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indocement_apk/pages/bpjs_page.dart';
import 'package:indocement_apk/pages/hr_menu.dart';
import 'package:indocement_apk/pages/id_card.dart';
import 'package:indocement_apk/pages/master.dart';
import 'package:indocement_apk/pages/skkmedic_page.dart';
import 'package:indocement_apk/pages/schedule_shift.dart';

class LayananMenuPage extends StatefulWidget {
  const LayananMenuPage({super.key});

  @override
  State<LayananMenuPage> createState() => _LayananMenuPageState();
}

class _LayananMenuPageState extends State<LayananMenuPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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

  void _navigateToFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menu $feature belum tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final double paddingValue = screenWidth * 0.04;
        final double baseFontSize = screenWidth * 0.04;

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
              "Layanan Karyawan",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.25,
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
                          'assets/images/banner_layanan.png',
                          width: double.infinity,
                          height: screenHeight * 0.2,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      "Selamat datang di Layanan Karyawan. Pilih salah satu menu di bawah untuk informasi lebih lanjut.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: baseFontSize * 0.9,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: paddingValue * 0.5),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildMenuItem(
                            icon: Icons.monetization_on,
                            title: "Uang Duka",
                            color: Colors.blue,
                            onTap: () => _navigateToFeature("Uang Duka"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.calendar_today,
                            title: "Cuti",
                            color: Colors.green,
                            onTap: () => _navigateToFeature("Cuti"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.schedule,
                            title: "Schedule Shift",
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ScheduleShiftPage()),
                              );
                            },
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.fingerprint,
                            title: "Absensi",
                            color: Colors.purple,
                            onTap: () => _navigateToFeature("Absensi"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet,
                            title: "Dispensasi/Kovensasi",
                            color: Colors.teal,
                            onTap: () =>
                                _navigateToFeature("Dispensasi/Kovensasi"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.folder,
                            title: "File Aktif",
                            color: Colors.blueGrey,
                            onTap: () => _navigateToFeature("File Aktif"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.school,
                            title: "Bea Siswa",
                            color: Colors.red,
                            onTap: () => _navigateToFeature("Bea Siswa"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.star,
                            title: "Penghargaan Masa Kerja",
                            color: Colors.amber,
                            onTap: () =>
                                _navigateToFeature("Penghargaan Masa Kerja"),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          _buildMenuItem(
                            icon: Icons.group,
                            title: "Internal Recruitment",
                            color: Colors.indigo,
                            onTap: () =>
                                _navigateToFeature("Internal Recruitment"),
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
                          icon: Icons.health_and_safety,
                          title: "BPJS",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BPJSPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.badge,
                          title: "ID & Slip Salary",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const IdCardUploadPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.description,
                          title: "SK Kerja & Medical",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SKKMedicPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.headset_mic,
                          title: "HR Care",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HRCareMenuPage()),
                            );
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
