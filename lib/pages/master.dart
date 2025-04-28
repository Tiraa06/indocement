import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // Tambahkan ini
import 'package:indocement_apk/pages/bpjs_page.dart';
import 'dart:convert'; // Tambahkan ini
import 'package:indocement_apk/pages/profile.dart';
import 'package:indocement_apk/pages/hr_menu.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Cegah tombol back keluar
      child: Stack(
        children: [
          const Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(),
                    Banner(),
                    Categories(),
                    DailyInfo(),
                    SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),

          // Floating FAQ button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final ScrollController scrollController = ScrollController();

                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Sudut melengkung
                      ),
                      contentPadding: const EdgeInsets.all(16.0),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95, // Lebih panjang (95% dari lebar layar)
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Scrollbar(
                          controller: scrollController, // Kontrol scrollbar
                          thumbVisibility: false, // Hilang jika tidak di-scroll
                          thickness: 3, // Ketebalan scrollbar
                          radius: const Radius.circular(10), // Sudut melengkung scrollbar
                          child: SingleChildScrollView(
                            controller: scrollController, // Kontrol scroll
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
                                  answer: 'Halaman Home memberikan ringkasan informasi harian, seperti shift kerja, ulang tahun, dan pengingat penting.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.category,
                                  question: 'Apa saja menu yang tersedia?',
                                  answer: 'Menu yang tersedia meliputi BPJS, ID & Slip Gaji, SK Kerja & Medical, Layanan Karyawan, HR Care, dan lainnya.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.info,
                                  question: 'Apa itu Info Harian?',
                                  answer: 'Info Harian menampilkan informasi penting seperti shift kerja, ulang tahun karyawan, dan pengingat tugas.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.help_outline,
                                  question: 'Bagaimana cara mengakses menu BPJS?',
                                  answer: 'Klik menu BPJS. Jika akses belum diberikan, Anda dapat meminta izin melalui tombol yang tersedia.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.notifications,
                                  question: 'Apa itu pengingat di Info Harian?',
                                  answer: 'Pengingat adalah notifikasi untuk tugas penting, seperti pengajuan lembur atau dokumen yang harus diselesaikan.',
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
                              backgroundColor: Colors.red, // Warna latar belakang merah
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // Tombol kotak
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              'Tutup',
                              style: TextStyle(
                                color: Colors.white, // Teks putih
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
              icon: const Icon(Icons.help_outline, color: Colors.white), // Ikon warna putih
              label: const Text(
                "FAQ",
                style: TextStyle(color: Colors.white), // Teks warna putih
              ),
              backgroundColor: Colors.blue, // Warna tombol tetap biru
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF1572E8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.arrow_right,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo kiri
          Image.asset(
            'assets/images/logo2.png',
            width: 180,
            fit: BoxFit.contain,
          ),

          // Profil kanan
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('assets/images/picture.jpg'),
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class Banner extends StatelessWidget {
  const Banner({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> bannerImages = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          bannerImages[0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 100,
        ),
      ),
    );
  }
}

class Categories extends StatelessWidget {
  const Categories({super.key});

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

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> categories = [
      {"icon": "assets/icons/bpjs.svg", "text": "BPJS"},
      {"icon": "assets/icons/id_card.svg", "text": "ID & Slip Salary"},
      {"icon": "assets/icons/document.svg", "text": "SK Kerja & Medical"},
      {"icon": "assets/icons/service.svg", "text": "Layanan Karyawan"},
      {"icon": "assets/icons/hr_care.svg", "text": "HR Care"},
      {"icon": "assets/icons/more.svg", "text": "Lainnya"},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    const cardWidth = 70.0;
    const spacing = 20.0;
    const padding = 16.0 * 2;
    final crossAxisCount = (screenWidth - padding) ~/ (cardWidth + spacing);
    final columnCount = crossAxisCount.clamp(2, 5);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: 12.0,
          childAspectRatio: cardWidth / (cardWidth + 30),
          children: List.generate(
            categories.length,
            (index) {
              final category = categories[index];
              return CategoryCard(
                iconPath: category["icon"]!,
                text: category["text"]!,
                press: () {
                  if (category["text"] == "HR Care") {
                    _showLoading(context); // Tampilkan loading
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pop(context); // Tutup loading
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HRCareMenuPage()),
                      );
                    });
                  } else if (category["text"] == "BPJS") {
                    _checkAccess(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Menu ${category["text"]} belum tersedia')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback press;

  const CategoryCard({
    super.key,
    required this.text,
    required this.iconPath,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: press,
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              iconPath,
              width: 30,
              height: 30,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class DailyInfo extends StatelessWidget {
  const DailyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: "Info Harian",
            press: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lihat semua info harian')),
              );
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                InfoCard(
                  title: "Shift Hari Ini",
                  subtitle: "Pagi (07.00 - 15.00)",
                  description: "Jangan lupa datang tepat waktu ya!",
                ),
                SizedBox(width: 12),
                InfoCard(
                  title: "Ulang Tahun 🎂",
                  subtitle: "Andi P. (Dept. QC)",
                  description: "Kirim ucapan via HR Care",
                ),
                SizedBox(width: 12),
                InfoCard(
                  title: "Reminder",
                  subtitle: "Submit lembur",
                  description: "Sebelum jam 17.00 hari ini",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.blueGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.press,
  });

  final String title;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          TextButton.icon(
            onPressed: press,
            icon: const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.blue),
            label: const Text(
              "Lihat Semua",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Tidak bisa ditutup dengan klik di luar
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Sudut melengkung
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animasi Loading
              const CircularProgressIndicator(
                color: Colors.blue, // Warna indikator loading
              ),
              const SizedBox(height: 16),

              // Teks Loading
              const Text(
                "Memuat halaman...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Teks Deskripsi
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
