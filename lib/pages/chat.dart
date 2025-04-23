import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWithHRPage extends StatefulWidget {
  const ChatWithHRPage({super.key});

  @override
  State<ChatWithHRPage> createState() => _ChatWithHRPageState();
}

class _ChatWithHRPageState extends State<ChatWithHRPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _employeeId;
  String? _roomId;
  String? _konsultasiId;
  bool _isLoading = true;
  Timer? _pollingTimer;
  String _sectionHeadName = "Unknown";
  String _sectionHeadDepartment = "Unknown";
  int? _sectionHeadId;
  Map<String, dynamic>?
      _employeeData; // Menyimpan data karyawan dari SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = prefs.getInt('idEmployee');
      // Ambil data karyawan dari SharedPreferences
      _employeeData = {
        'Id': _employeeId,
        'Name': prefs.getString('employeeName') ?? 'Unknown',
        'Email': prefs.getString('email') ?? 'unknown@example.com',
        'Telepon': prefs.getString('telepon') ?? '0000000000',
        'EmployeeNo': prefs.getString('employeeNo') ?? 'EMP000',
        'LivingArea': prefs.getString('livingArea') ?? 'Unknown',
        'EmployeeName': prefs.getString('employeeName') ?? 'Unknown',
      };
    });

    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ID Karyawan tidak ditemukan. Silakan login kembali.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _createConsultation();
  }

  Future<void> _createConsultation() async {
    if (_employeeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data karyawan tidak tersedia.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final requestBody = {
        'IdEmployee': _employeeId,
        'IdEmployeeNavigation': {
          'Id': _employeeData!['Id'],
          'Name': _employeeData!['Name'],
          'Email': _employeeData!['Email'],
          'Telepon': _employeeData!['Telepon'],
          'EmployeeNo': _employeeData!['EmployeeNo'],
          'LivingArea': _employeeData!['LivingArea'],
          'EmployeeName': _employeeData!['EmployeeName'],
        },
      };

      print('Create Consultation Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://213.35.123.110:5555/api/Konsultasis'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Create Consultation Status: ${response.statusCode}');
      print('Create Consultation Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _konsultasiId = data['Id']
              .toString(); // Sesuaikan dengan field 'Id' dari response
          _roomId = data['ChatRoom']['Id']
              .toString(); // Ambil ID chat room dari response
        });

        // Fetch chat room details to get Section Head info
        await _fetchChatRoomDetails();

        // Fetch initial messages
        await _fetchMessages();

        // Start polling for new messages every 5 seconds
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _fetchMessages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal membuat konsultasi: ${response.statusCode} - ${response.body}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error membuat konsultasi: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChatRoomDetails() async {
    if (_roomId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://213.35.123.110:5555/api/ChatRooms/$_roomId'),
        headers: {'accept': 'application/json'},
      );

      print('Fetch Chat Room Status: ${response.statusCode}');
      print('Fetch Chat Room Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomName =
            data['Name'] as String; // Sesuaikan dengan field 'Name'
        final parts = roomName.split('-');
        if (parts.length == 3) {
          _sectionHeadId = int.tryParse(parts[2]);
        }

        if (_sectionHeadId != null) {
          await _fetchSectionHead();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menentukan ID Section Head.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal mengambil detail chat room: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil detail chat room: $e')),
      );
    }
  }

  Future<void> _fetchSectionHead() async {
    if (_sectionHeadId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://213.35.123.110:5555/api/Employees/$_sectionHeadId'),
      );

      print('Fetch Section Head Status: ${response.statusCode}');
      print('Fetch Section Head Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sectionHeadName = data['employeeName'] ?? 'Unknown';
          _sectionHeadDepartment = data['NamaDepartement'] ?? 'Unknown';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal mengambil data Section Head: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil data Section Head: $e')),
      );
    }
  }

  Future<void> _fetchMessages() async {
    if (_roomId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://213.35.123.110:5555/api/ChatMessages/room/$_roomId'),
        headers: {'accept': 'application/json'},
      );

      print('Fetch Messages Status: ${response.statusCode}');
      print('Fetch Messages Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data
              .map((msg) => {
                    'sender':
                        msg['senderId'].toString() == _employeeId.toString()
                            ? 'user'
                            : 'hr',
                    'text': msg['message'],
                    'timestamp': msg['createdAt'],
                  })
              .toList();
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 60,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengambil pesan: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil pesan: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://213.35.123.110:5555/api/ChatMessages/send-message'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'roomId': _roomId,
          'senderId': _employeeId,
          'message': text,
        }),
      );

      print('Send Message Status: ${response.statusCode}');
      print('Send Message Body: ${response.body}');

      if (response.statusCode == 201) {
        _messageController.clear();
        await _fetchMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengirim pesan: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengirim pesan: $e')),
      );
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final timestamp = DateTime.parse(message['timestamp']).toLocal();
    final formattedTime = DateFormat('HH:mm').format(timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1572E8) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'],
              style: GoogleFonts.roboto(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: GoogleFonts.roboto(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile_hr.jpg'),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectionHeadName,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _sectionHeadDepartment,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Online",
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/chat_background.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              "Belum ada pesan.",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessage(_messages[index]);
                            },
                          ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Ketik pesan...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        style: GoogleFonts.roboto(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFF1572E8),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
