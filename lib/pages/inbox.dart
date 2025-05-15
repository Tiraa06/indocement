import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int? _employeeId;
  int _selectedTabIndex = 0; // 0 for Keluhan, 1 for Konsultasi
  bool _hasUnreadNotifications = false;

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
      _loadLocalNotifications(); // Muat notifikasi lokal
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee ID not found. Please log in again.')),
        );
      }
    }
  }

  Future<void> _fetchComplaints() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.100.140:5555/api/keluhans?employeeId=$_employeeId'),
      );
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');

        if (mounted) {
          setState(() {
            _complaints =
                (data as List).cast<Map<String, dynamic>>().where((complaint) {
              final matches =
                  complaint['IdEmployee']?.toString() == _employeeId.toString();
              print('Complaint: $complaint, Matches: $matches');
              return matches;
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load complaints: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching complaints: $e')),
        );
      }
    }
  }

  Future<void> _loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString('roomId');
    if (roomId != null) {
      final messagesJson = prefs.getString('messages_$roomId') ?? '[]';
      final messages = jsonDecode(messagesJson) as List;
      if (mounted) {
        setState(() {
          _notifications = (messages)
              .cast<Map<String, dynamic>>()
              .where((msg) =>
                  msg['SenderId'] != _employeeId && msg['Status'] != 'Dibaca')
              .map((msg) => {
                    'id': msg['Id'],
                    'message': msg['Message'],
                    'senderId': msg['SenderId'],
                    'createdAt': msg['CreatedAt'],
                    'roomId': msg['roomId'],
                    'isRead': msg['Status'] != 'Dibaca',
                  })
              .toList();
          _hasUnreadNotifications = _notifications.isNotEmpty;
        });
      }
    }
  }

  Future<void> _clearLocalNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString('roomId');
    if (roomId != null) {
      final messagesJson = prefs.getString('messages_$roomId') ?? '[]';
      final messages = jsonDecode(messagesJson) as List;
      final updatedMessages = messages
          .cast<Map<String, dynamic>>()
          .map((msg) =>
              msg['Id'] == notificationId ? {...msg, 'Status': 'Dibaca'} : msg)
          .toList();
      await prefs.setString('messages_$roomId', jsonEncode(updatedMessages));
      if (mounted) {
        setState(() {
          _notifications.removeWhere((notif) => notif['id'] == notificationId);
          _hasUnreadNotifications = _notifications.isNotEmpty;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingValue = screenWidth < 400 ? 16.0 : 20.0;
    final double fontSizeLabel = screenWidth < 400 ? 14.0 : 16.0;
    final double imageSize = (screenWidth * 0.2).clamp(100, 150);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "Inbox",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            if (_hasUnreadNotifications)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '!',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
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
      body: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(paddingValue * 0.5),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 0
                              ? const Color(0xFF1E88E5)
                              : Colors.grey[200],
                          foregroundColor: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: paddingValue * 0.6,
                          ),
                          elevation: _selectedTabIndex == 0 ? 2 : 0,
                        ),
                        child: Text(
                          'Keluhan',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeLabel * 0.9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: paddingValue * 0.5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 1
                              ? const Color(0xFF1E88E5)
                              : Colors.grey[200],
                          foregroundColor: _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: paddingValue * 0.6,
                          ),
                          elevation: _selectedTabIndex == 1 ? 2 : 0,
                        ),
                        child: Text(
                          'Konsultasi',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeLabel * 0.9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: paddingValue),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTabIndex == 0
                      ? _complaints.isEmpty
                          ? Center(
                              child: Text(
                                "No complaints found.",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSizeLabel,
                                  color: Colors.black87,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _complaints.length,
                              itemBuilder: (context, index) {
                                final complaint = _complaints[index];
                                final tglKeluhan = complaint['TglKeluhan'] !=
                                        null
                                    ? DateTime.parse(complaint['TglKeluhan'])
                                        .toLocal()
                                        .toString()
                                        .split('.')[0]
                                    : 'Unknown Date';

                                final keluhan =
                                    complaint['Keluhan']?.toString() ??
                                        complaint['Keluhan1']?.toString() ??
                                        complaint['Message']?.toString() ??
                                        complaint['Description']?.toString() ??
                                        'No message available';

                                final urlFotoKeluhan =
                                    complaint['UrlFotoKeluhan']?.toString() ??
                                        complaint['PhotoUrl']?.toString();

                                final baseUrl = 'http://192.168.100.140:5555';
                                final imageUrl = urlFotoKeluhan != null &&
                                        urlFotoKeluhan.isNotEmpty
                                    ? (urlFotoKeluhan.startsWith('http')
                                        ? urlFotoKeluhan
                                        : '$baseUrl$urlFotoKeluhan')
                                    : null;

                                final isImage = imageUrl != null &&
                                    (imageUrl.endsWith('.jpg') ||
                                        imageUrl.endsWith('.jpeg') ||
                                        imageUrl.endsWith('.png') ||
                                        imageUrl.endsWith('.gif'));

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Nomor Tiket: ${complaint['Id']}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSizeLabel,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Message: $keluhan",
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSizeLabel - 2,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Status: ${complaint['Status'] ?? 'Unknown'}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSizeLabel - 2,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Date: $tglKeluhan",
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSizeLabel - 2,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        isImage
                                            ? Image.network(
                                                imageUrl,
                                                width: imageSize,
                                                height: imageSize,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  print(
                                                      'Error loading image: $error');
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
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          fontSizeLabel - 2,
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
                            )
                      : _notifications.isEmpty
                          ? Center(
                              child: Text(
                                "No notifications available.",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSizeLabel,
                                  color: Colors.black87,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                final isRead = notif['isRead'] ?? true;
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: !isRead ? Colors.red[50] : null,
                                  child: ListTile(
                                    leading: !isRead
                                        ? const Icon(Icons.circle,
                                            color: Colors.red, size: 12)
                                        : null,
                                    title: Text(
                                      notif['message'] ?? 'New message',
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeLabel,
                                        fontWeight: !isRead
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      notif['createdAt'] != null
                                          ? DateTime.parse(notif['createdAt'])
                                              .toLocal()
                                              .toString()
                                              .split('.')[0]
                                          : 'Unknown time',
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeLabel - 2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onTap: () {
                                      _clearLocalNotification(notif['id']);
                                      Navigator.pushNamed(context, '/chat');
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
