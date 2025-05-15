import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
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
  final TextEditingController _sectionController = TextEditingController();

  String? _sectionName;
  int? _idSection;
  final List<XFile> _selectedFiles = [];

  int _lines = 0;
  int _words = 0;
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadProfileData()
        .then((_) => _fetchEmployeeData().then((_) => _fetchSectionName()));
    _messageController.addListener(_updateLinesAndWords);
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

  Future<void> _fetchEmployeeData() async {
    if (_employeeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee ID not found')),
        );
        setState(() {
          _sectionController.text = 'Unknown';
          _sectionName = 'Unknown';
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.140:5555/api/Employees/$_employeeId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _idSection = data['IdSection'] as int?;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load employee data')),
          );
          setState(() {
            _sectionController.text = 'Unknown';
            _sectionName = 'Unknown';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employee data: $e')),
        );
        setState(() {
          _sectionController.text = 'Unknown';
          _sectionName = 'Unknown';
        });
      }
    }
  }

  Future<void> _fetchSectionName() async {
    if (_idSection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section ID not found')),
        );
        setState(() {
          _sectionController.text = 'Unknown';
          _sectionName = 'Unknown';
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.140:5555/api/sections/$_idSection'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _sectionName = data['NamaSection'] as String? ?? 'Unknown';
            _sectionController.text = _sectionName!;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load section name')),
          );
          setState(() {
            _sectionController.text = 'Unknown';
            _sectionName = 'Unknown';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching section name: $e')),
        );
        setState(() {
          _sectionController.text = 'Unknown';
          _sectionName = 'Unknown';
        });
      }
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size exceeds 10MB limit')),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File ${file.name} exceeds 10MB limit')),
              );
            }
            return;
          }
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding files: $e')),
        );
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_employeeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee ID not found. Please log in again.')),
        );
      }
      return;
    }
    if (_subjectController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject is required')),
        );
      }
      return;
    }
    if (_sectionName == null ||
        _sectionName!.isEmpty ||
        _sectionName == 'Unknown') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section is required')),
        );
      }
      return;
    }
    if (_messageController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message is required')),
        );
      }
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.140:5555/api/keluhans'),
      );

      print('Submitting complaint with the following data:');
      print('IdEmployee: $_employeeId');
      print('Keluhan: ${_messageController.text}');
      print(
          'TglKeluhan: ${DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String()}');
      print('Status: Terkirim');
      print('Subject: ${_subjectController.text}');
      print('Section: $_sectionName');

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
      request.fields['NamaSection'] = _sectionName!;

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint submitted successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to submit complaint: ${response.statusCode} - ${responseBody.body}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting complaint: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _sectionController.dispose();
    _messageController.removeListener(_updateLinesAndWords);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final double paddingValue = screenWidth * 0.05; // 5% of screen width
        final double baseFontSize = screenWidth * 0.04; // 4% of screen width
        final double cardElevation = screenWidth * 0.01; // Dynamic elevation

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(
              "HR Care",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: baseFontSize * 1.2, // 20 on 500px screen
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
                  SizedBox(height: paddingValue),
                  Card(
                    elevation: cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: paddingValue * 0.8,
                        horizontal: paddingValue,
                      ),
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
                          fontSize: baseFontSize * 1.3, // 22 on 500px screen
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: paddingValue),
                  Card(
                    elevation: cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(paddingValue * 0.8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: baseFontSize * 0.9,
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
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          TextField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: baseFontSize * 0.9,
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
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: baseFontSize * 0.9,
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
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          TextField(
                            controller: _sectionController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Section',
                              labelStyle: GoogleFonts.poppins(
                                fontSize: baseFontSize * 0.9,
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
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          Text(
                            'Message',
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.3),
                          TextField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Type your message here...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: baseFontSize * 0.8,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.8,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.3),
                          Text(
                            'Lines: $_lines | Words: $_words | Saved',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: baseFontSize * 0.7,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: paddingValue),
                  Card(
                    elevation: cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(paddingValue * 0.8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachment',
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _chooseFile,
                                icon: const Icon(Icons.upload_file, size: 20),
                                label: Text(
                                  'Choose File',
                                  style: GoogleFonts.poppins(
                                    fontSize: baseFontSize * 0.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: paddingValue * 0.8,
                                    vertical: paddingValue * 0.6,
                                  ),
                                  elevation: 2,
                                ),
                              ),
                              SizedBox(width: paddingValue * 0.5),
                              Expanded(
                                child: Text(
                                  _selectedFiles.isEmpty
                                      ? 'No file chosen'
                                      : '${_selectedFiles.length} file(s) selected',
                                  style: GoogleFonts.poppins(
                                    fontSize: baseFontSize * 0.8,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          if (_selectedFiles.isNotEmpty)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: screenHeight * 0.2, // Limit height
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _selectedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = _selectedFiles[index];
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: paddingValue * 0.2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            file.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: baseFontSize * 0.8,
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
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: paddingValue * 0.5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _addMoreFiles,
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(
                                'Add More',
                                style: GoogleFonts.poppins(
                                  fontSize: baseFontSize * 0.8,
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: paddingValue * 0.6,
                                  vertical: paddingValue * 0.4,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.3),
                          Text(
                            'Allowed extensions: jpg, gif, jpeg, png, txt, pdf (Max: 10MB)',
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.7,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: paddingValue),
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
                            padding: EdgeInsets.symmetric(
                              vertical: paddingValue * 0.8,
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'SUBMIT',
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: paddingValue * 0.5),
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
                            padding: EdgeInsets.symmetric(
                              vertical: paddingValue * 0.8,
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: paddingValue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
