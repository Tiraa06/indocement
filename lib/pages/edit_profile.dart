import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart'; // Tambahkan untuk format tanggal

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
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  Map<String, dynamic> fullData = {};
  int? _userId;

  @override
  void initState() {
    super.initState();
    print('EditProfilePage initState called');
    _fetchInitialData();
  }

  Future<String> _fetchSectionName(int? idSection) async {
    if (idSection == null || idSection <= 0) {
      print('Invalid or missing IdSection: $idSection');
      return 'Tidak Tersedia';
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.140:5555/api/Sections/$idSection'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Fetch Section Status: ${response.statusCode}');
      print('Fetch Section Body: ${response.body}');

      if (response.statusCode == 200) {
        final sectionData = jsonDecode(response.body);
        return sectionData['NamaSection']?.toString() ?? 'Tidak Tersedia';
      } else {
        print('Failed to fetch section data: ${response.statusCode}');
        return 'Tidak Tersedia';
      }
    } catch (e) {
      print('Error fetching section data: $e');
      return 'Tidak Tersedia';
    }
  }

  Future<void> _fetchInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = widget.employeeId ?? prefs.getInt('idEmployee');
    final userId = prefs.getInt('id');

    print(
        'SharedPreferences: ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(", ")}');
    print('employeeId: $employeeId, userId: $userId');

    setState(() {
      _userId = userId;
      _employeeNameController.text = prefs.getString('employeeName') ??
          widget.employeeName ??
          "Nama Tidak Tersedia";
      _phoneController.text = prefs.getString('telepon') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _jobTitleController.text = prefs.getString('jobTitle') ?? widget.jobTitle;
      _livingAreaController.text = prefs.getString('livingArea') ?? '';
      _photoUrl = widget.urlFoto ?? prefs.getString('urlFoto');
    });

    if (employeeId == null || employeeId <= 0) {
      print('Invalid or missing employeeId: $employeeId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ID karyawan tidak valid, silakan login ulang')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.140:5555/api/Employees/$employeeId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Fetch Employee Status: ${response.statusCode}');
      print('Fetch Employee Body: ${response.body}');

      if (response.statusCode == 200) {
        final employee = jsonDecode(response.body);
        print('Employee Data Keys: ${employee.keys}');

        // Ambil IdSection dan kemudian cari SectionName
        final idSection = employee['IdSection'] != null
            ? int.tryParse(employee['IdSection'].toString())
            : null;
        final sectionName = await _fetchSectionName(idSection);

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
          _birthDateController.text = employee['BirthDate'] ?? '';
          _employeeNoController.text = employee['EmployeeNo'] ?? '';
          _serviceDateController.text = employee['ServiceDate'] ?? '';
          _noBpjsController.text = employee['NoBpjs'] ?? '';
          _genderController.text = employee['Gender'] ?? '';
          _educationController.text = employee['Education'] ?? '';
          _workLocationController.text = employee['WorkLocation'] ?? '';
          _sectionController.text = sectionName;

          // Tambahkan URL dasar jika UrlFoto adalah path relatif
          if (employee['UrlFoto'] != null && employee['UrlFoto'].isNotEmpty) {
            if (employee['UrlFoto'].startsWith('/')) {
              _photoUrl = 'http://192.168.100.140:5555${employee['UrlFoto']}';
            } else {
              _photoUrl = employee['UrlFoto'];
            }
          } else {
            _photoUrl = null; // Gunakan ikon profil jika URL tidak valid
          }
        });

        await prefs.setString('employeeName', _employeeNameController.text);
        await prefs.setString('jobTitle', _jobTitleController.text);
        await prefs.setString('livingArea', _livingAreaController.text);
        if (_photoUrl != null) {
          await prefs.setString('urlFoto', _photoUrl!);
        }

        print('Updated employeeName: ${_employeeNameController.text}');
      } else {
        print('Failed to fetch employee data: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _userId;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna tidak ditemukan')),
      );
      return;
    }

    if (_emailController.text.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    // Validasi format tanggal (opsional, tergantung format yang diharapkan API)
    if (_birthDateController.text.isNotEmpty) {
      try {
        DateFormat('yyyy-MM-dd').parse(_birthDateController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Format tanggal lahir tidak valid (gunakan yyyy-MM-dd)')),
        );
        return;
      }
    }

    await prefs.setString('telepon', _phoneController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('livingArea', _livingAreaController.text);
    await prefs.setString(
        'birthDate', _birthDateController.text); // Simpan ke SharedPreferences

    final updatedPayload = {
      'Id': userId,
      'IdEmployee': widget.employeeId ?? prefs.getInt('idEmployee'),
      'Email': _emailController.text,
      'Telepon': _phoneController.text,
      'EmployeeName': _employeeNameController.text,
      'JobTitle': _jobTitleController.text,
      'LivingArea': _livingAreaController.text,
      'BirthDate': _birthDateController.text, // Tambahkan BirthDate ke payload
    };

    try {
      final response = await http
          .put(
            Uri.parse('http://192.168.100.140:5555/api/User/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedPayload),
          )
          .timeout(const Duration(seconds: 10));

      print('Update Status: ${response.statusCode}');
      print('Update Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan berhasil disimpan')),
        );
        setState(() => isEditing = false);
        Navigator.pop(context, {
          'employeeName': _employeeNameController.text,
          'jobTitle': _jobTitleController.text,
          'urlFoto': _photoUrl,
          'employeeId': widget.employeeId ?? prefs.getInt('idEmployee'),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      print('File path: ${image.path}');
      setState(() {
        _selectedImage = File(image.path);
      });

      // Tampilkan popup konfirmasi
      _showImageConfirmationPopup(File(image.path));
    }
  }

  Future<void> _uploadImage(File image) async {
    final employeeId = widget.employeeId;

    if (employeeId == null) {
      print('Employee ID is null');
      return;
    }

    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'http://192.168.100.140:5555/api/Employees/$employeeId/UrlFoto'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'File',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.headers.addAll({
        'accept': '/',
        'Content-Type': 'multipart/form-data',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 204) {
        print('Image uploaded successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar berhasil diunggah')),
        );
        _fetchInitialData(); // Perbarui data profil
      } else {
        print('Failed to upload image: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengunggah gambar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% layar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image,
                    width: 200, // Lebar gambar
                    height: 200, // Tinggi gambar
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah anda yakin ingin mengganti foto profil?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup popup
                        _uploadImage(image); // Unggah gambar ke API
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup popup
                        setState(() {
                          _selectedImage = null; // Batalkan gambar yang dipilih
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

  // Tambahkan method untuk DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate;
    try {
      initialDate = _birthDateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_birthDateController.text)
          : DateTime.now();
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool readOnly = false,
  }) {
    final editableFields = [
      'Nomor Telepon',
      'Email',
      'Living Area',
      'Tanggal Lahir'
    ]; // Tambahkan Tanggal Lahir
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly || !(isEditing && editableFields.contains(label)),
        keyboardType: keyboardType,
        onTap: label == 'Tanggal Lahir' && isEditing
            ? () =>
                _selectDate(context) // Tambahkan DatePicker untuk Tanggal Lahir
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: inputBorder,
          labelStyle: GoogleFonts.poppins(fontSize: 16),
          suffixIcon: label == 'Tanggal Lahir' && isEditing
              ? const Icon(Icons.calendar_today)
              : null,
        ),
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
                color: const Color(0xFF1572E8),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Saya',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        backgroundColor: const Color(0xFF1572E8),
        actions: [
          IconButton(
            icon:
                Icon(isEditing ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: () => setState(() => isEditing = !isEditing),
          )
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
              onPressed: isEditing
                  ? _pickImage
                  : null, // Pilih gambar jika sedang mengedit
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1572E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard('Informasi Pribadi', [
              _buildTextField(
                  label: 'Nama Karyawan',
                  controller: _employeeNameController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Tanggal Lahir',
                  controller: _birthDateController,
                  keyboardType: TextInputType.datetime),
              _buildTextField(
                  label: 'Jenis Kelamin',
                  controller: _genderController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Pendidikan',
                  controller: _educationController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
            ]),
            _buildSectionCard('Informasi Pekerjaan', [
              _buildTextField(
                  label: 'Nomor Karyawan',
                  controller: _employeeNoController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Jabatan',
                  controller: _jobTitleController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Tanggal Mulai Kerja',
                  controller: _serviceDateController,
                  keyboardType: TextInputType.datetime,
                  readOnly: true),
              _buildTextField(
                  label: 'Nomor BPJS',
                  controller: _noBpjsController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Lokasi Kerja',
                  controller: _workLocationController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
              _buildTextField(
                  label: 'Section',
                  controller: _sectionController,
                  keyboardType: TextInputType.text,
                  readOnly: true),
            ]),
            _buildSectionCard('Kontak', [
              _buildTextField(
                  label: 'Nomor Telepon',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(
                  label: 'Living Area',
                  controller: _livingAreaController,
                  keyboardType: TextInputType.text),
            ]),
            const SizedBox(height: 16),
            if (isEditing)
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1572E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
                child: Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
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
    _genderController.dispose();
    _educationController.dispose();
    _workLocationController.dispose();
    _sectionController.dispose();
    super.dispose();
  }
}
