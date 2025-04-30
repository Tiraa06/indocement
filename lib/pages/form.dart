import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  final List<XFile> _selectedFiles = [];

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
    // _updateTime();
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

  // void _updateTime() {
  //   final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  //   final formatter = DateFormat('dd MMMM yyyy, HH:mm:ss');
  //   setState(() {
  //     _currentTime = formatter.format(now);
  //   });
  //   Future.delayed(const Duration(seconds: 1), _updateTime);
  // }

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
    final double paddingValue = screenWidth < 400 ? 16.0 : 24.0;
    final double fontSizeLabel = screenWidth < 400 ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "HR Care",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // child: Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       const Icon(Icons.access_time,
                //           color: Color(0xFF1E88E5), size: 22),
                //       const SizedBox(width: 8),
                //       Text(
                //         _currentTime.isEmpty
                //             ? 'Loading...'
                //             : 'WIB: $_currentTime',
                //         style: GoogleFonts.poppins(
                //           fontSize: fontSizeLabel - 2,
                //           color: Colors.black87,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Form Keluhan",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _department,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: _departments
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSizeLabel - 2,
                                      color: Colors.black87,
                                    ),
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
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeLabel - 2,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Message',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeLabel,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Type your message here...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lines: $_lines | Words: $_words | Saved',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: fontSizeLabel - 2,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachment',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeLabel,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _chooseFile,
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: Text(
                              'Choose File',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel - 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFiles.isEmpty
                                  ? 'No file chosen'
                                  : '${_selectedFiles.length} file(s) selected',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel - 2,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFiles.isNotEmpty)
                        Column(
                          children: _selectedFiles
                              .map((file) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            file.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSizeLabel - 2,
                                              color: Colors.black87,
                                            ),
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
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addMoreFiles,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            'Add More',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeLabel - 2,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Allowed extensions: jpg, gif, jpeg, png, txt, pdf (Max: 10MB)',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeLabel - 2,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'SUBMIT',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeLabel,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeLabel,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}