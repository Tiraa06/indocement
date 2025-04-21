import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> uploadBpjsDocument({
  required int idEmployee,
  required String anggotaBpjs,
  required String fieldName, // contoh: urlKk atau urlSuratNikah
  required File file,
}) async {
  final uri = Uri.parse('http://213.35.123.110:5555/api/Bpjs');

  var request = http.MultipartRequest('POST', uri);
  request.fields['idEmployee'] = idEmployee.toString();
  request.fields['anggotaBpjs'] = anggotaBpjs;
  request.fields['tglPengajuan'] = DateTime.now().toIso8601String();
  request.fields[fieldName] = file.path;

  request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

  var response = await request.send();

  if (response.statusCode == 200) {
    print("Upload berhasil!");
  } else {
    print("Gagal upload: ${response.statusCode}");
  }
}
