import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = prefs.getInt('idEmployee');
    });
    if (_employeeId != null) {
      _fetchComplaints();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Employee ID not found. Please log in again.')),
      );
    }
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://213.35.123.110:5555/api/keluhans?employeeId=$_employeeId'),
      );

      print('Fetch Complaints Status: ${response.statusCode}');
      print('Fetch Complaints Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Complaints Data: $data');
        setState(() {
          _complaints = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load complaints: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching complaints: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingValue = screenWidth < 400 ? 16.0 : 20.0;
    final double fontSizeLabel = screenWidth < 400 ? 14.0 : 16.0;
    // Ukuran gambar responsif: 20% dari lebar layar, maksimum 150 piksel
    final double imageSize = (screenWidth * 0.2).clamp(100, 150);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _complaints.isEmpty
                ? Center(
                    child: Text(
                      "No complaints found.",
                      style: GoogleFonts.roboto(
                        fontSize: fontSizeLabel,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final tglKeluhan = DateTime.parse(complaint['TglKeluhan'])
                          .toLocal()
                          .toString()
                          .split('.')[0];

                      final keluhan =
                          complaint['Keluhan1'] ?? 'No message available';
                      final urlFotoKeluhan = complaint['UrlFotoKeluhan'];

                      // Tambahkan base URL jika URL tidak lengkap
                      final baseUrl = 'http://213.35.123.110:5555';
                      final imageUrl =
                          urlFotoKeluhan != null && urlFotoKeluhan.isNotEmpty
                              ? (urlFotoKeluhan.startsWith('http')
                                  ? urlFotoKeluhan
                                  : '$baseUrl$urlFotoKeluhan')
                              : null;

                      // Filter hanya format gambar
                      final isImage = imageUrl != null &&
                          (imageUrl.endsWith('.jpg') ||
                              imageUrl.endsWith('.jpeg') ||
                              imageUrl.endsWith('.png') ||
                              imageUrl.endsWith('.gif'));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bagian kiri: Teks informasi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Nomor Tiket: ${complaint['Id']}",
                                      style: GoogleFonts.roboto(
                                        fontSize: fontSizeLabel,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Message: $keluhan",
                                      style: GoogleFonts.roboto(
                                        fontSize: fontSizeLabel - 2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Status: ${complaint['Status']}",
                                      style: GoogleFonts.roboto(
                                        fontSize: fontSizeLabel - 2,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Date: $tglKeluhan",
                                      style: GoogleFonts.roboto(
                                        fontSize: fontSizeLabel - 2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bagian kanan: Gambar
                              isImage
                                  ? Image.network(
                                      imageUrl!,
                                      width: imageSize,
                                      height: imageSize,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return Container(
                                          width: imageSize,
                                          height: imageSize,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: imageSize,
                                      height: imageSize,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Text(
                                          'No image',
                                          style: GoogleFonts.roboto(
                                            fontSize: fontSizeLabel - 2,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
