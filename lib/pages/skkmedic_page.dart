import 'package:flutter/material.dart';
import 'package:indocement_apk/pages/medic_pasutri.dart'; // Import halaman MedicPasutriPage

class SKKMedicPage extends StatelessWidget {
  const SKKMedicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
         iconTheme: const IconThemeData(color: Colors.white), // Tombol back warna putih
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Gambar
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
                    'assets/images/banner_medicskk.png', // Path ke gambar banner
                    fit: BoxFit.cover,
                    height: 200, // Tinggi gambar
                  ),
                ),
              ),

              // Penjelasan Halaman
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Halaman ini digunakan untuk mengelola Surat Keterangan Kerja dan memperbarui data medical suami/istri Anda.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Menu Surat Keterangan Kerja
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.work, color: Colors.blue),
                  title: const Text(
                    "Surat Keterangan Kerja",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // Navigasi ke halaman Surat Keterangan Kerja
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const SuratKeteranganKerjaPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Menu Update Medical Suami/Istri
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading:
                      const Icon(Icons.medical_services, color: Colors.green),
                  title: const Text(
                    "Update Medical Suami/Istri",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MedicPasutriPage()), // Navigasi ke TambahDataPasutriPage
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

// Halaman placeholder untuk Surat Keterangan Kerja
class SuratKeteranganKerjaPage extends StatelessWidget {
  const SuratKeteranganKerjaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surat Keterangan Kerja'),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: const Center(
        child: Text('Halaman Surat Keterangan Kerja'),
      ),
    );
  }
}
