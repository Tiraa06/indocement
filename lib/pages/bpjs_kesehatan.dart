import 'package:flutter/material.dart';
import 'bpjs_karyawan.dart'; // Import the BPJSKaryawanPage
import 'bpjs_tambahan.dart'; // Import the BPJSTambahanPage

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back icon
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        backgroundColor: const Color(0xFF1572E8), // Match header color with menu box
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Banner with BPJS.png, border radius, and shadow
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12.0), // Padding untuk memberi ruang di dalam container
                decoration: BoxDecoration(
                  color: Colors.white, // Warna latar belakang container
                  borderRadius: BorderRadius.circular(16), // Sudut melengkung
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Warna bayangan
                      blurRadius: 10, // Radius blur bayangan
                      offset: const Offset(0, 4), // Offset bayangan
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Border radius untuk gambar
                  child: Image.asset(
                    'assets/images/BPJS.png', // Path to BPJS.png
                    height: 150, // Tinggi gambar
                    fit: BoxFit.contain, // Menyesuaikan gambar
                  ),
                ),
              ),
              // Description text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Text(
                  'Akses cepat untuk informasi, pembayaran, dan dukungan BPJS. Pilih opsi di bawah untuk melanjutkan.',
                  textAlign: TextAlign.center, // Teks rata tengah
                  style: TextStyle(
                    fontSize: 14, // Ukuran font lebih kecil
                    color: Colors.black87, // Warna teks lebih gelap
                    height: 1.5, // Jarak antar baris
                  ),
                ),
              ),
              // Menu container wrapped in a modern box
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Background color for the box
                  borderRadius: BorderRadius.circular(16), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Shadow color
                      blurRadius: 10, // Blur radius for shadow
                      offset: const Offset(0, 4), // Shadow offset
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BPJSKaryawanPage(),
                                ),
                              );
                            },
                            child: _buildMenuBox(
                              icon: Icons.family_restroom, // Icon for family
                              title: 'BPJS Kesehatan\nKeluarga Karyawan',
                              color: const Color(0xFF1572E8),
                              width: double.infinity, // Responsif
                              height: 140,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Spacing between boxes
                        Flexible(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BPJSTambahanPage(),
                                ),
                              );
                            },
                            child: _buildMenuBox(
                              icon: Icons.group_add, // Icon for additional family
                              title: 'BPJS Kesehatan\nKeluarga Tambahan',
                              color: const Color(0xFF1572E8),
                              width: double.infinity, // Responsif
                              height: 140,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Spacing between rows
                    _buildMenuBox(
                      icon: Icons.help_outline, // Icon for FAQ
                      title: 'FAQ',
                      color: const Color(0xFFE53935),
                      width: double.infinity, // Responsif
                      height: 140,
                      isFullWidth: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16), // Sudut melengkung
                              ),
                              contentPadding: const EdgeInsets.all(16.0),
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: SingleChildScrollView(
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
                                        question: 'Apa itu BPJS?',
                                        answer: 'BPJS adalah Badan Penyelenggara Jaminan Sosial yang menyediakan layanan kesehatan bagi masyarakat Indonesia.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Bagaimana cara mendaftar BPJS?',
                                        answer: 'Anda dapat mendaftar melalui aplikasi atau kantor BPJS terdekat.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Apa saja dokumen yang diperlukan?',
                                        answer: 'Dokumen yang diperlukan meliputi KTP, KK, dan dokumen pendukung lainnya.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Bagaimana cara mengajukan klaim?',
                                        answer: 'Klaim dapat diajukan melalui aplikasi atau langsung ke kantor BPJS.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Apakah BPJS mencakup semua jenis penyakit?',
                                        answer: 'BPJS mencakup sebagian besar penyakit, namun ada beberapa pengecualian tertentu.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Bagaimana cara membayar iuran BPJS?',
                                        answer: 'Iuran BPJS dapat dibayar melalui bank, aplikasi pembayaran, atau kantor BPJS.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Apa yang terjadi jika terlambat membayar iuran?',
                                        answer: 'Jika terlambat membayar, status keanggotaan Anda dapat dinonaktifkan sementara hingga pembayaran dilakukan.',
                                      ),
                                      _buildFAQItem(
                                        question: 'Bagaimana cara memperbarui data BPJS?',
                                        answer: 'Data BPJS dapat diperbarui melalui aplikasi atau dengan mengunjungi kantor BPJS terdekat.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Tutup',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBox({
    required IconData icon,
    required String title,
    required Color color,
    double width = 100,
    double height = 120,
    bool isFullWidth = false,
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(0.2), // Warna border
            width: 1, // Ketebalan border 1px
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: height * 0.3, // Ukuran ikon responsif berdasarkan tinggi kotak
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: height * 0.12, // Ukuran teks responsif berdasarkan tinggi kotak
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
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
              const Icon(
                Icons.question_answer,
                color: Color(0xFF1572E8),
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