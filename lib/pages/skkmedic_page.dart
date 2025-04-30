import 'package:flutter/material.dart';
import 'package:indocement_apk/pages/medic_pasutri.dart'; // Import halaman MedicPasutriPage

class SKKMedicPage extends StatelessWidget {
  const SKKMedicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SK Kerja & Medical'),
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
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description, // Ikon untuk banner
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "SK Kerja & Medical",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Kelola Surat Keterangan Kerja dan Update Medical Suami/Istri dengan mudah.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
