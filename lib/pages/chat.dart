import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _messages = [];
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
            'http://192.168.100.140:5555/chatHub',
            options: HttpConnectionOptions(),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.onclose(({Exception? error}) {
        print('SignalR Connection Closed: $error');
        Future.delayed(const Duration(seconds: 5), _initializeSignalR);
      });

      _hubConnection?.on('ReceiveMessage', (arguments) {
        print('Received SignalR ReceiveMessage: $arguments');
        _handleMessage(arguments);
      });

      _hubConnection?.on('receiveMessage', (arguments) {
        print('Received SignalR receiveMessage: $arguments');
        _handleMessage(arguments);
      });

      _hubConnection?.on('NewMessage', (arguments) {
        print('Received SignalR NewMessage: $arguments');
        _handleMessage(arguments);
      });

      _hubConnection?.on('Message', (arguments) {
        print('Received SignalR Message: $arguments');
        _handleMessage(arguments);
      });

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
              _saveMessagesLocally();
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
        final messageId = message['Id'] ?? message['id'];
        if (messageId != null &&
            !_messages.any((msg) => msg['Id'] == messageId)) {
          final createdAt = message['CreatedAt'] ?? message['createdAt'];
          final timestamp = _formatTimestamp(createdAt);
          var sender = message['Sender'] ?? message['sender'] ?? {};
          // Gunakan data dari opponent sebagai fallback jika Sender tidak lengkap
          if (sender.isEmpty &&
              opponent != null &&
              message['SenderId'] == opponent!['Id']) {
            sender = {
              'Id': opponent!['Id'],
              'EmployeeName': opponent!['Name'],
              'Email': null,
              'ProfilePhoto': opponent!['ProfilePhoto'],
            };
          }
          print('Sender data in received message: $sender');
          setState(() {
            _messages.add({
              'Id': messageId,
              'Message': message['Message'] ??
                  message['message'] ??
                  message['Content'] ??
                  message['content'],
              'SenderId': message['SenderId'] ?? message['senderId'],
              'CreatedAt': createdAt,
              'FormattedTime': timestamp['time'],
              'FormattedDate': timestamp['date'],
              'Status': message['Status'] ?? message['status'] ?? 'Terkirim',
              'Sender': sender,
              'roomId': message['roomId'] ?? message['RoomId'],
            });
          });
          print('Added new message to _messages: $message');
          _saveMessagesLocally();
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

    if (roomId != null && idEmployee != null) {
      final isRoomValid = await _verifyRoomExists(roomId!, idEmployee!);
      if (!isRoomValid) {
        print('Room $roomId is no longer valid. Clearing local data.');
        await _clearLocalChatData(prefs);
        roomId = null;
        konsultasiId = null;
      }
    }

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
      await _loadLocalMessages();
      await _initializeSignalR();
    }
  }

  Future<bool> _verifyRoomExists(String roomId, int idEmployee) async {
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await http.get(url);

      print(
          'Verifying room $roomId: Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        print('Room $roomId not found on server.');
        return false;
      } else {
        print(
            'Error verifying room $roomId: Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error verifying room $roomId: $e');
      return false;
    }
  }

  Future<void> _clearLocalChatData(SharedPreferences prefs) async {
    await prefs.remove('roomId');
    await prefs.remove('konsultasiId');
    if (roomId != null) {
      await prefs.remove('messages_$roomId');
    }
    setState(() {
      _messages.clear();
      roomId = null;
      konsultasiId = null;
    });
    print('Cleared local chat data.');
  }

  Future<void> _loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('messages_$roomId');
    if (messagesJson != null) {
      try {
        final messages = jsonDecode(messagesJson) as List<dynamic>;
        setState(() {
          _messages.clear();
          for (var msg in messages) {
            if (msg['Id'] != null && msg['CreatedAt'] != null) {
              final timestamp = _formatTimestamp(msg['CreatedAt']);
              var sender = msg['Sender'] ?? {};
              // Gunakan data dari opponent sebagai fallback
              if (sender.isEmpty &&
                  opponent != null &&
                  msg['SenderId'] == opponent!['Id']) {
                sender = {
                  'Id': opponent!['Id'],
                  'EmployeeName': opponent!['Name'],
                  'Email': null,
                  'ProfilePhoto': opponent!['ProfilePhoto'],
                };
              }
              final updatedMsg = {
                ...msg,
                'FormattedTime': msg['FormattedTime'] ?? timestamp['time'],
                'FormattedDate': msg['FormattedDate'] ?? timestamp['date'],
                'Sender': sender,
              };
              _messages.add(updatedMsg);
              print('Loaded local message: $updatedMsg');
            } else {
              print('Skipping invalid local message: $msg');
            }
          }
        });
        print('Loaded ${_messages.length} messages from local storage');
        _scrollToBottom();
      } catch (e) {
        print('Error loading local messages: $e');
        await prefs.remove('messages_$roomId');
      }
    }
  }

  Future<void> _saveMessagesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final validMessages = _messages
          .where((msg) => msg['Id'] != null && msg['CreatedAt'] != null)
          .map((msg) => {
                'Id': msg['Id'],
                'Message': msg['Message'],
                'SenderId': msg['SenderId'],
                'CreatedAt': msg['CreatedAt'],
                'FormattedTime': msg['FormattedTime'],
                'FormattedDate': msg['FormattedDate'],
                'Status': msg['Status'],
                'Sender': msg['Sender'] ?? {},
                'roomId': msg['roomId'],
              })
          .toList();
      final messagesJson = jsonEncode(validMessages);
      await prefs.setString('messages_$roomId', messagesJson);
      print('Saved ${validMessages.length} messages to local storage');
    } catch (e) {
      print('Error saving messages to local storage: $e');
    }
  }

  Future<Map<String, dynamic>?> _checkExistingConsultation(
      int idEmployee) async {
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/Konsultasis/employee/$idEmployee');
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
        'http://192.168.100.140:5555/api/Konsultasis/create-consultation');
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
          'http://192.168.100.140:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await http.get(url);

      print('Response from GET /api/ChatMessages/room/$roomId: '
          'Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final newMessages = (data['Messages'] ?? []) as List<dynamic>;
          _messages.clear();
          for (var msg in newMessages) {
            final messageId = msg['Id'];
            print(
                'Processing message ID: $messageId, Sender: ${msg['Sender']}, CreatedAt: ${msg['CreatedAt']}');
            if (msg['CreatedAt'] == null) {
              print('Warning: Message ID $messageId has null CreatedAt');
            }
            final timestamp = _formatTimestamp(msg['CreatedAt']);
            var sender = msg['Sender'] ?? {};
            // Gunakan data dari opponent sebagai fallback
            if (sender.isEmpty &&
                opponent != null &&
                msg['SenderId'] == opponent!['Id']) {
              sender = {
                'Id': opponent!['Id'],
                'EmployeeName': opponent!['Name'],
                'Email': null,
                'ProfilePhoto': opponent!['ProfilePhoto'],
              };
            }
            _messages.add({
              ...msg,
              'FormattedTime': timestamp['time'],
              'FormattedDate': timestamp['date'],
              'Sender': sender,
            });
          }
          opponent = data['Opponent'];
        });
        print('Loaded messages: ${_messages.length} messages');
        _saveMessagesLocally();
        _scrollToBottom();
        for (var msg in _messages) {
          if (msg['SenderId'] != idEmployee && msg['Status'] != 'Dibaca') {
            await _updateMessageStatus(msg['Id'], 'Dibaca');
          }
        }
      } else if (response.statusCode == 404) {
        print(
            'Room not found, clearing local data and creating new consultation');
        final prefs = await SharedPreferences.getInstance();
        await _clearLocalChatData(prefs);
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

    // Buat pesan sementara untuk ditampilkan sebelum respons server
    final timestamp = _formatTimestamp(DateTime.now().toString());
    final tempMessage = {
      'Id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'Message': messageText,
      'SenderId': idEmployee,
      'CreatedAt': DateTime.now().toString(),
      'FormattedTime': timestamp['time'],
      'FormattedDate': timestamp['date'],
      'Status': 'Terkirim',
      'Sender': {
        'Id': idEmployee,
        'EmployeeName': 'You', // Nama sementara untuk pengguna sendiri
        'Email': null,
        'ProfilePhoto': null,
      },
      'roomId': roomId,
    };

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      await _hubConnection?.invoke('SendMessage', args: [
        {
          'roomId': roomId,
          'senderId': idEmployee,
          'message': messageText,
        }
      ]);
      print('Message sent via SignalR: $messageText');
      _messageController.clear();
      await _loadMessages(); // Muat ulang pesan dari server
    } catch (e) {
      print('Error sending message via SignalR: $e');
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/send-message');
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
        await _loadMessages();
      } else if (jsonDecode(response.body)['Message'] ==
          'Chat room tidak ditemukan.') {
        final prefs = await SharedPreferences.getInstance();
        await _clearLocalChatData(prefs);
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
          'http://192.168.100.140:5555/api/ChatMessages/update-status/$messageId');
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
        _saveMessagesLocally();
      } else {
        print('Failed to update message status: ${response.body}');
      }
    } catch (e) {
      print('Error updating message status: $e');
    }
  }

  Map<String, String> _formatTimestamp(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      print('Warning: timeString is null or empty for timestamp formatting');
      return {'date': 'Unknown Date', 'time': '--:--'};
    }

    print('Attempting to parse timeString for timestamp: $timeString');

    // Normalize whitespace and split
    final normalizedString = timeString.trim().replaceAll(RegExp(r'\s+'), ' ');
    print('Normalized timeString: $normalizedString');

    // Try direct extraction for format: "dd MMMM yyyy HH.mm"
    try {
      final parts = normalizedString.split(' ');
      print('Split parts: $parts');
      if (parts.length == 4) {
        final day = parts[0];
        final month = parts[1];
        final year = parts[2];
        final timePart = parts[3];
        print(
            'Extracted day: $day, month: $month, year: $year, timePart: $timePart');

        final timeParts = timePart.split('.');
        print('Split time parts: $timeParts');
        if (timeParts.length == 2) {
          final hour = timeParts[0].padLeft(2, '0');
          final minute = timeParts[1].padLeft(2, '0');
          final formattedDate = '$day $month $year';
          final formattedTime = '$hour:$minute';
          print(
              'Successfully extracted timestamp: $timeString -> date: $formattedDate, time: $formattedTime');
          return {'date': formattedDate, 'time': formattedTime};
        } else {
          print('Invalid time part format: $timePart');
        }
      } else {
        print('Unexpected number of parts: ${parts.length}');
      }
    } catch (e) {
      print('Error extracting timestamp \'$timeString\': $e');
    }

    // Fallback to DateFormat parsing
    try {
      final formatter = DateFormat('dd MMMM yyyy HH.mm', 'id_ID');
      final dateTime = formatter.parseLoose(timeString).toLocal();
      final formattedDate =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
      final formattedTime =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      print(
          'Successfully parsed local timestamp: $timeString -> date: $formattedDate, time: $formattedTime');
      return {'date': formattedDate, 'time': formattedTime};
    } catch (e) {
      print('Error parsing local timestamp \'$timeString\': $e');
    }

    // Fallback to ISO 8601 parsing
    try {
      final dateTime = DateTime.parse(timeString).toLocal();
      final formattedDate =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
      final formattedTime =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      print(
          'Successfully parsed ISO timestamp: $timeString -> date: $formattedDate, time: $formattedTime');
      return {'date': formattedDate, 'time': formattedTime};
    } catch (e) {
      print('Error parsing ISO timestamp \'$timeString\': $e');
    }

    // Fallback to manual parsing
    try {
      final parts = normalizedString.toLowerCase().split(' ');
      if (parts.length == 4) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);
        final timeParts = parts[3].split('.');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final monthMap = {
          'januari': 1,
          'februari': 2,
          'maret': 3,
          'april': 4,
          'mei': 5,
          'juni': 6,
          'juli': 7,
          'agustus': 8,
          'september': 9,
          'oktober': 10,
          'november': 11,
          'desember': 12
        };
        final month = monthMap[monthStr.toLowerCase()];
        if (month == null) throw FormatException('Invalid month: $monthStr');

        final dateTime = DateTime(year, month, day, hour, minute).toLocal();
        final formattedDate =
            DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
        final formattedTime =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
        print(
            'Successfully parsed manual timestamp: $timeString -> date: $formattedDate, time: $formattedTime');
        return {'date': formattedDate, 'time': formattedTime};
      }
    } catch (e) {
      print('Error parsing manual timestamp \'$timeString\': $e');
    }

    print('All parsing attempts failed for timeString: $timeString');
    return {'date': 'Unknown Date', 'time': '--:--'};
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
                  final sender = msg['Sender'] ?? {};
                  // Gunakan opponent sebagai fallback untuk nama pengirim
                  final senderName = sender['EmployeeName']?.toString() ??
                      (opponent != null && msg['SenderId'] == opponent!['Id']
                          ? opponent!['Name']?.toString() ?? 'Unknown'
                          : 'Unknown');
                  print(
                      'Message $index: Sender = $sender, SenderName = $senderName, CreatedAt = ${msg['CreatedAt']}');

                  final formattedTime = msg['FormattedTime'] ??
                      _formatTimestamp(msg['CreatedAt'])['time'];
                  final formattedDate = msg['FormattedDate'] ??
                      _formatTimestamp(msg['CreatedAt'])['date'];
                  final status = msg['Status'] ?? 'Terkirim';

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
                                      '$formattedDate $formattedTime',
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
