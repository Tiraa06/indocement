import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:dio/dio.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Map<String, dynamic>? opponent;
  String? roomId;
  String? konsultasiId;
  int? idEmployee;
  late HubConnection _hubConnection;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initializeSignalR();
    _loadChatRoom();
  }

  void _initializeSignalR() {
    print("Initializing SignalR connection...");
    _hubConnection = HubConnectionBuilder()
        .withUrl("http://213.35.123.110:5555/chatHub")
        .build();

    // Event untuk menerima pesan baru
    _hubConnection.on("ReceiveMessage", (message) {
      print("Received message via SignalR: $message");
      if (message is List && message.isNotEmpty && message[0]['roomId'] == roomId) {
        setState(() {
          _messages.add(message[0]);
        });
        _scrollToBottom();
      }
    });

    // Event untuk memperbarui status pesan
    _hubConnection.on("UpdateMessageStatus", (statusUpdate) {
      print("Received status update via SignalR: $statusUpdate");
      final messageId = (statusUpdate as List<Map<String, dynamic>>)[0]['id'];
      final newStatus = (statusUpdate as List<Map<String, dynamic>>)[0]['status'];
      if (messageId != null && newStatus != null) {
        _updateMessageStatusInUI(messageId, newStatus);
      }
    });

    // Log saat koneksi berhasil

    // Mulai koneksi SignalR
    _hubConnection.start()?.then((_) {
      print("SignalR connection established successfully.");
    }).catchError((err) {
      print("SignalR connection error: $err");
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _hubConnection.stop();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    print("Loading chat room...");
    final prefs = await SharedPreferences.getInstance();
    idEmployee = prefs.getInt('idEmployee');
    roomId = prefs.getString('roomId');
    konsultasiId = prefs.getString('konsultasiId');

    print("Loaded preferences: idEmployee=$idEmployee, roomId=$roomId, konsultasiId=$konsultasiId");

    if (idEmployee == null) {
      print("idEmployee is null, aborting chat room load.");
      return;
    }

    if (roomId == null || konsultasiId == null) {
      print("Room ID or Konsultasi ID is null, creating new consultation...");
      await _createKonsultasi(idEmployee!);
    }

    if (roomId != null) {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      print("Fetching messages from: $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Messages fetched successfully: $data");
        setState(() {
          _messages = data['Messages'] ?? [];
          opponent = data['Opponent'];
        });
        _scrollToBottom();
      } else {
        print("Failed to fetch messages, status code: ${response.statusCode}");
        await _createKonsultasi(idEmployee!);
        await _loadChatRoom();
      }
    }
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
      print("Gagal membuat konsultasi: ${response.body}");
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || idEmployee == null) {
      print("Message is empty or idEmployee is null, aborting send.");
      return;
    }

    final messageText = _messageController.text.trim();
    final tempMessage = {
      'Id': DateTime.now().millisecondsSinceEpoch, // Temporary unique ID
      'SenderId': idEmployee,
      'Message': messageText,
      'CreatedAt': DateTime.now().toIso8601String(),
      'Status': 'Terkirim', // Default status
    };

    print("Sending message: $tempMessage");

    setState(() {
      _messages.add(tempMessage); // Add the message to the UI immediately
      _scrollToBottom(); // Scroll to the bottom
    });

    _messageController.clear(); // Clear the input field

    try {
      final response = await _dio.post(
        'http://213.35.123.110:5555/api/ChatMessages/send-message',
        data: {
          'roomId': roomId,
          'senderId': idEmployee,
          'message': messageText,
        },
      );

      if (response.statusCode == 200) {
        final sentMessage = response.data;
        print("Message sent successfully: $sentMessage");
        setState(() {
          // Update the temporary message with the actual server response
          final index = _messages.indexWhere((msg) => msg['Id'] == tempMessage['Id']);
          if (index != -1) {
            _messages[index] = sentMessage;
          }
        });
      } else {
        print("Failed to send message, status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending message: $e");
      setState(() {
        // Remove the temporary message if sending fails
        _messages.removeWhere((msg) => msg['Id'] == tempMessage['Id']);
      });
    }
  }

  Future<void> _loadMessages() async {
    if (roomId == null || idEmployee == null) return;

    try {
      final response = await _dio.get(
        'http://213.35.123.110:5555/api/ChatMessages/room/$roomId',
        queryParameters: {'currentUserId': idEmployee},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _messages = data['Messages'] ?? [];
          opponent = data['Opponent'];
        });
      }
    } catch (e) {
      print("Error loading messages: $e");
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

  void _updateMessageStatusInUI(int messageId, String newStatus) {
    setState(() {
      for (var msg in _messages) {
        if (msg['Id'] == messageId) {
          msg['Status'] = newStatus;
          break;
        }
      }
    });
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
            image: AssetImage('assets/images/chat_background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
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