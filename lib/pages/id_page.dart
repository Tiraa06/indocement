import 'package:flutter/material.dart';

class IDPage extends StatelessWidget {
  const IDPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Card Management'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'assets/images/banner_id_card.png', // Path ke gambar banner
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Deskripsi
              const Text(
                "Kelola ID Card Anda dengan mudah. Pilih salah satu menu di bawah untuk membuat ID baru, melaporkan ID rusak, atau melaporkan ID hilang.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16), // Jarak antara deskripsi dan menu

              // Menu Buat Baru
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.add_card, color: Colors.blue),
                  title: const Text(
                    "Buat Baru",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // Navigasi ke halaman Buat Baru
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BuatBaruPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Menu Id Card Rusak
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.build, color: Colors.orange),
                  title: const Text(
                    "Id Card Rusak",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // Navigasi ke halaman Id Card Rusak
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IdCardRusakPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Menu Id Card Hilang
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.report_problem, color: Colors.red),
                  title: const Text(
                    "Id Card Hilang",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // Navigasi ke halaman Id Card Hilang
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IdCardHilangPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman placeholder untuk Buat Baru
class BuatBaruPage extends StatelessWidget {
  const BuatBaruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Baru'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: const Center(
        child: Text('Halaman Buat Baru'),
      ),
    );
  }
}

// Halaman placeholder untuk Id Card Rusak
class IdCardRusakPage extends StatelessWidget {
  const IdCardRusakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Id Card Rusak'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: const Center(
        child: Text('Halaman Id Card Rusak'),
      ),
    );
  }
}

// Halaman placeholder untuk Id Card Hilang
class IdCardHilangPage extends StatelessWidget {
  const IdCardHilangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Id Card Hilang'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: const Center(
        child: Text('Halaman Id Card Hilang'),
      ),
    );
  }
}