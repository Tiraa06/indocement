import 'package:flutter/material.dart';

class BPJSTambahanPage extends StatelessWidget {
  const BPJSTambahanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Header Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1572E8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info, size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Informasi BPJS Tambahan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Halaman ini digunakan untuk mengunggah dokumen yang diperlukan untuk pengelolaan BPJS Tambahan.',
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
                  const SizedBox(height: 24),
                  // Section 1: Bapak/Ibu Kandung/Mertua
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1572E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bapak/Ibu Kandung/Mertua',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildBox(
                              title: 'Upload KK',
                              icon: Icons.file_upload,
                              color: const Color(0xFF1572E8),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Download Surat Pemotongan Gaji',
                              icon: Icons.download,
                              color: const Color(0xFF1572E8),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Pemotongan Gaji',
                              icon: Icons.file_upload,
                              color: const Color(0xFF1572E8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section 2: Anak > Ke 3
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1572E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anak > Ke 3',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildBox(
                              title: 'Upload KK',
                              icon: Icons.file_upload,
                              color: const Color(0xFF1572E8),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Keterangan Lahir',
                              icon: Icons.file_upload, // Changed to upload icon
                              color: const Color(0xFF1572E8),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Download Surat Pemotongan Gaji',
                              icon: Icons.download,
                              color: const Color(0xFF1572E8),
                            ),
                            const SizedBox(height: 16),
                            _buildBox(
                              title: 'Upload Surat Pemotongan Gaji',
                              icon: Icons.file_upload,
                              color: const Color(0xFF1572E8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48), // Add bottom spacing
                ],
              ),
            ),
          ),
          // Floating FAQ Button
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Handle FAQ button tap
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('FAQ'),
                    content: const Text('Frequently Asked Questions about BPJS Karyawan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Increased padding
                decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(16), // Slightly larger border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.help_outline, size: 28, color: Color.fromARGB(255, 0, 0, 0)), // Larger icon
                    SizedBox(width: 10),
                    Text(
                      'FAQ',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16), // Larger text
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

  Widget _buildBox({required String title, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
