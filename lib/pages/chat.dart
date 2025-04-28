import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';

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
  HubConnection? _hubConnection;

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
  }

  Future<void> _initializeSignalR() async {
    if (roomId == null) {
      print('Cannot initialize SignalR: roomId is null');
      return;
    }

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            'http://213.35.123.110:5555/chatHub',
            options: HttpConnectionOptions(),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.onclose(({Exception? error}) {
        print('SignalR Connection Closed: $error');
        Future.delayed(const Duration(seconds: 5), _initializeSignalR);
      });

      // Handler untuk ReceiveMessage
      _hubConnection?.on('ReceiveMessage', (arguments) {
        print('Received SignalR ReceiveMessage: $arguments');
        _handleMessage(arguments);
      });

      // Handler untuk receiveMessage
      _hubConnection?.on('receiveMessage', (arguments) {
        print('Received SignalR receiveMessage: $arguments');
        _handleMessage(arguments);
      });

      // Handler untuk NewMessage
      _hubConnection?.on('NewMessage', (arguments) {
        print('Received SignalR NewMessage: $arguments');
        _handleMessage(arguments);
      });

      // Handler untuk Message
      _hubConnection?.on('Message', (arguments) {
        print('Received SignalR Message: $arguments');
        _handleMessage(arguments);
      });

      // Handler untuk UpdateMessageStatus
      _hubConnection?.on('UpdateMessageStatus', (arguments) {
        print('Received SignalR UpdateMessageStatus: $arguments');
        if (arguments != null && arguments.isNotEmpty) {
          final statusUpdate = arguments[0];
          if (statusUpdate is Map<String, dynamic>) {
            final messageId = statusUpdate['id'] ?? statusUpdate['Id'];
            final newStatus = statusUpdate['status'] ?? statusUpdate['Status'];
            if (messageId != null && newStatus != null) {
              setState(() {
                for (var msg in _messages) {
                  if (msg['Id'] == messageId) {
                    msg['Status'] = newStatus;
                    break;
                  }
                }
              });
            } else {
              print('Invalid status update format: $statusUpdate');
            }
          } else {
            print('Invalid status update type: $statusUpdate');
          }
        }
      });

      await _hubConnection?.start();
      print('SignalR connection started. State: ${_hubConnection?.state}');

      // Bergabung ke grup
      try {
        if (roomId != null) {
          await _hubConnection?.invoke('JoinRoom', args: [roomId!]);
          print('Joined room: $roomId');
        } else {
          print('Error: roomId is null, cannot join room.');
        }
      } catch (e) {
        print('Error joining room: $e');
        try {
          if (roomId != null) {
            await _hubConnection?.invoke('AddToGroup', args: [roomId!]);
            print('Joined group (AddToGroup): $roomId');
          } else {
            print('Error: roomId is null, cannot add to group.');
          }
        } catch (e2) {
          print('Error joining group (AddToGroup): $e2');
          try {
            if (roomId != null) {
              await _hubConnection?.invoke('JoinGroup', args: [roomId!]);
              print('Joined group (JoinGroup): $roomId');
            } else {
              print('Error: roomId is null, cannot join group.');
            }
          } catch (e3) {
            print('Error joining group (JoinGroup): $e3');
          }
        }
      }
    } catch (e) {
      print('Error initializing SignalR: $e');
      Future.delayed(const Duration(seconds: 5), _initializeSignalR);
    }
  }

  void _handleMessage(List<dynamic>? arguments) {
    print('Handling message: $arguments');
    print('Type of arguments: ${arguments.runtimeType}');
    if (arguments != null && arguments.isNotEmpty) {
      print('First argument: ${arguments[0]}');
      print('Type of first argument: ${arguments[0].runtimeType}');
      var message = arguments[0];
      if (message is List && message.isNotEmpty) {
        message = message[0];
      }
      if (message is Map<String, dynamic> &&
          (message['roomId']?.toString() == roomId ||
              message['RoomId']?.toString() == roomId)) {
        // Cek apakah pesan sudah ada berdasarkan Id
        final messageId = message['Id'] ?? message['id'];
        if (messageId != null &&
            !_messages.any((msg) => msg['Id'] == messageId)) {
          setState(() {
            _messages.add({
              'Id': messageId,
              'Message': message['Message'] ??
                  message['message'] ??
                  message['Content'] ??
                  message['content'],
              'SenderId': message['SenderId'] ?? message['senderId'],
              'CreatedAt': message['CreatedAt'] ?? message['createdAt'],
              'Status': message['Status'] ?? message['status'] ?? 'Terkirim',
              'Sender': message['Sender'] ?? message['sender'],
              'roomId': message['roomId'] ?? message['RoomId'],
            });
          });
          print('Added new message to _messages: $message');
          _scrollToBottom();
          if (message['SenderId'] != idEmployee &&
              (message['Status'] ?? message['status']) != 'Dibaca') {
            _updateMessageStatus(messageId, 'Dibaca');
          }
        } else {
          print('Message already exists or invalid ID: $messageId');
        }
      } else {
        print('Invalid message format or roomId mismatch: $message');
      }
    } else {
      print('Empty or invalid SignalR message: $arguments');
    }
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
    _hubConnection?.stop();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    final prefs = await SharedPreferences.getInstance();
    idEmployee = prefs.getInt('idEmployee');
    print('idEmployee: $idEmployee');
    if (idEmployee == null) {
      print('Error: idEmployee is null');
      return;
    }

    roomId = prefs.getString('roomId');
    konsultasiId = prefs.getString('konsultasiId');

    if (roomId == null || konsultasiId == null) {
      final existingConsultation =
          await _checkExistingConsultation(idEmployee!);
      if (existingConsultation != null) {
        setState(() {
          konsultasiId = existingConsultation['KonsultasiId']?.toString() ??
              existingConsultation['Id']?.toString();
          roomId = existingConsultation['ChatRoomId']?.toString() ??
              (existingConsultation['ChatRoom'] != null
                  ? existingConsultation['ChatRoom']['Id']?.toString()
                  : null);
        });
        if (konsultasiId != null) {
          await prefs.setString('konsultasiId', konsultasiId!);
          if (roomId != null) {
            await prefs.setString('roomId', roomId!);
          }
        }
      } else {
        await _createKonsultasi(idEmployee!);
      }
    }

    if (roomId != null) {
      await _loadMessages();
      await _initializeSignalR();
    }
  }

  Future<Map<String, dynamic>?> _checkExistingConsultation(
      int idEmployee) async {
    try {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/Konsultasis/employee/$idEmployee');
      final response = await http.get(url);

      print('Response from GET /api/Konsultasis/employee/$idEmployee: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          print('Found consultation: ${data[0]}');
          return data[0];
        } else if (data is Map<String, dynamic> && data.isNotEmpty) {
          print('Found consultation: $data');
          return data;
        } else {
          print('No consultation found for idEmployee: $idEmployee');
        }
      } else {
        print('Failed to fetch consultation for idEmployee: $idEmployee, '
            'Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error checking consultation for idEmployee: $idEmployee: $e');
    }
    return null;
  }

  Future<void> _createKonsultasi(int idEmployee) async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(
        'http://213.35.123.110:5555/api/Konsultasis/create-consultation');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEmployee': idEmployee}),
      );

      print('Response from POST /api/Konsultasis/create-consultation: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        konsultasiId =
            data['KonsultasiId']?.toString() ?? data['Id']?.toString();
        roomId = data['ChatRoomId']?.toString() ??
            (data['ChatRoom'] != null
                ? data['ChatRoom']['Id']?.toString()
                : null);
        if (konsultasiId != null) {
          await prefs.setString('konsultasiId', konsultasiId!);
          if (roomId != null) {
            await prefs.setString('roomId', roomId!);
          }
        }
      } else {
        final error = jsonDecode(response.body);
        if (error['Message'] == 'Room chat sudah ada.') {
          roomId = error['ChatRoomId']?.toString();
          if (roomId != null) {
            await prefs.setString('roomId', roomId!);
            final existingConsultation =
                await _checkExistingConsultation(idEmployee);
            if (existingConsultation != null) {
              konsultasiId = existingConsultation['KonsultasiId']?.toString() ??
                  existingConsultation['Id']?.toString();
              if (konsultasiId != null) {
                await prefs.setString('konsultasiId', konsultasiId!);
              }
            }
          }
        } else {
          print('Failed to create consultation: ${response.body}');
        }
      }
    } catch (e) {
      print('Error creating consultation: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (roomId == null || idEmployee == null) {
      print('Error: roomId or idEmployee is null');
      return;
    }

    try {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await http.get(url);

      print('Response from GET /api/ChatMessages/room/$roomId: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Filter pesan untuk menghindari duplikasi berdasarkan Id
          final newMessages = (data['Messages'] ?? []) as List<dynamic>;
          for (var msg in newMessages) {
            if (!_messages
                .any((existingMsg) => existingMsg['Id'] == msg['Id'])) {
              _messages.add(msg);
            }
          }
          opponent = data['Opponent'];
        });
        print('Loaded messages: ${_messages.length} messages');
        _scrollToBottom();
        for (var msg in _messages) {
          if (msg['SenderId'] != idEmployee && msg['Status'] != 'Dibaca') {
            await _updateMessageStatus(msg['Id'], 'Dibaca');
          }
        }
      } else if (response.statusCode == 404) {
        print('Room not found, attempting to create new consultation');
        await _createKonsultasi(idEmployee!);
        await _loadChatRoom();
      } else {
        print('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || idEmployee == null || roomId == null) {
      print('Cannot send message: empty message or invalid roomId/idEmployee');
      return;
    }

    try {
      // Kirim pesan melalui SignalR
      await _hubConnection?.invoke('SendMessage', args: [
        {
          'roomId': roomId,
          'senderId': idEmployee,
          'message': messageText,
        }
      ]);
      print('Message sent via SignalR: $messageText');
      _messageController.clear();
      // Fallback: Muat ulang pesan untuk memperbarui UI (opsional, bisa dikomentari setelah SignalR stabil)
      // await _loadMessages();
    } catch (e) {
      print('Error sending message via SignalR: $e');
      // Fallback ke HTTP
      final url =
          Uri.parse('http://213.35.123.110:5555/api/ChatMessages/send-message');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'senderId': idEmployee,
          'message': messageText,
        }),
      );

      print('Response from POST /api/ChatMessages/send-message: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _messageController.clear();
        await _loadMessages(); // Muat ulang pesan untuk memperbarui UI
      } else if (jsonDecode(response.body)['Message'] ==
          'Chat room tidak ditemukan.') {
        await _createKonsultasi(idEmployee!);
        await _loadChatRoom();
        await _sendMessage();
      } else {
        print('Failed to send message via HTTP: ${response.body}');
      }
    }
  }

  Future<void> _updateMessageStatus(int messageId, String status) async {
    try {
      final url = Uri.parse(
          'http://213.35.123.110:5555/api/ChatMessages/update-status/$messageId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      print('Response from PUT /api/ChatMessages/update-status/$messageId: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          for (var msg in _messages) {
            if (msg['Id'] == messageId) {
              msg['Status'] = status;
              break;
            }
          }
        });
      } else {
        print('Failed to update message status: ${response.body}');
      }
    } catch (e) {
      print('Error updating message status: $e');
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      print(
          'Warning: timeString is null or empty, using current time as fallback');
      final now = DateTime.now();
      return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
    try {
      final dt = DateTime.parse(timeString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print(
          'Error parsing timeString \'$timeString\': $e, using current time as fallback');
      final now = DateTime.now();
      return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent != null ? opponent!['Name'] ?? 'N/A' : 'Loading...',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  opponent != null ? opponent!['Department'] ?? 'N/A' : '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  if (msg == null) return const SizedBox();
                  final isMe = msg['SenderId'] == idEmployee;
                  final message = msg['Message'] ?? '[Pesan kosong]';
                  final sender = msg['Sender'];
                  final senderName = sender?['EmployeeName'] ?? '';
                  final createdAt = msg['CreatedAt'];
                  final status = msg['Status'] ?? 'Terkirim';

                  print(
                      'Message $index: createdAt = $createdAt, formatted time = ${_formatTime(createdAt)}');

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: EdgeInsets.only(
                              left: isMe ? 50 : 8,
                              right: isMe ? 8 : 50,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMe ? const Color(0xFFE1FFC7) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(12),
                              ),
                              boxShadow: const [
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
                                if (!isMe) const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        decoration: const InputDecoration(
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
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1572E8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
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
