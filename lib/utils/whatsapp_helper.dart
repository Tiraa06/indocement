import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> openWhatsApp() async {
    final phoneNumber = '628882017549'; // Nomor tujuan
    final message = Uri.encodeComponent(
        "Halo Bpk. Heriyanto, saya ingin bertanya terkait BPJS Ketenagakerjaan. Berikut detailnya:\n"
        "- Nama: [Isi Nama]\n"
        "- NIP: [Isi NIP]\n"
        "- Divisi: [Isi Divisi]\n"
        "- Pertanyaan: [JMO/Saldo/Kartu]\n\n"
        "Terima kasih!");

    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }
}
