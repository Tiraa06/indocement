import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final String employeeName;
  final String jobTitle;
  final String? urlFoto;
  final int? employeeId;

  const EditProfilePage({
    super.key,
    required this.employeeName,
    required this.jobTitle,
    this.urlFoto,
    this.employeeId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool isEditing = false;
  File? _selectedImage;
  File? _ktpImage;
  String? _photoUrl;
  final bool _isUploading = false;
  final OutlineInputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey),
  );

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _livingAreaController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _employeeNoController = TextEditingController();
  final TextEditingController _serviceDateController = TextEditingController();
  final TextEditingController _noBpjsController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  String? _selectedGender;
  String? _selectedEducation;
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _educationOptions = [
    'TK',
    'SD',
    'SMP/Sederajat',
    'SLTA/Sederajat',
    'Diploma/D1',
    'Diploma/D2',
    'Diploma/D3',
    'Diploma/D4',
    'Sarjana/S1',
    'Magister/S2',
    'Doktor/S3',
    'lainnya',
  ];

  Map<String, dynamic> fullData = {};
  int? _userId;
  final Map<String, String> _changedFields = {};

  String? _mapGenderFromApi(String? apiValue) {
    if (apiValue == null) return null;
    switch (apiValue.toLowerCase()) {
      case 'l':
      case 'laki-laki':
      case 'male':
        return 'Laki-laki';
      case 'p':
      case 'perempuan':
      case 'female':
        return 'Perempuan';
      default:
        return null;
    }
  }

  String? _mapEducationFromApi(String? apiValue) {
    if (apiValue == null) return null;
    if (_educationOptions.contains(apiValue)) {
      return apiValue;
    }
    return null;
  }

  String? _formatDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _startPolling();
  }

  Future<String> _fetchSectionName(int? idSection) async {
    if (idSection == null || idSection <= 0) {
      return 'Tidak Tersedia';
    }

    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Sections/$idSection'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final sectionData = jsonDecode(response.body);
        return sectionData['NamaSection']?.toString() ?? 'Tidak Tersedia';
      } else {
        return 'Tidak Tersedia';
      }
    } catch (e) {
      return 'Tidak Tersedia';
    }
  }

  Future<void> _fetchVerifData() async {
    final employeeId = widget.employeeId;
    if (employeeId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'http://103.31.235.237:5555/api/VerifData/requests?employeeId=$employeeId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final verifData = data
            .cast<Map<String, dynamic>>()
            .where((verif) =>
                verif['EmployeeId']?.toString() == employeeId.toString() &&
                (verif['Status'] == 'Pending' || verif['Status'] == 'Approved'))
            .toList();

        for (var verif in verifData) {
          final fieldName = verif['FieldName']?.toString();
          final newValueRaw = verif['NewValue']?.toString();
          final status = verif['Status']?.toString();
          if (fieldName != null && newValueRaw != null && status != null) {
            String? newValue = newValueRaw;
            if (fieldName == 'BirthDate' || fieldName == 'ServiceDate') {
              newValue = _formatDateOnly(newValueRaw);
            }

            setState(() {
              if (status == 'Approved') {
                switch (fieldName) {
                  case 'EmployeeName':
                    _employeeNameController.text = newValue ?? '';
                    fullData['EmployeeName'] = newValue;
                    break;
                  case 'BirthDate':
                    _birthDateController.text = newValue ?? '';
                    fullData['BirthDate'] = newValue;
                    break;
                  case 'Gender':
                    _selectedGender = _mapGenderFromApi(newValue);
                    fullData['Gender'] = newValue;
                    break;
                  case 'Education':
                    _selectedEducation = _mapEducationFromApi(newValue);
                    fullData['Education'] = newValue;
                    break;
                  case 'EmployeeNo':
                    _employeeNoController.text = newValue ?? '';
                    fullData['EmployeeNo'] = newValue;
                    break;
                  case 'JobTitle':
                    _jobTitleController.text = newValue ?? '';
                    fullData['JobTitle'] = newValue;
                    break;
                  case 'ServiceDate':
                    _serviceDateController.text = newValue ?? '';
                    fullData['ServiceDate'] = newValue;
                    break;
                  case 'NoBpjs':
                    _noBpjsController.text = newValue ?? '';
                    fullData['NoBpjs'] = newValue;
                    break;
                  case 'WorkLocation':
                    _workLocationController.text = newValue ?? '';
                    fullData['WorkLocation'] = newValue;
                    break;
                  case 'Section':
                    _sectionController.text = newValue ?? '';
                    fullData['Section'] = newValue;
                    break;
                  case 'Telepon':
                    _phoneController.text = newValue ?? '';
                    fullData['Telepon'] = newValue;
                    break;
                  case 'Email':
                    _emailController.text = newValue ?? '';
                    fullData['Email'] = newValue;
                    break;
                  case 'LivingArea':
                    _livingAreaController.text = newValue ?? '';
                    fullData['LivingArea'] = newValue;
                    break;
                }
                final prefs = SharedPreferences.getInstance();
                prefs.then((p) =>
                    p.setString(fieldName.toLowerCase(), newValue ?? ''));
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching verification data: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = widget.employeeId ?? prefs.getInt('idEmployee');
    final userId = prefs.getInt('id');

    setState(() {
      _userId = userId;
      _employeeNameController.text =
          prefs.getString('employeeName') ?? widget.employeeName;
      _phoneController.text = prefs.getString('telepon') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _jobTitleController.text = prefs.getString('jobTitle') ?? widget.jobTitle;
      _livingAreaController.text = prefs.getString('livingArea') ?? '';
      _photoUrl = widget.urlFoto ?? prefs.getString('urlFoto');
    });

    if (employeeId == null || employeeId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ID karyawan tidak valid, silakan login ulang')),
      );
      return;
    }

    await _fetchVerifData();

    try {
      final response = await http.get(
        Uri.parse('http://103.31.235.237:5555/api/Employees/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final employee = jsonDecode(response.body);
        final idSection = employee['IdSection'] != null
            ? int.tryParse(employee['IdSection'].toString())
            : null;
        final sectionName = await _fetchSectionName(idSection);

        String? validatedBirthDate = _formatDateOnly(employee['BirthDate']);
        if (validatedBirthDate != null && validatedBirthDate.isNotEmpty) {
          try {
            final parsedDate =
                DateFormat('yyyy-MM-dd').parse(validatedBirthDate);
            final firstDate = DateTime(1900);
            if (parsedDate.isBefore(firstDate)) {
              validatedBirthDate = '';
            }
          } catch (e) {
            validatedBirthDate = '';
          }
        }

        String? validatedServiceDate = _formatDateOnly(employee['ServiceDate']);
        if (validatedServiceDate != null && validatedServiceDate.isNotEmpty) {
          try {
            final parsedDate =
                DateFormat('yyyy-MM-dd').parse(validatedServiceDate);
            final firstDate = DateTime(1900);
            if (parsedDate.isBefore(firstDate)) {
              validatedServiceDate = '';
            }
          } catch (e) {
            validatedServiceDate = '';
          }
        }

        setState(() {
          fullData = employee;
          _employeeNameController.text =
              employee['EmployeeName']?.isNotEmpty == true
                  ? employee['EmployeeName']
                  : _employeeNameController.text;
          _jobTitleController.text =
              employee['JobTitle'] ?? _jobTitleController.text;
          _livingAreaController.text =
              employee['LivingArea'] ?? _livingAreaController.text;
          _birthDateController.text = validatedBirthDate ?? '';
          _employeeNoController.text = employee['EmployeeNo'] ?? '';
          _serviceDateController.text = validatedServiceDate ?? '';
          _noBpjsController.text = employee['NoBpjs'] ?? '';
          _selectedGender = _mapGenderFromApi(employee['Gender']);
          _selectedEducation = _mapEducationFromApi(employee['Education']);
          _workLocationController.text = employee['WorkLocation'] ?? '';
          _sectionController.text = sectionName;

          if (employee['UrlFoto'] != null && employee['UrlFoto'].isNotEmpty) {
            _photoUrl = employee['UrlFoto'].startsWith('/')
                ? 'http://103.31.235.237:5555${employee['UrlFoto']}'
                : employee['UrlFoto'];
          } else {
            _photoUrl = null;
          }
        });

        await prefs.setString('employeeNo', _employeeNoController.text);
        await prefs.setString('employeeName', _employeeNameController.text);
        await prefs.setString('jobTitle', _jobTitleController.text);
        await prefs.setString('livingArea', _livingAreaController.text);
        if (_photoUrl != null) {
          await prefs.setString('urlFoto', _photoUrl!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _startPolling() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        await _fetchVerifData();
      } else {
        timer.cancel();
      }
    });
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Permintaan berhasil dikirim, silakan menunggu verifikasi dari PIC Anda",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1572E8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitChangeRequests() async {
    final employeeId = widget.employeeId;
    if (employeeId == null || _ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ID karyawan atau foto KTP tidak ditemukan')),
      );
      return;
    }

    bool atLeastOneSuccess = false;
    List<String> failedFields = [];

    for (var entry in _changedFields.entries) {
      final fieldName = entry.key;
      final newValue = entry.value;
      final oldValue = fullData[fieldName] ?? '';

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://103.31.235.237:5555/api/VerifData/request'),
        );
        request.fields['EmployeeId'] = employeeId.toString();
        request.fields['FieldName'] = fieldName;
        request.fields['OldValue'] = oldValue.toString();
        request.fields['NewValue'] = newValue;
        request.files.add(await http.MultipartFile.fromPath(
          'SupportingDocumentPath',
          _ktpImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
        request.headers.addAll({
          'accept': '*/*',
          'Content-Type': 'multipart/form-data',
        });

        final response =
            await request.send().timeout(const Duration(seconds: 10));
        final responseBody =
            await response.stream.bytesToString().catchError((e) {
          print('Error reading response stream: $e');
          return '';
        });

        print('Response status for $fieldName: ${response.statusCode}');
        print('Response body for $fieldName: $responseBody');

        if (response.statusCode >= 200 && response.statusCode <= 204) {
          atLeastOneSuccess = true;
          await _fetchVerifData();
          await _fetchInitialData();
        } else {
          failedFields.add(fieldName);
          print(
              'Failed to submit $fieldName: ${response.statusCode} - $responseBody');
        }
      } catch (e) {
        failedFields.add(fieldName);
        print('Error submitting $fieldName: $e');
      }
    }

    setState(() {
      isEditing = false;
      _ktpImage = null;
      _changedFields.clear();
    });

    if (atLeastOneSuccess) {
      _showSuccessModal();
    }
    if (failedFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Gagal mengirim perubahan untuk field: ${failedFields.join(', ')}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _showImageConfirmationPopup(File(image.path));
    }
  }

  Future<void> _pickKtpImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _ktpImage = File(image.path);
      });
      _showKtpConfirmationPopup(File(image.path));
    }
  }

  Future<void> _uploadImage(File image) async {
    final employeeId = widget.employeeId;
    if (employeeId == null) return;

    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'http://103.31.235.237:5555/api/Employees/$employeeId/UrlFoto'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'File',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.headers.addAll({
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      });

      final response = await request.send();
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar berhasil diunggah')),
        );
        await _fetchInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengunggah gambar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _showImageConfirmationPopup(File image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image,
                      width: 200, height: 200, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah Anda yakin ingin mengganti foto profil?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _uploadImage(image);
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKtpConfirmationPopup(File image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image,
                      width: 200, height: 200, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah Anda yakin ingin menggunakan foto KTP ini?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _ktpImage = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditConfirmationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Apakah Anda yakin ingin mengedit profil Anda?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() => isEditing = true);
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRequestConfirmationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Apakah Anda yakin ingin mengajukan perubahan berikut?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ..._changedFields.entries.map((entry) {
                    final fieldName = entry.key;
                    final newValue = entry.value;
                    final oldValue = fullData[fieldName] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Field: $fieldName\nDari: $oldValue\nMenjadi: $newValue",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }),
                  if (_ktpImage == null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Silakan unggah foto KTP terlebih dahulu.",
                      textAlign: TextAlign.center,
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: _ktpImage != null ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        onPressed: _ktpImage != null
                            ? () {
                                Navigator.of(context).pop();
                                _submitChangeRequests();
                              }
                            : null,
                        tooltip: _ktpImage == null
                            ? 'Unggah foto KTP terlebih dahulu'
                            : 'Konfirmasi perubahan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel,
                            color: Colors.red, size: 32),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      String fieldName,
      String oldValue) async {
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime.now();
    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
        if (initialDate.isBefore(firstDate)) {
          initialDate = firstDate;
        }
        if (initialDate.isAfter(lastDate)) {
          initialDate = lastDate;
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (controller.text != oldValue && controller.text.isNotEmpty) {
          _changedFields[fieldName] = controller.text;
        } else {
          _changedFields.remove(fieldName);
        }
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool isDateField = false,
    String? fieldName,
    String? oldValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: !isEditing || (isDateField && isEditing),
        keyboardType: keyboardType,
        onTap: isDateField && isEditing
            ? () => _selectDate(context, controller, fieldName!, oldValue!)
            : null,
        onChanged: isEditing && fieldName != null && oldValue != null
            ? (value) {
                setState(() {
                  if (value != oldValue && value.isNotEmpty) {
                    _changedFields[fieldName] = value;
                  } else {
                    _changedFields.remove(fieldName);
                  }
                });
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: inputBorder,
          labelStyle: GoogleFonts.poppins(fontSize: 16),
          suffixIcon: isDateField && isEditing
              ? const Icon(Icons.calendar_today)
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String fieldName,
    required String oldValue,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value != null && items.contains(value) ? value : null,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: GoogleFonts.poppins(fontSize: 16)),
          );
        }).toList(),
        onChanged: isEditing
            ? (newValue) {
                onChanged(newValue);
                setState(() {
                  if (newValue != null && newValue != oldValue) {
                    _changedFields[fieldName] = newValue;
                  } else {
                    _changedFields.remove(fieldName);
                  }
                });
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: inputBorder,
          labelStyle: GoogleFonts.poppins(fontSize: 16),
        ),
        hint: Text('Pilih $label',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF1572E8)),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildKtpUploadCard() {
    return GestureDetector(
      onTap: isEditing ? _pickKtpImage : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFF1572E8),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.upload_file, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload KTP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEditing ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    _ktpImage == null
                        ? 'Belum ada file yang dipilih'
                        : _ktpImage!.path.split('/').last,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isEditing ? Colors.black54 : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1572E8),
        actions: [
          IconButton(
            icon:
                Icon(isEditing ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: isEditing
                ? () => setState(() {
                      isEditing = false;
                      _changedFields.clear();
                      _ktpImage = null;
                    })
                : _showEditConfirmationPopup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : (_photoUrl != null && _photoUrl!.isNotEmpty
                          ? NetworkImage(_photoUrl!)
                          : const AssetImage('assets/images/profile.png')),
                  backgroundColor: Colors.grey[200],
                  child: _selectedImage == null &&
                          (_photoUrl == null || _photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                if (_isUploading) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isEditing ? _pickImage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1572E8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text(
                'Edit Foto Profil',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard('Informasi Pribadi', [
              _buildTextField(
                label: 'Nama Karyawan',
                controller: _employeeNameController,
                keyboardType: TextInputType.text,
                fieldName: 'EmployeeName',
                oldValue: fullData['EmployeeName'] ?? '',
              ),
              _buildTextField(
                label: 'Tanggal Lahir',
                controller: _birthDateController,
                keyboardType: TextInputType.datetime,
                isDateField: true,
                fieldName: 'BirthDate',
                oldValue: fullData['BirthDate'] ?? '',
              ),
              _buildDropdownField(
                label: 'Jenis Kelamin',
                value: _selectedGender,
                items: _genderOptions,
                fieldName: 'Gender',
                oldValue: fullData['Gender'] ?? '',
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              _buildDropdownField(
                label: 'Pendidikan',
                value: _selectedEducation,
                items: _educationOptions,
                fieldName: 'Education',
                oldValue: fullData['Education'] ?? '',
                onChanged: (value) =>
                    setState(() => _selectedEducation = value),
              ),
            ]),
            _buildSectionCard('Informasi Pekerjaan', [
              _buildTextField(
                label: 'Nomor Karyawan',
                controller: _employeeNoController,
                keyboardType: TextInputType.text,
                fieldName: 'EmployeeNo',
                oldValue: fullData['EmployeeNo'] ?? '',
              ),
              _buildTextField(
                label: 'Jabatan',
                controller: _jobTitleController,
                keyboardType: TextInputType.text,
                fieldName: 'JobTitle',
                oldValue: fullData['JobTitle'] ?? '',
              ),
              _buildTextField(
                label: 'Tanggal Mulai Kerja',
                controller: _serviceDateController,
                keyboardType: TextInputType.datetime,
                isDateField: true,
                fieldName: 'ServiceDate',
                oldValue: fullData['ServiceDate'] ?? '',
              ),
              _buildTextField(
                label: 'Nomor BPJS',
                controller: _noBpjsController,
                keyboardType: TextInputType.text,
                fieldName: 'NoBpjs',
                oldValue: fullData['NoBpjs'] ?? '',
              ),
              _buildTextField(
                label: 'Lokasi Kerja',
                controller: _workLocationController,
                keyboardType: TextInputType.text,
                fieldName: 'WorkLocation',
                oldValue: fullData['WorkLocation'] ?? '',
              ),
              _buildTextField(
                label: 'Section',
                controller: _sectionController,
                keyboardType: TextInputType.text,
                fieldName: 'Section',
                oldValue: fullData['Section'] ?? '',
              ),
            ]),
            _buildSectionCard('Kontak', [
              _buildTextField(
                label: 'Nomor Telepon',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                fieldName: 'Telepon',
                oldValue: fullData['Telepon'] ?? '',
              ),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                fieldName: 'Email',
                oldValue: fullData['Email'] ?? '',
              ),
              _buildTextField(
                label: 'Living Area',
                controller: _livingAreaController,
                keyboardType: TextInputType.text,
                fieldName: 'LivingArea',
                oldValue: fullData['LivingArea'] ?? '',
              ),
            ]),
            const SizedBox(height: 16),
            _buildKtpUploadCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  isEditing && _ktpImage != null && _changedFields.isNotEmpty
                      ? _showRequestConfirmationPopup
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEditing && _ktpImage != null && _changedFields.isNotEmpty
                        ? const Color(0xFF1572E8)
                        : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text(
                'Ajukan Perubahan',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _livingAreaController.dispose();
    _employeeNameController.dispose();
    _jobTitleController.dispose();
    _birthDateController.dispose();
    _employeeNoController.dispose();
    _serviceDateController.dispose();
    _noBpjsController.dispose();
    _workLocationController.dispose();
    _sectionController.dispose();
    super.dispose();
  }
}
