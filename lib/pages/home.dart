import 'package:flutter/material.dart';
import 'package:indocement_apk/utils/helper.dart';
import 'package:indocement_apk/widgets/app_button.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FD), // Warna background sesuai permintaan
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    top: 100.0,
                    left: 0.0,
                    right: 0.0,
                    child: Container(
                      height: 150.0,
                      width: double.infinity,
                      decoration: BoxDecoration(),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical:
                              40.0), // Tambahkan padding agar lebih ke tengah
                      child: Image.asset(
                        "assets/images/logo.png",
                        scale: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                decoration: BoxDecoration(
                  color: Color(
                      0xFF1572E8), // Ubah warna background menjadi #1A2035
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    topLeft: Radius.circular(30.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.0),
                    Text(
                      "Selamat Datang di Aplikasi Karyawan Indocement",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.white, // Ubah warna teks menjadi putih
                          ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      "Kelola informasi dan aktivitas kerja Anda menjadi lebih mudah. Silakan Login menggunakan akun Anda untuk mengakses layanan karyawan.",
                      style: TextStyle(
                        color: Colors.white, // Ubah warna teks menjadi putih
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                    // Tombol Login
                    AppButton(
                      text: "Log In",
                      type: ButtonType.PLAIN,
                      onPressed: () {
                        nextScreen(context, "/login");
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
