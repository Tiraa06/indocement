import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:indocement_apk/pages/bpjs_page.dart';
import 'package:indocement_apk/pages/id_card.dart';
import 'package:indocement_apk/pages/layanan_menu.dart';
import 'package:indocement_apk/pages/profile.dart';
import 'package:indocement_apk/pages/hr_menu.dart';
import 'package:indocement_apk/pages/skkmedic_page.dart';
import 'package:indocement_apk/pages/inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  _MasterScreenState createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = [
    const MasterContent(),
    const InboxPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _selectedIndex == 0
                  ? Tween<double>(begin: 1.0, end: 1.2).animate(_scaleAnimation)
                  : const AlwaysStoppedAnimation(1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(
                    0, _selectedIndex == 0 ? -10 : 0, 0),
                transformAlignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 0
                      ? BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _selectedIndex == 1
                  ? Tween<double>(begin: 1.0, end: 1.2).animate(_scaleAnimation)
                  : const AlwaysStoppedAnimation(1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(
                    0, _selectedIndex == 1 ? -10 : 0, 0),
                transformAlignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 1
                      ? BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.inbox,
                    color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _selectedIndex == 2
                  ? Tween<double>(begin: 1.0, end: 1.2).animate(_scaleAnimation)
                  : const AlwaysStoppedAnimation(1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(
                    0, _selectedIndex == 2 ? -10 : 0, 0),
                transformAlignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 2
                      ? BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.person,
                    color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}

class MasterContent extends StatefulWidget {
  const MasterContent({super.key});

  @override
  State<MasterContent> createState() => _MasterContentState();
}

class _MasterContentState extends State<MasterContent> {
  String? _urlFoto;
  String? _employeeName;
  String? _jobTitle;
  String? _email;
  String? _telepon;

  @override
  void initState() {
    super.initState();
    _fetchProfilePhoto();
    _loadProfileData();
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getInt('idEmployee');

      if (employeeId == null || employeeId <= 0) {
        print('Invalid or missing employeeId: $employeeId');
        return;
      }

      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['UrlFoto'] != null && data['UrlFoto'].isNotEmpty) {
            if (data['UrlFoto'].startsWith('/')) {
              _urlFoto = 'http://103.31.235.237:5555${data['UrlFoto']}';
            } else {
              _urlFoto = data['UrlFoto'];
            }
          } else {
            _urlFoto = null;
          }
        });
      } else {
        print('Failed to fetch profile photo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile photo: $e');
    }
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt('idEmployee');

    if (employeeId == null || employeeId <= 0) {
      print('Invalid or missing employeeId: $employeeId');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _employeeName = data['EmployeeName'] ?? "Nama Tidak Tersedia";
          _jobTitle = data['JobTitle'] ?? "Departemen Tidak Tersedia";
          _urlFoto = data['UrlFoto'] != null && data['UrlFoto'].isNotEmpty
              ? (data['UrlFoto'].startsWith('/')
                  ? 'http://103.31.235.237:5555${data['UrlFoto']}'
                  : data['UrlFoto'])
              : null;
          _email = data['Email'] ?? "Email Tidak Tersedia";
          _telepon = data['Telepon'] ?? "Telepon Tidak Tersedia";
        });
      } else {
        print('Failed to fetch profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(urlFoto: _urlFoto),
                    const BannerCarousel(),
                    const Categories(),
                    const DailyInfo(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
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
                                      'Halaman Home adalah tampilan awal aplikasi yang menyediakan akses cepat ke berbagai fitur utama seperti layanan karyawan, HR Chat, dan lainnya. Di halaman ini, pengguna juga dapat melihat informasi harian seperti jadwal shift, ulang tahun karyawan, dan pengingat tugas penting.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.category,
                                  question: 'Apa saja menu yang tersedia?',
                                  answer:
                                      'Menu yang tersedia mencakup BPJS, ID Card, SK Kerja & Medical, Layanan Karyawan, HR Chat, dan fitur lainnya yang menunjang kebutuhan karyawan.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.info,
                                  question: 'Apa itu Info Harian?',
                                  answer:
                                      'Info Harian adalah fitur yang menyajikan informasi penting setiap hari, seperti jadwal shift kerja, ulang tahun karyawan, dan daftar pengingat tugas.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.mail,
                                  question: 'Apa fungsi halaman Inbox?',
                                  answer:
                                      'Halaman Inbox menampilkan riwayat aktivitas dari berbagai fitur dalam aplikasi, seperti pengajuan layanan, status permintaan, dan pesan dari HR.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.person,
                                  question: 'Apa fungsi halaman Profile?',
                                  answer:
                                      'Halaman Profile menampilkan informasi akun karyawan seperti nama, jabatan, kontak, dan data lainnya. Pengguna juga dapat mengedit informasi pribadi melalui halaman ini.',
                                ),
                                
                                _buildFAQItem(
                                  icon: Icons.help_outline,
                                  question:
                                      'Di mana saya bisa melihat semua FAQ?',
                                  answer:
                                      'Seluruh daftar FAQ dapat diakses melalui halaman Profile, pada bagian FAQ.',
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
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  _BannerCarouselState createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final List<String> bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  int _currentIndex = 0;
  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentIndex < bannerImages.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: bannerImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    bannerImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 6.0,
              width: _currentIndex == index ? 16.0 : 6.0,
              decoration: BoxDecoration(
                color: _currentIndex == index ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeHeader extends StatelessWidget {
  final String? urlFoto;

  const HomeHeader({super.key, this.urlFoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo2.png',
            width: 180,
            fit: BoxFit.contain,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage: urlFoto != null && urlFoto!.isNotEmpty
                  ? NetworkImage(urlFoto!)
                  : const AssetImage('assets/images/profile.png')
                      as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
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
      {"icon": "assets/icons/id_card.svg", "text": "ID Card"},
      {"icon": "assets/icons/document.svg", "text": "SK Kerja & Medical"},
      {"icon": "assets/icons/service.svg", "text": "Layanan Karyawan"},
      {"icon": "assets/icons/hr_care.svg", "text": "HR Chat"},
      {"icon": "assets/icons/more.svg", "text": "Lainnya"},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    const cardWidth = 60.0;
    const spacing = 20.0;
    const padding = 16.0 * 2;
    final crossAxisCount = (screenWidth - padding) ~/ (cardWidth + spacing);
    final columnCount = crossAxisCount.clamp(2, 5);

return Padding(
  padding: const EdgeInsets.all(16),
  child: Container(
    width: double.infinity,
    // Tambahkan height agar container lebih tinggi
    height: 250, // Ubah sesuai kebutuhan tampilan
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
              _showLoading(context);
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
                if (category["text"] == "BPJS") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BPJSPage(),
                    ),
                  );
                } else if (category["text"] == "HR Chat") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HRCareMenuPage(),
                    ),
                  );
                } else if (category["text"] == "ID Card") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IdCardUploadPage(),
                    ),
                  );
                } else if (category["text"] == "SK Kerja & Medical") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SKKMedicPage(),
                    ),
                  );
                } else if (category["text"] == "Layanan Karyawan") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LayananMenuPage(),
                    ),
                  );
                } else if (category["text"] == "Lainnya") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu Lainnya belum tersedia'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Menu ${category["text"]} belum tersedia'),
                    ),
                  );
                }
              });
            },
          );
        },
      ),
    ),
  ),
);
  }

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
                  "Memuat halaman...",
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
                  title: "Ulang Tahun ðŸŽ‚",
                  subtitle: "Andi P. (Dept. QC)",
                  description: "Kirim ucapan via HR Chat",
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
