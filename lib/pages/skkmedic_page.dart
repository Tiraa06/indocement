import 'package:flutter/material.dart';
import 'package:indocement_apk/pages/medic_pasutri.dart';
import 'package:indocement_apk/pages/skk_form.dart';

class SKKMedicPage extends StatefulWidget {
  const SKKMedicPage({super.key});

  @override
  State<SKKMedicPage> createState() => _SKKMedicPageState();
}

class _SKKMedicPageState extends State<SKKMedicPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();

    _menuItems = [
      {
        'icon': Icons.work,
        'title': 'Surat Keterangan Kerja',
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SkkFormPage()),
          );
        },
      },
      {
        'icon': Icons.medical_services,
        'title': 'Update Medical Suami/Istri',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MedicPasutriPage()),
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

  @override
  Widget build(BuildContext context) {
    // Hitung tinggi banner berdasarkan lebar layar dan rasio aspek gambar (1024/1536 ≈ 0.6667)
    // Kembali ke faktor 1.0 untuk menghindari banner terlalu besar
    double bannerHeight = MediaQuery.of(context).size.width * (1024 / 1536);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFF1572E8),
        title: const Text(
          "SKK & Medical",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
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
                        'assets/images/banner_medicskk.png',
                        width: double.infinity, // Lebar penuh
                        height: 250, // Tinggi banner diubah menjadi 250
                        fit: BoxFit.cover, // Gambar menyesuaikan ukuran container
                      ),
                    ),
                  ),

                  // Deskripsi
                  const Text(
                    "Halaman ini digunakan untuk mengelola Surat Keterangan Kerja dan memperbarui data medical suami/istri Anda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Menu
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ],
              ),
            ),
          ),
          // Tombol FAQ dipindahkan ke bawah layar dengan padding
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
            child: Align(
              alignment: Alignment.bottomRight,
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
                                    icon: Icons.work,
                                    question: 'Apa itu Surat Keterangan Kerja?',
                                    answer:
                                        'Surat Keterangan Kerja adalah dokumen yang menyatakan status kerja Anda di perusahaan.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.medical_services,
                                    question:
                                        'Bagaimana cara update medical suami/istri?',
                                    answer:
                                        'Silakan unggah dokumen yang diperlukan melalui menu Update Medical Suami/Istri.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.info,
                                    question: 'Bagaimana Sistem Pengajuan Surat Keterangan Kerja?',
                                    answer:
                                        'Anda perlu mengisi form kecil untuk menyebutkan keperluan surat tersebut. Setelah diajukan, pengajuan akan masuk ke riwayat pengajuan SKK, di mana Anda bisa melihat statusnya:\n\n'
                                        '-Diajukan: Masih diproses oleh HR\n'
                                        '-Approved: Telah disetujui, dan tombol download akan muncul di bagian keperluan\n'
                                        '-Return: Pengajuan dikembalikan, Anda perlu mengajukan ulang',
                                  ),
                                  // Tambahan FAQ Medical
                                  _buildFAQItem(
                                    icon: Icons.medical_information,
                                    question: 'Apa itu Halaman Medical?',
                                    answer:
                                        'Halaman Medical adalah halaman yang disediakan untuk karyawan mengisi dan mengunggah dokumen medis, seperti Surat Keterangan Medic dan Surat Pernyataan Medic, untuk keperluan administrasi internal.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.description,
                                    question: 'Dokumen apa saja yang perlu saya isi?',
                                    answer:
                                        'Anda perlu mengisi:\n\n'
                                        'Surat Keterangan Medic – Formulir ini berisi informasi medis dari instansi atau fasilitas kesehatan.\n\n'
                                        'Surat Pernyataan Medic – Formulir ini berisi pernyataan pribadi Anda terkait kondisi medis dan persetujuan terhadap kebijakan perusahaan.',
                                  ),
                                  _buildFAQItem(
                                     icon: Icons.edit_document,
                                    question: 'Apakah saya harus mencetak dan menandatangani dokumen terlebih dahulu?',
                                    answer:
                                        'Ya. Anda perlu mencetak, mengisi, dan menandatangani kedua dokumen tersebut sebelum mengunggahnya melalui tombol Upload yang tersedia di halaman.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.upload_file,
                                    question: 'Bagaimana cara mengunggah dokumen?',
                                    answer:
                                        'Setelah Anda mengisi dan menandatangani dokumen:\n\n'
                                        '• Pindai atau foto dokumen dengan jelas.\n'
                                        '• Klik tombol Upload pada halaman Medical.\n'
                                        '• Pilih file yang akan diunggah (format PDF/JPG/PNG disarankan).\n'
                                        '• Konfirmasi pengunggahan dan pastikan status file berhasil dikirim.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.group,
                                    question: 'Siapa yang menerima dokumen yang saya unggah?',
                                    answer:
                                        'Dokumen yang diunggah akan dikirim secara otomatis ke atasan langsung atau pihak HR yang berwenang untuk verifikasi dan tindak lanjut.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.notifications_active,
                                    question: 'Apakah saya akan mendapat notifikasi setelah mengunggah dokumen?',
                                    answer:
                                        'Ya, Anda akan menerima notifikasi bahwa dokumen telah berhasil dikirim. Pastikan untuk menyimpan bukti pengunggahan jika diperlukan.',
                                  ),
                                  _buildFAQItem(
                                    icon: Icons.help,
                                    question: 'Apa yang harus saya lakukan jika mengalami kendala saat mengunggah?',
                                    answer:
                                        'Silakan hubungi tim IT support atau HRD melalui email internal atau kontak yang tersedia jika:\n\n'
                                        '• Tombol upload tidak berfungsi.\n'
                                        '• Dokumen gagal terkirim.\n'
                                        '• Ada kesalahan dalam file yang sudah diunggah.',
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
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
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
