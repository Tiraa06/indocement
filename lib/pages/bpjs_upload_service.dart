import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

Future<void> uploadBpjsDocument({
  required int idEmployee,
  required String anggotaBpjs,
  required String fieldName, // contoh: urlKk atau urlSuratNikah
  required File file,
}) async {
  final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');

  var request = http.MultipartRequest('POST', uri);
  request.fields['idEmployee'] = idEmployee.toString();
  request.fields['anggotaBpjs'] = anggotaBpjs;
  request.fields[fieldName] = file.path;

  request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

  print("Fields: ${request.fields}");
  print("Files: ${request.files.map((f) => f.filename).toList()}");

  var response = await request.send();

  if (response.statusCode == 200) {
    print("Upload berhasil!");
  } else {
    print("Gagal upload: ${response.statusCode}");
  }
}

Future<void> uploadBpjsDocumentAsPdf({
  required int idEmployee,
  required String anggotaBpjs,
  required String fieldName, // contoh: urlKk atau urlSuratNikah
  required File file,
}) async {
  try {
    // 1. Kompres gambar
    final compressedImage = await _compressImage(file);

    // Konversi XFile menjadi File
    final compressedFile = File(compressedImage.path);

    // 2. Konversi gambar menjadi PDF
    final pdfFile = await _convertImageToPdf(compressedFile);

    // 3. Kirim PDF ke API
    final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['idEmployee'] = idEmployee.toString();
    request.fields['anggotaBpjs'] = anggotaBpjs;
    request.fields['tglPengajuan'] = DateTime.now().toIso8601String();
    request.files.add(await http.MultipartFile.fromPath(fieldName, pdfFile.path));

    print("Fields: ${request.fields}");
    print("Files: ${request.files.map((f) => f.filename).toList()}");

    var response = await request.send();

    if (response.statusCode == 200) {
      print("✅ Upload berhasil!");
    } else {
      print("❌ Gagal upload: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Terjadi kesalahan: $e");
  }
}

Future<void> uploadBpjsDocumentCompressed({
  required int idEmployee,
  required String anggotaBpjs,
  required String fieldName, // contoh: urlKk atau urlSuratNikah
  required File file,
}) async {
  try {
    // Kompres gambar (jika perlu)
    final compressedImage = await _compressImage(file);
    final compressedFile = File(compressedImage.path);

    final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['idEmployee'] = idEmployee.toString();
    request.fields['anggotaBpjs'] = anggotaBpjs;
    request.fields['fieldName'] = fieldName;

    // Kirim file gambar langsung (bukan PDF)
    request.files.add(await http.MultipartFile.fromPath('Files', compressedFile.path));
    request.fields['FileTypes'] = fieldName;

    print("Fields: ${request.fields}");
    print("Files: ${request.files.map((f) => f.filename).toList()}");

    var response = await request.send();

    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      print("✅ Upload berhasil!");
    } else {
      print("❌ Gagal upload: ${response.statusCode}");
      print("Respons: $responseBody");
      throw Exception("Gagal upload: $responseBody");
    }
  } catch (e) {
    print("❌ Terjadi kesalahan: $e");
    rethrow;
  }
}

Future<void> uploadBpjsDocumentsCompressed({
  required int idEmployee,
  required String anggotaBpjs,
  required List<String> fieldNames,
  required List<File> files,
  String? anakKe,
}) async {
  try {
    if (files.isEmpty || fieldNames.isEmpty) {
      throw Exception("Files dan FileTypes tidak boleh kosong.");
    }

    if (files.length != fieldNames.length) {
      throw Exception("Jumlah Files dan FileTypes harus sama.");
    }

    final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan field ke request
    request.fields['IdEmployee'] = idEmployee.toString();
    request.fields['AnggotaBpjs'] = anggotaBpjs;
    request.fields['TglPengajuan'] = DateTime.now().toIso8601String();

    if (anakKe != null) {
      request.fields['AnakKe'] = anakKe;
    }

    // Tambahkan file dan tipe file
    for (int i = 0; i < files.length; i++) {
      request.files.add(await http.MultipartFile.fromPath('Files', files[i].path));
      request.fields['FileTypes[$i]'] = fieldNames[i]; // Format array untuk FileTypes
    }

    print("Fields: ${request.fields}");
    print("Files: ${request.files.map((f) => f.filename).toList()}");

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print("✅ Upload berhasil!");
    } else {
      print("❌ Gagal upload: ${response.statusCode}");
      print("Respons: $responseBody");
      throw Exception("Gagal upload: $responseBody");
    }
  } catch (e) {
    print("❌ Terjadi kesalahan: $e");
    rethrow;
  }
}

