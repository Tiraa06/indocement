import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> openWhatsApp() async {
    final phoneNumber = '628882017549'; // Ganti dengan nomor tujuan
    final message = Uri.encodeComponent(
        "Halo tim HR Care, saya ingin mengajukan pertanyaan terkait kebijakan cuti. Berikut detailnya:\n"
        "- Nama: [Isi Nama]\n"
        "- NIP: [Isi NIP]\n"
        "- Divisi: [Isi Divisi]\n\n"
        "Terima kasih!");

    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }
}
