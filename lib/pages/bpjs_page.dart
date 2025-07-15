import 'package:flutter/material.dart';
import 'package:indocement_apk/pages/bpjs_ketenagakerjaan.dart';
import 'package:indocement_apk/pages/bpjs_kesehatan.dart';
import 'package:indocement_apk/pages/master.dart';
import 'package:indocement_apk/pages/hr_menu.dart';
import 'package:indocement_apk/pages/pcir_page.dart';

class BPJSPage extends StatefulWidget {
  const BPJSPage({super.key});

  @override
  State<BPJSPage> createState() => _BPJSPageState();
}

class _BPJSPageState extends State<BPJSPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();

    _menuItems = [
      {
        'icon': Icons.health_and_safety,
        'title': 'BPJS Kesehatan',
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuPage()),
          );
        },
      },
      {
        'icon': Icons.work,
        'title': 'BPJS Ketenagakerjaan',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BPJSKetenagakerjaanPage()),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'title': 'PCIR',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PCIRPage()),
          );
        },
      },
    ];

    // Inisialisasi animasi
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
    _animationController
        .dispose(); // Hentikan controller saat widget dihancurkan
    super.dispose();
  }

  void _toggleMenu() {
    if (_animationController.isCompleted) {
      _animationController.reverse(); // Tutup menu
    } else {
      _animationController.forward(); // Buka menu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ikon back
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const MasterScreen()), // Navigasi ke halaman Master
            );
          },
        ),
        backgroundColor: const Color(0xFF1572E8), // Warna latar belakang header
        title: const Text(
          "BPJS",
          style: TextStyle(
            color: Colors.white, // Warna putih untuk judul
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Warna putih untuk ikon
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 16.0), // Jarak bawah banner
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // Sudut melengkung
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // Warna bayangan
                        blurRadius: 8, // Radius blur bayangan
                        offset: const Offset(0, 4), // Posisi bayangan
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        16), // Sudut melengkung untuk gambar
                    child: Image.asset(
                      'assets/images/bpjs_page.png', // Path ke gambar banner
                      width: double.infinity, // Lebar penuh
                      height: 250, // Tinggi banner diubah menjadi 250
                      fit: BoxFit.cover, // Gambar menyesuaikan ukuran container
                    ),
                  ),
                ),

                // Deskripsi
                const Text(
                  "Selamat datang di halaman BPJS. Pilih salah satu menu di bawah untuk informasi lebih lanjut.",
                  textAlign: TextAlign.center, // Rata tengah
                  style: TextStyle(
                    fontSize: 16, // Perbesar ukuran teks
                    fontWeight: FontWeight.w500, // Tambahkan ketebalan teks
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10), // Jarak antara deskripsi dan menu

                // Menu
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Dua kolom
                      crossAxisSpacing: 16, // Jarak horizontal antar kotak
                      mainAxisSpacing: 16, // Jarak vertikal antar kotak
                      childAspectRatio: 1, // Rasio aspek kotak (lebar = tinggi)
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = _menuItems[index];
                      return _buildMenuItem(
                        context,
                        icon: menuItem['icon'] as IconData,
                        title: menuItem['title'] as String,
                        color: menuItem['color'] as Color,
                        onTap: menuItem['onTap'] as VoidCallback,
                      );
                    },
                  ),
                ),
              ],
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
                    final ScrollController scrollController =
                        ScrollController();

                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16), // Sudut melengkung
                      ),
                      contentPadding: const EdgeInsets.all(16.0),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.95, // Lebih panjang (95% dari lebar layar)
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Scrollbar(
                          controller: scrollController, // Kontrol scrollbar
                          thumbVisibility: false, // Hilang jika tidak di-scroll
                          thickness: 3, // Ketebalan scrollbar
                          radius: const Radius.circular(
                              10), // Sudut melengkung scrollbar
                          child: SingleChildScrollView(
                            controller: scrollController, // Kontrol scroll
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FAQ BPJS Kesehatan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1572E8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFAQItem(
                                  icon: Icons.health_and_safety,
                                  question: 'Apa tujuan dari menu BPJS Kesehatan?',
                                  answer:
                                      'Menu ini disediakan untuk mengelola data kepesertaan BPJS Kesehatan karyawan dan keluarga, termasuk pengunggahan dokumen dan penambahan anggota keluarga yang ditanggung.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.upload_file,
                                  question: 'Dokumen apa yang perlu saya unggah?',
                                  answer:
                                      'Anda perlu mengunggah dokumen berikut:\n\n• Kartu Keluarga (KK)\n• Surat Nikah (jika ingin menambahkan pasangan)',
                                ),
                                _buildFAQItem(
                                  icon: Icons.group_add,
                                  question: 'Siapa saja anggota keluarga yang bisa saya tambahkan?',
                                  answer:
                                      '• Pasangan (Suami/Istri) – Wajib melampirkan surat nikah.\n'
                                      '• Anak – Maksimal 3 anak ditanggung langsung.\n'
                                      '• Tambahan Keluarga (BPJS Keluarga Tambahan):\n'
                                      '   - Ayah\n   - Ibu\n   - Ayah Mertua\n   - Ibu Mertua\n   - Anak ke-4 sampai Anak ke-7',
                                ),
                                _buildFAQItem(
                                  icon: Icons.add_box,
                                  question: 'Bagaimana cara menambahkan data anggota keluarga?',
                                  answer:
                                      'Klik tombol “Tambah Data” di bagian yang sesuai.\n'
                                      'Lengkapi form biodata anggota keluarga.\n'
                                      'Unggah dokumen pendukung jika diminta (KK, akta kelahiran, surat nikah, dll).\n'
                                      'Simpan dan tunggu proses verifikasi oleh HR.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.info_outline,
                                  question: 'Apakah semua anggota keluarga tambahan akan otomatis ditanggung perusahaan?',
                                  answer:
                                      'Tidak. Penambahan anggota keluarga di luar ketentuan (anak ke-4 dst, orang tua/mertua) mungkin dikenakan iuran tambahan, sesuai kebijakan perusahaan.',
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'FAQ - BPJS Ketenagakerjaan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1572E8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFAQItem(
                                  icon: Icons.work,
                                  question: 'Apa fungsi dari menu BPJS Ketenagakerjaan?',
                                  answer:
                                      'Menu ini digunakan untuk informasi dan pertanyaan seputar BPJS Ketenagakerjaan, termasuk proses klaim, status kepesertaan, dan bantuan administrasi.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.contact_phone,
                                  question: 'Siapa yang bisa saya hubungi jika saya memiliki pertanyaan tentang BPJS Ketenagakerjaan?',
                                  answer:
                                      'Anda dapat menghubungi atasan/PIC'
                                ),
                                _buildFAQItem(
                                  icon: Icons.account_balance_wallet,
                                  question: 'Apakah saya bisa melihat data iuran atau saldo BPJS Ketenagakerjaan di sini?',
                                  answer:
                                      'Tidak. Untuk melihat data saldo BPJS TK, silakan login ke aplikasi resmi BPJSTKU atau kunjungi situs web BPJS Ketenagakerjaan.',
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'FAQ - PCIR (Pusat Control Informasi Relasi)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1572E8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFAQItem(
                                  icon: Icons.info,
                                  question: 'Apa itu menu PCIR?',
                                  answer:
                                      'PCIR adalah pusat kendali informasi pribadi dan keluarga karyawan. Di sini Anda bisa mengelola dan memperbarui data pribadi Anda secara mandiri.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.featured_play_list,
                                  question: 'Fitur apa saja yang tersedia di menu PCIR?',
                                  answer:
                                      'Menu PCIR memiliki 3 fitur utama:\n'
                                      '• Update BPJS – Untuk memperbarui data kepesertaan BPJS Anda dan keluarga.\n'
                                      '• Update Pendidikan – Untuk memperbarui riwayat dan tingkat pendidikan terakhir Anda.\n'
                                      '• Lihat Seluruh Data Keluarga – Untuk melihat semua data anggota keluarga yang terdaftar dalam sistem.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.verified,
                                  question: 'Apakah perubahan data melalui PCIR langsung berlaku?',
                                  answer:
                                      'Setelah Anda mengajukan perubahan, data akan diverifikasi oleh HR terlebih dahulu sebelum di-update secara resmi di sistem.',
                                ),
                                _buildFAQItem(
                                  icon: Icons.download,
                                  question: 'Apakah saya bisa mencetak data keluarga dari PCIR?',
                                  answer:
                                      'Ya, terdapat fitur "Download Data" yang memungkinkan Anda mencetak atau menyimpan data keluarga dalam format PDF untuk keperluan pribadi atau administrasi.',
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
                              backgroundColor:
                                  Colors.red, // Warna latar belakang merah
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8), // Tombol kotak
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
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
              icon: const Icon(Icons.help_outline,
                  color: Colors.white), // Ikon warna putih
              label: const Text(
                "FAQ",
                style: TextStyle(color: Colors.white), // Teks warna putih
              ),
              backgroundColor: Colors.blue, // Warna tombol tetap biru
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
                    color: Colors.black
                        .withOpacity(0.1), // Warna border lebih halus
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
                    const SizedBox(height: 16), // Jarak antar menu
                    _buildMenuItem(
                      context,
                      title: "HR Care",
                      icon: Icons.headset_mic,
                      color: Colors.blue, // Warna menu menjadi biru
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
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Tambahkan padding di dalam kotak
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40), // Ikon di tengah
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                softWrap: true, // Pastikan teks melanjutkan ke baris berikutnya
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
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