Future<void> uploadBpjsDocuments({
  required int idEmployee,
  required String anggotaBpjs,
  String? anakKe,
  String? urlKk,
  String? urlSuratNikah,
  String? urlAkteLahir,
  String? urlSuratPotongGaji,
}) async {
  try {
    final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');
    final body = {
      "Id": 0,
      "IdEmployee": idEmployee,
      "TglPengajuan": DateTime.now().toIso8601String(),
      "AnggotaBpjs": anggotaBpjs,
      "AnakKe": anakKe ?? "",
      "UrlKk": urlKk ?? "",
      "UrlSuratNikah": urlSuratNikah ?? "",
      "UrlAkteLahir": urlAkteLahir ?? "",
      "UrlSuratPotongGaji": urlSuratPotongGaji ?? "",
      "CreatedAt": DateTime.now().toIso8601String(),
      "UpdatedAt": DateTime.now().toIso8601String(),
    };

    print("Payload: ${jsonEncode(body)}");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Upload berhasil!");
    } else {
      print("❌ Gagal upload: ${response.statusCode}");
      print("Respons: ${response.body}");
      throw Exception("Gagal upload: ${response.body}");
    }
  } catch (e) {
    print("❌ Terjadi kesalahan: $e");
    rethrow;
  }
}

Future<void> uploadBpjsDocumentsMultipart({
  required int idEmployee,
  required String anggotaBpjs,
  String? anakKe,
  File? urlKk,
  File? urlSuratNikah,
  File? urlAkteLahir,
  File? urlSuratPotongGaji,
}) async {
  try {
    final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs/upload');
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan field ke request
    request.fields['IdEmployee'] = idEmployee.toString();
    request.fields['AnggotaBpjs'] = anggotaBpjs;
    request.fields['TglPengajuan'] = DateTime.now().toIso8601String();
    request.fields['AnakKe'] = anakKe ?? "";

    // Tambahkan file jika ada
    if (urlKk != null) {
      request.files.add(await http.MultipartFile.fromPath('UrlKk', urlKk.path));
    }
    if (urlSuratNikah != null) {
      request.files.add(await http.MultipartFile.fromPath('UrlSuratNikah', urlSuratNikah.path));
    }
    if (urlAkteLahir != null) {
      request.files.add(await http.MultipartFile.fromPath('UrlAkteLahir', urlAkteLahir.path));
    }
    if (urlSuratPotongGaji != null) {
      request.files.add(await http.MultipartFile.fromPath('UrlSuratPotongGaji', urlSuratPotongGaji.path));
    }

    print("Fields: ${request.fields}");
    print("Files: ${request.files.map((f) => f.filename).toList()}");

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print("✅ Upload berhasil!");
    } else {
      print("❌ Gagal upload: ${response.statusCode}");
      print("Respons: $responseBody");
      throw Exception("Gagal upload: $responseBody");
    }
  } catch (e) {
    print("❌ Terjadi kesalahan: $e");
    rethrow;
  }
}

// Fungsi untuk mengompres gambar
Future<XFile> _compressImage(File file) async {
  final dir = await getTemporaryDirectory();
  final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

  final compressedFile = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 70, // Sesuaikan kualitas kompresi
  );

  if (compressedFile == null) {
    throw Exception("Gagal mengompres gambar");
  }

  return compressedFile;
}

// Fungsi untuk mengonversi gambar menjadi PDF
Future<File> _convertImageToPdf(File imageFile) async {
  final pdf = pw.Document();

  final image = pw.MemoryImage(imageFile.readAsBytesSync());
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.Image(image),
      ),
    ),
  );

  final dir = await getTemporaryDirectory();
  final pdfPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
  final pdfFile = File(pdfPath);

  await pdfFile.writeAsBytes(await pdf.save());
  return pdfFile;
}