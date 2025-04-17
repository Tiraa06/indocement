import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profile.dart';
import 'hr_menu.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
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

        // ⬇️ Floating FAQ button di pojok kiri bawah
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("FAQ"),
                  content: const Text(
                      "Berisi pertanyaan yang sering ditanyakan oleh karyawan."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            label: const Text("FAQ"),
            backgroundColor: Colors.blue,
          ),
        ),
      ],
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
            width: 180, // ubah nilai ini sesuai kebutuhan, misal 160–200
            fit: BoxFit.contain,
          ),

          // Profil kanan
          GestureDetector(
            onTap: () {
              // Navigasi ke halaman ProfilePage saat avatar ditekan
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
          bannerImages[0], // Menampilkan hanya gambar pertama
          fit: BoxFit.cover,
          width: double.infinity,
          height: 100, // Sesuaikan dengan tinggi sebelumnya
        ),
      ),
    );
  }
}

class Categories extends StatelessWidget {
  const Categories({super.key});

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.start,
          children: List.generate(
            categories.length,
            (index) {
              final category = categories[index];
              return CategoryCard(
                iconPath: category["icon"]!,
                text: category["text"]!,
                // Contoh Navigasi
                  press: () {
                    if (category["text"] == "HR Care") {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HRCareMenuPage(),
                          ));
                    }
                  }
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
    return SizedBox(
      width: 70,
      child: Column(
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
      ),
    );
  }
}

class DailyInfo extends StatelessWidget {
  const DailyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32), // Tambahkan padding bawah
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: "Info Harian",
            press: () {
              // Aksi ketika See more ditekan
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lihat semua info harian')),
              );
            },
          ),
          const SizedBox(height: 12),
          // Gunakan Wrap di sini agar item bisa disesuaikan dengan lebar layar
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
      padding: const EdgeInsets.symmetric(
          horizontal: 20), // ⬅️ Biar sejajar dengan konten lain
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
                color: Colors.blue, // Lebih mencolok
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



