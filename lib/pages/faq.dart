import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, dynamic>> faqItems = [
    {
      'icon': Icons.home,
      'question': 'Apa fungsi halaman Home?',
      'answer':
          'Halaman Home adalah tampilan awal aplikasi yang menyediakan akses cepat ke berbagai fitur utama seperti layanan karyawan, HR Chat, dan lainnya. Di halaman ini, pengguna juga dapat melihat informasi harian seperti jadwal shift, ulang tahun karyawan, dan pengingat tugas penting.'
    },
    {
      'icon': Icons.category,
      'question': 'Apa saja menu yang tersedia?',
      'answer':
          'Menu yang tersedia mencakup BPJS, ID Card, SK Kerja & Medical, Layanan Karyawan, HR Chat, dan fitur lainnya yang menunjang kebutuhan karyawan.'
    },
    {
      'icon': Icons.info,
      'question': 'Apa itu Info Harian?',
      'answer':
          'Info Harian adalah fitur yang menyajikan informasi penting setiap hari, seperti jadwal shift kerja, ulang tahun karyawan, dan daftar pengingat tugas.'
    },
    {
      'icon': Icons.mail,
      'question': 'Apa fungsi halaman Inbox?',
      'answer':
          'Halaman Inbox menampilkan riwayat aktivitas dari berbagai fitur dalam aplikasi, seperti pengajuan layanan, status permintaan, dan pesan dari HR.'
    },
    {
      'icon': Icons.person,
      'question': 'Apa fungsi halaman Profile?',
      'answer':
          'Halaman Profile menampilkan informasi akun karyawan seperti nama, jabatan, kontak, dan data lainnya. Pengguna juga dapat mengedit informasi pribadi melalui halaman ini.'
    },
    {
      'icon': Icons.help_outline,
      'question': 'Di mana saya bisa melihat semua FAQ?',
      'answer':
          'Seluruh daftar FAQ dapat diakses melalui halaman Profile, pada bagian FAQ.'
    },
    {
      'icon': Icons.badge,
      'question': 'Apa fungsi menu ID Card?',
      'answer':
          'Menu ID Card digunakan oleh karyawan untuk mengajukan pembuatan kartu identitas. Tersedia tiga jenis pengajuan: Baru, Rusak, dan Hilang. Setiap jenis pengajuan memiliki ketentuan unggah dokumen yang berbeda. Pastikan Anda membaca ketentuannya terlebih dahulu dan mengunggah dokumen sesuai dengan status pengajuan.'
    },
    {
      'icon': Icons.schedule_send,
      'question': 'Apa yang terjadi setelah saya mengajukan ID Card?',
      'answer':
          'Setelah pengajuan ID Card dilakukan, permintaan Anda akan diproses oleh tim HR. Silakan menunggu hingga proses selesai dan ID Card Anda siap.'
    },
    {
      'icon': Icons.support_agent,
      'question': 'Apa saja fitur yang tersedia di HR Chat?',
      'answer':
          'Terdapat dua fitur utama di HR Chat: Konsultasi dan Permintaan Karyawan. Masing-masing memiliki fungsi dan alur yang berbeda.'
    },
    {
      'icon': Icons.chat_bubble_outline,
      'question': 'Apa itu fitur Konsultasi?',
      'answer':
          'Fitur Konsultasi memungkinkan Anda melakukan percakapan langsung (real-time) dengan HR melalui chat. Jika HR sudah membalas pesan Anda dan Anda belum membacanya, maka balasan tersebut akan muncul di Inbox Konsultasi sebagai pesan baru.'
    },
    {
      'icon': Icons.assignment_outlined,
      'question': 'Apa itu fitur Permintaan Karyawan?',
      'answer':
          'Fitur ini menyediakan form untuk mengajukan permintaan kepada HR. Silakan isi form sesuai ketentuan yang berlaku. Anda juga dapat mengunggah gambar sebagai pendukung, namun hal ini bersifat opsional.'
    },
    {
      'icon': Icons.monetization_on,
      'question': 'Apa itu menu Uang Duka?',
      'answer':
          'Menu Uang Duka disediakan untuk mengajukan bantuan atau klaim terkait musibah duka. Fitur ini akan tersedia pada pembaruan selanjutnya.'
    },
    {
      'icon': Icons.calendar_today,
      'question': 'Apa itu menu Cuti?',
      'answer':
          'Menu Cuti akan digunakan untuk mengajukan dan memantau permohonan cuti karyawan secara online. Fitur ini sedang dalam tahap pengembangan.'
    },
    {
      'icon': Icons.schedule,
      'question': 'Apa itu menu Schedule Shift?',
      'answer':
          'Menu Schedule Shift berfungsi untuk melihat jadwal kerja atau shift Anda setiap harinya. Fitur ini sudah aktif dan dapat digunakan.'
    },
    {
      'icon': Icons.fingerprint,
      'question': 'Apa itu menu Absensi?',
      'answer':
          'Menu Absensi ditujukan untuk melihat riwayat kehadiran dan melakukan proses absensi secara digital. Fitur ini akan tersedia di versi mendatang.'
    },
    {
      'icon': Icons.account_balance_wallet,
      'question': 'Apa itu menu Dispensasi/Kompensasi?',
      'answer':
          'Menu ini digunakan untuk mengajukan dispensasi atau kompensasi waktu kerja. Fitur ini masih dalam tahap pengembangan.'
    },
    {
      'icon': Icons.folder,
      'question': 'Apa itu menu File Aktif?',
      'answer':
          'Menu File Aktif akan menampilkan dokumen penting terkait karyawan yang sedang aktif. Fitur ini akan segera tersedia.'
    },
    {
      'icon': Icons.school,
      'question': 'Apa itu menu Bea Siswa?',
      'answer':
          'Menu Bea Siswa disiapkan untuk pengajuan beasiswa karyawan atau keluarga karyawan. Fitur ini belum tersedia dan masih dikembangkan.'
    },
    {
      'icon': Icons.star,
      'question': 'Apa itu menu Penghargaan Masa Kerja?',
      'answer':
          'Menu ini akan digunakan untuk melihat dan mengajukan penghargaan berdasarkan masa kerja karyawan. Akan tersedia dalam pembaruan berikutnya.'
    },
    {
      'icon': Icons.group,
      'question': 'Apa itu menu Internal Recruitment?',
      'answer':
          'Menu Internal Recruitment memungkinkan karyawan melamar posisi yang tersedia di lingkungan perusahaan. Fitur ini masih dalam proses pengembangan.'
    },
    {
      'icon': Icons.work,
      'question': 'Apa itu Surat Keterangan Kerja?',
      'answer':
          'Surat Keterangan Kerja adalah dokumen yang menyatakan status kerja Anda di perusahaan.'
    },
    {
      'icon': Icons.medical_services,
      'question': 'Bagaimana cara update medical suami/istri?',
      'answer':
          'Silakan unggah dokumen yang diperlukan melalui menu Update Medical Suami/Istri.'
    },
    {
      'icon': Icons.info,
      'question': 'Bagaimana Sistem Pengajuan Surat Keterangan Kerja?',
      'answer':
          'Anda perlu mengisi form kecil untuk menyebutkan keperluan surat tersebut. Setelah diajukan, pengajuan akan masuk ke riwayat pengajuan SKK, di mana Anda bisa melihat statusnya:\n\n- Diajukan: Masih diproses oleh HR\n- Approved: Telah disetujui, dan tombol download akan muncul di bagian keperluan\n- Return: Pengajuan dikembalikan, Anda perlu mengajukan ulang'
    },
    {
      'icon': Icons.swap_horiz,
      'question': 'Bagaimana cara mengajukan Tukar Schedule?',
      'answer':
          'Pada halaman Tukar Schedule, disediakan form yang harus Anda isi. Anda perlu memilih karyawan lain yang ingin diajak bertukar shift, lalu tentukan tanggal penukaran shift dan cantumkan keterangan alasan penukaran dengan jelas.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          final item = faqItems[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Icon(item['icon'], color: Colors.blue),
                title: Text(
                  item['question'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      item['answer'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
