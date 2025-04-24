import 'dart:convert';
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Added for scroll control
  List<dynamic> _messages = [];
  Map<String, dynamic>? opponent;
  String? roomId;
  String? konsultasiId;
  int? idEmployee;
  Timer? _pollingTimer; // Added for polling

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
    // Start polling every 5 seconds to check for updates
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadChatRoom(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel the timer to avoid memory leaks
    _scrollController.dispose(); // Dispose the scroll controller
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRoom({bool isPolling = false}) async {
    final prefs = await SharedPreferences.getInstance();
    idEmployee = prefs.getInt('idEmployee');
    roomId = prefs.getString('roomId');
    konsultasiId = prefs.getString('konsultasiId');

    if (idEmployee == null) return;

    // Check for existing consultation if roomId or konsultasiId is missing
    if (roomId == null || konsultasiId == null) {
      final existingConsultation =
          await _checkExistingConsultation(idEmployee!);
      if (existingConsultation != null) {
        setState(() {
          roomId = existingConsultation['ChatRoomId']?.toString();
          konsultasiId = existingConsultation['KonsultasiId']?.toString();
        });
        if (roomId != null && konsultasiId != null) {
          await prefs.setString('roomId', roomId!);
          await prefs.setString('konsultasiId', konsultasiId!);
        }
      }
    }

    if (roomId != null) {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessages = data['Messages'] ?? [];
        final newOpponent = data['Opponent'];

        // Only update state if messages or opponent have changed to avoid unnecessary rebuilds
        if (_messages.toString() != newMessages.toString() ||
            opponent.toString() != newOpponent.toString()) {
          double? previousOffset;
          if (isPolling && _scrollController.hasClients) {
            previousOffset =
                _scrollController.offset; // Save scroll position during polling
          }

          setState(() {
            _messages = newMessages;
            opponent = newOpponent;
          });

          // Restore scroll position after update
          if (isPolling &&
              previousOffset != null &&
              _scrollController.hasClients) {
            _scrollController.jumpTo(previousOffset);
          } else {
            // Scroll to bottom for initial load or after sending a message
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
          }

          // Update message status for unread messages from the opponent
          for (var msg in _messages) {
            if (msg['SenderId'] != idEmployee && msg['Status'] != 'Dibaca') {
              await _updateMessageStatus(msg['Id'], 'Dibaca');
            }
          }
        }
      } else {
        print("Room tidak ditemukan, mencoba membuat baru.");
        await _createKonsultasi(idEmployee!);
        await _loadChatRoom();
      }
    } else {
      await _createKonsultasi(idEmployee!);
      await _loadChatRoom();
    }
  }

  Future<Map<String, dynamic>?> _checkExistingConsultation(
      int idEmployee) async {
    try {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/Konsultasis/employee/$idEmployee');
      final response = await http.get(url);

      print("Response from GET /api/Konsultasis/employee/$idEmployee: "
          "Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          print("Found consultation: ${data[0]}");
          return data[0]; // Return the most recent consultation
        } else if (data is Map<String, dynamic> && data.isNotEmpty) {
          print("Found consultation: $data");
          return data; // Return the single consultation
        } else {
          print("Tidak ada konsultasi ditemukan untuk idEmployee: $idEmployee");
        }
      } else {
        print("Failed to fetch consultation for idEmployee: $idEmployee, "
            "Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print(
          "Error saat memeriksa konsultasi untuk idEmployee: $idEmployee: $e");
    }
    return null; // No existing consultation found
  }

  Future<void> _createKonsultasi(int idEmployee) async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(
        'http://213.35.123.110:5555/api/Konsultasis/create-consultation');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idEmployee': idEmployee}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      konsultasiId = data['KonsultasiId']?.toString();
      roomId = data['ChatRoomId']?.toString();
      if (roomId != null && konsultasiId != null) {
        await prefs.setString('roomId', roomId!);
        await prefs.setString('konsultasiId', konsultasiId!);
      }
    } else {
      final error = jsonDecode(response.body);
      if (error['Message'] == "Room chat sudah ada.") {
        // Handle case where room already exists
        roomId = error['ChatRoomId']?.toString();
        if (roomId != null) {
          await prefs.setString('roomId', roomId!);
          // Optionally fetch konsultasiId from existing consultation
          final existingConsultation =
              await _checkExistingConsultation(idEmployee);
          if (existingConsultation != null) {
            konsultasiId = existingConsultation['KonsultasiId']?.toString();
            if (konsultasiId != null) {
              await prefs.setString('konsultasiId', konsultasiId!);
            }
          }
        }
      } else {
        print("Gagal membuat konsultasi: ${response.body}");
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || idEmployee == null) return;

    final url =
        Uri.parse('http://213.35.123.110:5555/api/ChatMessages/send-message');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomId': roomId,
        'senderId': idEmployee,
        'message': _messageController.text
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _messageController.clear();
      await _loadChatRoom(); // Refresh messages after sending
    } else {
      final error = jsonDecode(response.body);
      if (error['Message'] == "Chat room tidak ditemukan.") {
        await _createKonsultasi(idEmployee!);
        await _sendMessage();
      } else {
        print("Gagal mengirim pesan: ${response.body}");
      }
    }
  }

  Future<void> _updateMessageStatus(int messageId, String status) async {
    final url = Uri.parse(
        'http://213.35.123.110:5555/api/ChatMessages/update-status/$messageId');
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      print(
          "Warning: timeString is null or empty, using current time as fallback");
      final now = DateTime.now();
      return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
    try {
      final dt = DateTime.parse(timeString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print(
          "Error parsing timeString '$timeString': $e, using current time as fallback");
      final now = DateTime.now();
      return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1572E8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent != null ? opponent!['Name'] ?? 'N/A' : 'Loading...',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  opponent != null ? opponent!['NamaDepartement'] ?? 'N/A' : '',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/chat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Attach scroll controller
                padding: EdgeInsets.symmetric(vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  if (msg == null) return SizedBox();
                  final isMe = msg['SenderId'] == idEmployee;
                  final message = msg['Message'] ?? '[Pesan kosong]';
                  final sender = msg['Sender'];
                  final senderName = sender?['EmployeeName'] ?? '';
                  final createdAt = msg['CreatedAt'];
                  final status = msg['Status'] ?? 'Terkirim';

                  print(
                      "Message $index: createdAt = $createdAt, formatted time = ${_formatTime(createdAt)}");

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: EdgeInsets.only(
                              left: isMe ? 50 : 8,
                              right: isMe ? 8 : 50,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Color(0xFFE1FFC7) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: isMe
                                    ? Radius.circular(12)
                                    : Radius.circular(0),
                                bottomRight: isMe
                                    ? Radius.circular(0)
                                    : Radius.circular(12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (!isMe) SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 6),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      _formatTime(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (isMe)
                                      Icon(
                                        status == 'Dibaca'
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 14,
                                        color: status == 'Dibaca'
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1572E8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
