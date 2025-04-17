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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Banner with BPJS.png, border radius, and shadow
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Add border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      blurRadius: 10, // Blur radius for shadow
                      offset: const Offset(0, 4), // Shadow offset
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge, // Ensure the image respects the border radius
                child: Image.asset(
                  'assets/images/BPJS.png', // Path to BPJS.png
                  height: 150, // Increased height
                  fit: BoxFit.contain,
                ),
              ),
              // Description text
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'This page provides quick access to BPJS Info, Payments, and Support. Select an option below to proceed.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              // Menu container
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
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
                          title: 'BPJS Kesehatan\nKeluarga Karyawan', // Updated title
                          color: const Color(0xFF1572E8),
                          width: 120,
                          height: 120,
                        ),
                      ),
                      GestureDetector(
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
                          title: 'BPJS Kesehatan\nKeluarga Tambahan', // Updated title
                          color: const Color(0xFF1572E8),
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildMenuBox(
                    icon: Icons.help_outline, // Updated icon for FAQ
                    title: 'FAQ',
                    color: const Color(0xFF1572E8),
                    width: 260,
                    height: 120,
                  ),
                ],
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
  }) {
    return Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center, // Center-align the text
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
