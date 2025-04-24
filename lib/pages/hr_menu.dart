import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chat.dart';
import 'form.dart';

class HRCareMenuPage extends StatefulWidget {
  const HRCareMenuPage({super.key});

  @override
  State<HRCareMenuPage> createState() => _HRCareMenuPageState();
}

class _HRCareMenuPageState extends State<HRCareMenuPage> {
  late String _dateTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update setiap detik
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _updateTime();
      return true;
    });
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB
    setState(() {
      _dateTime =
          "${now.day}/${now.month}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HR Care",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/banner_hr.jpg',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Selamat datang di HR Care 👋\nSilakan pilih layanan yang Anda butuhkan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/consultation.svg',
                height: 54,
                width: 54,
                color: Colors.white,
              ),
              label: Text(
                "Konsultasi Dengan HR",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF1572E8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/complaint.svg',
                height: 34,
                width: 34,
                color: Colors.white,
              ),
              label: Text(
                "Keluhan Karyawan",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFDE2328),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KeluhanPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Jam dan Tanggal
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Color(0xFF1572E8), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _dateTime,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
