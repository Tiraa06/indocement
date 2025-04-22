import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeluhanPage extends StatefulWidget {
  const KeluhanPage({super.key});

  @override
  _KeluhanPageState createState() => _KeluhanPageState();
}

class _KeluhanPageState extends State<KeluhanPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _department;
  List<String> _departments = [];

  List<XFile> _selectedFiles = [];

  int _lines = 0;
  int _words = 0;

  String _currentTime = '';

  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchDepartments();
    _messageController.addListener(_updateLinesAndWords);
    _updateTime();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    print('SharedPreferences keys: ${prefs.getKeys()}');
    for (var key in prefs.getKeys()) {
      print('$key: ${prefs.get(key)}');
    }

    final employeeName = prefs.getString('employeeName') ?? 'Unknown';
    final email = prefs.getString('email') ?? 'Unknown';
    final employeeId = prefs.getInt('idEmployee');

    setState(() {
      _nameController.text = employeeName;
      _emailController.text = email;
      _employeeId = employeeId;
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http
          .get(Uri.parse('http://213.35.123.110:5555/api/departements'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _departments =
              data.map((dept) => dept['NamaDepartement'] as String).toList();
          _department = _departments.isNotEmpty ? _departments[0] : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load departments')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching departments: $e')),
      );
    }
  }

  void _updateLinesAndWords() {
    final text = _messageController.text;
    print('Message input: $text');
    setState(() {
      _lines = text.isEmpty ? 0 : text.split('\n').length;
      _words = text.length;
    });
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formatter = DateFormat('dd MMMM yyyy, HH:mm:ss');
    setState(() {
      _currentTime = formatter.format(now);
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> _chooseFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['jpg', 'gif', 'jpeg', 'png', 'txt', 'pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 10MB limit')),
          );
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _addMoreFiles() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['jpg', 'gif', 'jpeg', 'png', 'txt', 'pdf'],
      );
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);

      if (files.isNotEmpty) {
        const maxSize = 10 * 1024 * 1024; // 10MB
        for (var file in files) {
          final fileSize = await file.length();
          if (fileSize > maxSize) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File ${file.name} exceeds 10MB limit')),
            );
            return;
          }
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding files: $e')),
      );
    }
  }

  Future<void> _submitComplaint() async {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Employee ID not found. Please log in again.')),
      );
      return;
    }
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject is required')),
      );
      return;
    }
    if (_department == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message is required')),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://213.35.123.110:5555/api/keluhans'),
      );

      print('Submitting complaint with the following data:');
      print('IdEmployee: $_employeeId');
      print('Keluhan: ${_messageController.text}');
      print(
          'TglKeluhan: ${DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String()}');
      print('Status: Terkirim');
      print('Subject: ${_subjectController.text}');
      print('Department: $_department');

      request.fields['IdEmployee'] = _employeeId.toString();
      request.fields['Keluhan'] = _messageController.text;
      request.fields['TglKeluhan'] = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 7))
          .toIso8601String();
      request.fields['CreatedAt'] = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 7))
          .toIso8601String();
      request.fields['UpdatedAt'] = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 7))
          .toIso8601String();
      request.fields['Status'] = 'Terkirim';
      request.fields['subject'] = _subjectController.text;
      request.fields['NamaDepartement'] = _department!;

      // Tambahkan daftar nama file yang dipisahkan dengan koma
      if (_selectedFiles.isNotEmpty) {
        final fileNames = _selectedFiles.map((file) => file.name).join(',');
        request.fields['NamaFile'] = fileNames;
        print('NamaFile: $fileNames');
      }

      for (var file in _selectedFiles) {
        var multipartFile = await http.MultipartFile.fromPath(
          'FotoKeluhan',
          file.path,
          filename: file.name,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${responseBody.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to submit complaint: ${response.statusCode} - ${responseBody.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.removeListener(_updateLinesAndWords);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingValue = screenWidth < 400 ? 16.0 : 20.0;
    final double fontSizeLabel = screenWidth < 400 ? 14.0 : 16.0;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.black54, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentTime.isEmpty
                          ? 'Loading...'
                          : 'WIB: $_currentTime',
                      style: GoogleFonts.roboto(
                        fontSize: fontSizeLabel,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1572E8), Color(0xFF3B94F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Form Keluhan",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _department,
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: _departments
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept,
                            style: GoogleFonts.roboto(fontSize: fontSizeLabel),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _department = value;
                  });
                },
                hint: Text(
                  _departments.isEmpty
                      ? 'Loading departments...'
                      : 'Select Department',
                  style: GoogleFonts.roboto(fontSize: fontSizeLabel),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.roboto(
                        fontSize: fontSizeLabel, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LINES: $_lines - Words: $_words - saved',
                    style: GoogleFonts.roboto(
                        color: Colors.grey, fontSize: fontSizeLabel - 2),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attachment',
                    style: GoogleFonts.roboto(
                      fontSize: fontSizeLabel,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _chooseFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          'Choose File',
                          style:
                              GoogleFonts.roboto(fontSize: fontSizeLabel - 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedFiles.isEmpty
                              ? 'No file chosen'
                              : '${_selectedFiles.length} file(s) selected',
                          style: GoogleFonts.roboto(
                              fontSize: fontSizeLabel - 2, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFiles.isNotEmpty) ...[
                    ..._selectedFiles.map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            file.name,
                            style: GoogleFonts.roboto(
                                fontSize: fontSizeLabel - 2,
                                color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _addMoreFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        '+ Add More',
                        style: GoogleFonts.roboto(fontSize: fontSizeLabel - 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ALLOWED FILE EXTENSIONS: jpg, gif, jpeg, png, txt, pdf (Max size: 10MB)',
                    style: GoogleFonts.roboto(
                        fontSize: fontSizeLabel - 2, color: Colors.grey),
                  ),
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._selectedFiles.map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: GoogleFonts.roboto(
                                      fontSize: fontSizeLabel - 2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedFiles.remove(file);
                                  });
                                },
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1572E8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'SUBMIT',
                        style: GoogleFonts.roboto(
                            fontSize: fontSizeLabel, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                            fontSize: fontSizeLabel, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
