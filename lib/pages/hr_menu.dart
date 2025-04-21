import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

class HRCareMenuPage extends StatefulWidget {
  const HRCareMenuPage({super.key});

  @override
  State<HRCareMenuPage> createState() => _HRCareMenuPageState();
}

class _HRCareMenuPageState extends State<HRCareMenuPage> {
  // Controllers untuk TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // State untuk dropdown
  String _department = 'Technical Support';
  String _relatedService = 'None';
  String _priority = 'Medium';

  // State untuk file yang dipilih
  List<XFile> _selectedFiles = [];

  // State untuk menghitung lines dan words
  int _lines = 0;
  int _words = 0;

  // State untuk waktu
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    // Listener untuk menghitung lines dan words
    _messageController.addListener(_updateLinesAndWords);
    // Update waktu setiap detik
    _updateTime();
  }

  void _updateLinesAndWords() {
    final text = _messageController.text;
    setState(() {
      // Hitung jumlah baris
      _lines = text.isEmpty ? 0 : text.split('\n').length;
      // Hitung jumlah karakter (termasuk spasi dan karakter khusus)
      _words = text.length;
    });
  }

  void _updateTime() {
    // Format tanggal dan waktu WIB (UTC+7)
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formatter = DateFormat('dd MMMM yyyy, HH:mm:ss');
    setState(() {
      _currentTime = formatter.format(now);
    });
    // Update setiap detik
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  // Fungsi untuk memilih file
  Future<void> _chooseFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['jpg', 'gif', 'jpeg', 'png', 'txt', 'pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        // Validasi ukuran file (max 10MB)
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB dalam bytes
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

  // Fungsi untuk menambahkan lebih banyak file
  Future<void> _addMoreFiles() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['jpg', 'gif', 'jpeg', 'png', 'txt', 'pdf'],
      );
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);

      if (files.isNotEmpty) {
        // Validasi ukuran file
        const maxSize = 10 * 1024 * 1024; // 10MB dalam bytes
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
              // Banner
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/banner_hr.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              // Teks di bawah banner
              Text(
                "Selamat datang di HR Care 👋\nSilakan mengisi form dan pilih layanan yang Anda butuhkan.",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              // Tanggal dan Waktu
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
                    const Icon(Icons.access_time, color: Colors.black54, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentTime.isEmpty ? 'Loading...' : 'WIB: $_currentTime',
                      style: GoogleFonts.roboto(
                      fontSize: fontSizeLabel,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                )
              ),
              const SizedBox(height: 20),
              // Open Ticket Title dengan dekorasi
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1572E8), Color(0xFF3B94F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
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
                  "Form Pengaduan",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              // Email Address Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Subject Field
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              // Dropdowns
              Column(
                children: [
                  // Department Dropdown
                  DropdownButtonFormField<String>(
                    value: _department,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: ['Technical Support']
                        .map((dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(
                                dept,
                                style:
                                    GoogleFonts.roboto(fontSize: fontSizeLabel),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _department = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Related Service Dropdown
                  DropdownButtonFormField<String>(
                    value: _relatedService,
                    decoration: InputDecoration(
                      labelText: 'Related Service',
                      labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: ['None', 'Konsultasi', 'Keluhan']
                        .map((service) => DropdownMenuItem(
                              value: service,
                              child: Text(
                                service,
                                style:
                                    GoogleFonts.roboto(fontSize: fontSizeLabel),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _relatedService = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      labelStyle: GoogleFonts.roboto(fontSize: fontSizeLabel),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: ['Low', 'Medium', 'High']
                        .map((priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(
                                priority,
                                style:
                                    GoogleFonts.roboto(fontSize: fontSizeLabel),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.roboto(
                      fontSize: fontSizeLabel,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LINES: $_lines - Words: $_words - saved',
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: fontSizeLabel - 2,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Attachment Section
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
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            fontSize: fontSizeLabel - 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _addMoreFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                      fontSize: fontSizeLabel - 2,
                      color: Colors.grey,
                    ),
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
              // Submit dan Cancel Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1572E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'SUBMIT',
                        style: GoogleFonts.roboto(
                          fontSize: fontSizeLabel,
                          color: Colors.white,
                        ),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          fontSize: fontSizeLabel,
                          color: Colors.black,
                        ),
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