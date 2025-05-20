import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'chat.dart'; // Import ChatPage

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _bpjsData = [];
  bool _isLoading = true;
  int? _employeeId;
  int _selectedTabIndex = 0;
  bool _hasUnreadNotifications = false;
  Timer? _pollingTimer;
  List<String> _roomIds = [];
  Map<String, Map<String, dynamic>> _roomOpponentCache = {};

  @override
  void initState() {
    super.initState();
    _clearLocalData();
    _loadEmployeeId();
    _startPolling();
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString('roomId');
    if (roomId != null) {
      await prefs.remove('messages_$roomId');
      print('Cleared local messages for roomId: $roomId');
    }
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = prefs.getInt('idEmployee');
      _isLoading = true;
    });
    print('Employee ID loaded: $_employeeId');
    if (_employeeId != null) {
      await _fetchRooms();
      await _fetchComplaints();
      await _fetchBpjsData();
      await _fetchMessages();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee ID not found. Please log in again.')),
        );
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_employeeId != null && mounted) {
        print('Polling for messages... Room IDs: $_roomIds');
        await _fetchMessages();
      } else {
        print('Skipping poll: employeeId=$_employeeId, mounted=$mounted');
      }
    });
  }

  Future<void> _fetchRooms() async {
    if (_employeeId == null || !mounted) return;
    try {
      final url = Uri.parse('http://192.168.100.140:5555/api/ChatRooms');
      final response = await http.get(url);
      print('Fetch all rooms - Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> rooms = [];
        if (data is List) {
          rooms = data.cast<Map<String, dynamic>>();
        }
        final myEmployeeId = _employeeId.toString();
        final myRooms = rooms.where((room) {
          final konsultasi = room['Konsultasi'];
          return konsultasi != null &&
            (konsultasi['IdEmployee']?.toString() == myEmployeeId ||
             konsultasi['IdKaryawan']?.toString() == myEmployeeId);
        }).toList();
        setState(() {
          _roomIds = myRooms
              .map((room) => room['Id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          print('Filtered roomIds for employeeId $_employeeId: $_roomIds');
        });
      }
    } catch (e) {
      print('Error fetching all rooms: $e');
    }
  }

  Future<void> _fetchRoomFallback() async {
    try {
      final url = Uri.parse('http://192.168.100.140:5555/api/ChatRooms/62');
      final response = await http.get(url);
      print(
          'Fetch room fallback (roomId: 62) - Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['Id'] != null) {
          setState(() {
            _roomIds = [data['Id'].toString()];
            print('Fallback successful, roomIds: $_roomIds');
          });
        } else {
          print('Fallback failed: Invalid response format for roomId 62');
        }
      } else {
        print('Fallback failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error in fetchRoomFallback: $e');
    }
  }

  Future<void> _fetchMessages() async {
    if (_employeeId == null || _roomIds.isEmpty || !mounted) {
      print(
          'Cannot fetch messages: employeeId=$_employeeId, roomIds=$_roomIds');
      return;
    }
    try {
      List<Map<String, dynamic>> allMessages = [];
      for (String roomId in _roomIds) {
        final url = Uri.parse(
            'http://192.168.100.140:5555/api/ChatMessages/room/$roomId?currentUserId=$_employeeId');
        final response = await http.get(url);
        print(
            'Fetch messages for room $roomId - Status: ${response.statusCode}, Body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['Messages'] is List) {
            allMessages.addAll(data['Messages'].cast<Map<String, dynamic>>());
            if (data['Opponent'] != null) {
              _roomOpponentCache[roomId] =
                  data['Opponent'] as Map<String, dynamic>;
              print('Opponent cached for room $roomId: ${data['Opponent']}');
            } else {
              print('No Opponent data for room $roomId');
            }
          } else {
            print(
                'Unexpected messages response format for room $roomId: $data');
          }
        } else {
          print(
              'Failed to fetch messages for room $roomId: ${response.statusCode} ${response.body}');
        }
      }

      print('All messages from server: $allMessages');
      if (mounted) {
        setState(() {
          _notifications = allMessages.where((msg) {
            final status = msg['Status']?.toString() ?? '';
            final senderId = msg['SenderId']?.toString() ?? '';
            final roomId = msg['RoomId']?.toString() ?? '';
            final isFromHR = senderId != _employeeId.toString();
            final isUnread = status == 'Terkirim';
            final isMyRoom = _roomIds.contains(roomId);
            return isFromHR && isUnread && isMyRoom;
          }).map((msg) {
            final roomId = msg['RoomId']?.toString() ?? '';
            final senderName = msg['Sender']?['EmployeeName']?.toString() ?? 'HR Tidak Diketahui';
            return {
              'id': msg['Id']?.toString() ?? '',
              'message': msg['Message']?.toString() ?? 'No message',
              'senderName': senderName,
              'senderId': msg['SenderId']?.toString() ?? '',
              'createdAt': msg['CreatedAt']?.toString() ?? '',
              'roomId': roomId,
              'isRead': false,
            };
          }).toList();
          _hasUnreadNotifications = _notifications.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      print(
          'Fetch complaints - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _complaints =
                (data as List).cast<Map<String, dynamic>>().where((complaint) {
              final matches =
                  complaint['IdEmployee']?.toString() == _employeeId.toString();
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

  Future<void> _fetchBpjsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.100.140:5555/api/bpjs?employeeId=$_employeeId'),
      );
      print(
          'Fetch BPJS - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _bpjsData =
                (data as List).cast<Map<String, dynamic>>().where((bpjs) {
              final matches =
                  bpjs['IdEmployee']?.toString() == _employeeId.toString();
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
                    Text('Failed to load BPJS data: ${response.statusCode}')),
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
          SnackBar(content: Text('Error fetching BPJS data: $e')),
        );
      }
    }
  }

  Future<void> _updateServerStatus(String messageId, String status) async {
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/update-status/$messageId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      print(
          'Update server status - Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200) {
        print('Failed to update server status: ${response.body}');
      }
    } catch (e) {
      print('Error updating server status: $e');
    }
  }

  Future<void> _navigateToChat(String roomId, String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roomId', roomId);
    // Update status to "Dibaca" before navigating, to align with chat.dart behavior
    await _updateServerStatus(notificationId, 'Dibaca');
    if (mounted) {
      setState(() {
        _notifications.removeWhere((notif) => notif['id'] == notificationId);
        _hasUnreadNotifications = _notifications.isNotEmpty;
      });
      // Navigate to ChatPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatPage()),
      ).then((_) async {
        // Refresh notifications after returning from ChatPage
        await _fetchMessages();
      });
    }
  }

  String _formatTimestamp(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'Unknown Date';
    }
    try {
      final formatter = DateFormat('dd MMMM yyyy HH.mm', 'id_ID');
      final dateTime = formatter.parseLoose(timeString);
      return DateFormat('dd MMMM yyyy HH.mm', 'id_ID').format(dateTime);
    } catch (e) {
      print('Error parsing timestamp: $timeString, Error: $e');
      return timeString;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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
                child: Text(
                  _notifications.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                            _notifications = _notifications.map((notif) {
                              return {...notif, 'isRead': true};
                            }).toList();
                            _hasUnreadNotifications = false;
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Konsultasi',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel * 0.9,
                                fontWeight: FontWeight.w500,
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
                                child: Text(
                                  _notifications.length.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: paddingValue * 0.5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 2;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 2
                              ? const Color(0xFF1E88E5)
                              : Colors.grey[200],
                          foregroundColor: _selectedTabIndex == 2
                              ? Colors.white
                              : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: paddingValue * 0.6,
                          ),
                          elevation: _selectedTabIndex == 2 ? 2 : 0,
                        ),
                        child: Text(
                          'BPJS',
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
                      : _selectedTabIndex == 1
                          ? _notifications.isEmpty
                              ? Center(
                                  child: Text(
                                    "No unread consultations from HR.",
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
                                    final timestamp =
                                        _formatTimestamp(notif['createdAt']);
                                    return GestureDetector(
                                      onTap: () {
                                        _navigateToChat(
                                            notif['roomId'], notif['id']);
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        color: !isRead ? Colors.red[50] : null,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Pesan dari ${notif['senderName']}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: fontSizeLabel,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      "Message: ${notif['message']}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize:
                                                            fontSizeLabel - 2,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      "Status: Belum Dibaca",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize:
                                                            fontSizeLabel - 2,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      "Date: $timestamp",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize:
                                                            fontSizeLabel - 2,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                          : _bpjsData.isEmpty
                              ? Center(
                                  child: Text(
                                    "No BPJS data found.",
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSizeLabel,
                                      color: Colors.black87,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _bpjsData.length,
                                  itemBuilder: (context, index) {
                                    final bpjs = _bpjsData[index];
                                    final timestamp = bpjs['CreatedAt'] != null
                                        ? _formatTimestamp(bpjs['CreatedAt'])
                                        : 'Unknown Date';
                                    final description =
                                        bpjs['Description']?.toString() ??
                                            'No description';
                                    final status =
                                        bpjs['Status']?.toString() ?? 'Unknown';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Nomor BPJS: ${bpjs['NoBpjs'] ?? 'N/A'}",
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSizeLabel,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Description: $description",
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSizeLabel - 2,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Status: $status",
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSizeLabel - 2,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Date: $timestamp",
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSizeLabel - 2,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
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
