// ✅ Versi final dengan UI asli dipertahankan
// ✅ Hanya Nomor Telepon, Email, dan Living Area yang bisa diedit
// ✅ Data tersimpan ke SharedPreferences & API dengan format lengkap
// ✅ Semua kolom dari API ditambahkan, read-only kecuali telepon, email, livingArea
// ✅ UI dipercantik dengan pengelompokan Informasi Pribadi, Pekerjaan, dan Kontak

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String jobTitle;
  final String? urlFoto;
  final int? employeeId;

  const EditProfilePage({
    super.key,
    required this.name,
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
  final TextEditingController _idSectionController = TextEditingController();
  final TextEditingController _idEslController = TextEditingController();

  Map<String, dynamic> fullData = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = widget.employeeId ?? prefs.getInt('idEmployee');
    if (employeeId == null) return;

    final response =
        await http.get(Uri.parse('http://213.35.123.110:5555/api/Employees'));
    if (response.statusCode == 200) {
      final List<dynamic> employees = jsonDecode(response.body);
      final employee = employees.firstWhere((e) => e['id'] == employeeId,
          orElse: () => null);
      if (employee != null) {
        setState(() {
          fullData = employee;
          _phoneController.text = employee['telepon'] ?? '';
          _emailController.text = employee['email'] ?? '';
          _livingAreaController.text = employee['livingArea'] ?? '';
          _employeeNameController.text = employee['employeeName'] ?? '';
          _jobTitleController.text = employee['jobTitle'] ?? '';
          _birthDateController.text = employee['birthDate'] ?? '';
          _employeeNoController.text = employee['employeeNo'] ?? '';
          _serviceDateController.text = employee['serviceDate'] ?? '';
          _noBpjsController.text = employee['noBpjs'] ?? '';
          _genderController.text = employee['gender'] ?? '';
          _educationController.text = employee['education'] ?? '';
          _workLocationController.text = employee['workLocation'] ?? '';
          _idSectionController.text = employee['idSection']?.toString() ?? '';
          _idEslController.text = employee['idEsl']?.toString() ?? '';
          _photoUrl = employee['urlFoto'];
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = widget.employeeId ?? prefs.getInt('idEmployee');
    if (employeeId == null) return;

    if (_emailController.text.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    await prefs.setString('phone', _phoneController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('livingArea', _livingAreaController.text);

    final updatedPayload = {
      'id': fullData['id'],
      'employeeNo': fullData['employeeNo'],
      'employeeName': fullData['employeeName'],
      'jobTitle': fullData['jobTitle'],
      'serviceDate': fullData['serviceDate'],
      'birthDate': fullData['birthDate'],
      'noBpjs': fullData['noBpjs'],
      'gender': fullData['gender'],
      'education': fullData['education'],
      'workLocation': fullData['workLocation'],
      'idSection': fullData['idSection'],
      'idEsl': fullData['idEsl'],
      'urlFoto': fullData['urlFoto'],
      'telepon': _phoneController.text,
      'email': _emailController.text,
      'livingArea': _livingAreaController.text,
    };

    final response = await http.put(
      Uri.parse('http://213.35.123.110:5555/api/Employees/$employeeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedPayload),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan berhasil disimpan')),
      );
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${response.statusCode}')),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool readOnly = false,
  }) {
    final editableFields = ['Nomor Telepon', 'Email', 'Living Area'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly || !(isEditing && editableFields.contains(label)),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: inputBorder,
          labelStyle: GoogleFonts.roboto(fontSize: 16),
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
              style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
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
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? NetworkImage(_photoUrl!)
                      : const AssetImage('assets/images/picture.jpg')
                          as ImageProvider,
                  backgroundColor: Colors.grey[200],
                ),
                if (_isUploading) const CircularProgressIndicator(),
              ],
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
                  keyboardType: TextInputType.datetime,
                  readOnly: true),
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
                  label: 'ID Section',
                  controller: _idSectionController,
                  keyboardType: TextInputType.number,
                  readOnly: true),
              _buildTextField(
                  label: 'ID ESL',
                  controller: _idEslController,
                  keyboardType: TextInputType.number,
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
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
                child: Text('Simpan Perubahan',
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
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
    _idSectionController.dispose();
    _idEslController.dispose();
    super.dispose();
  }
}
