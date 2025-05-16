import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:intl/intl.dart';
import 'package:retry/retry.dart';
import 'package:intl/date_symbol_data_local.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? opponent;
  String? roomId;
  String? konsultasiId;
  int? idEmployee;
  HubConnection? _hubConnection;
  bool _isLoading = true;
  String? _errorMessage;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _saveMessagesTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _showConnectedMessage = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted && !_isDisposed) {
        _loadChatRoom();
      }
    }).catchError((e) {
      print('Error initializing locale: $e');
      if (mounted && !_isDisposed) {
        setState(
            () => _errorMessage = 'Gagal menginisialisasi format tanggal: $e');
      }
    });
  }

  Future<void> _initializeSignalR() async {
    if (roomId == null || _isDisposed) {
      print('Cannot initialize SignalR: roomId is null or page is disposed');
      return;
    }

    try {
      print(
          'Initializing SignalR for room: $roomId (Attempt ${_reconnectAttempts + 1})');
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            'http://192.168.100.140:5555/chatHub',
            options: HttpConnectionOptions(
              requestTimeout: 30000,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      if (_hubConnection != null) {
        _hubConnection!.onclose(({Exception? error}) {
          print('SignalR Connection Closed: $error');
          if (mounted && !_isDisposed) {
            setState(() {
              _errorMessage =
                  'Koneksi SignalR terputus: ${error?.toString() ?? "Tidak diketahui"}';
            });
            _scheduleReconnect();
          }
        });

        _hubConnection!.on('ReceiveMessage', (List<dynamic>? arguments) {
          print('Received SignalR ReceiveMessage: $arguments');
          _handleMessage(arguments);
        });

        _hubConnection!.on('receiveMessage', (List<dynamic>? arguments) {
          print('Received SignalR receiveMessage: $arguments');
          _handleMessage(arguments);
        });

        _hubConnection!.on('NewMessage', (List<dynamic>? arguments) {
          print('Received SignalR NewMessage: $arguments');
          _handleMessage(arguments);
        });

        _hubConnection!.on('Message', (List<dynamic>? arguments) {
          print('Received SignalR Message: $arguments');
          _handleMessage(arguments);
        });

        _hubConnection!.on('UpdateMessageStatus', (List<dynamic>? arguments) {
          print('Received SignalR UpdateMessageStatus: $arguments');
          if (arguments != null && arguments.isNotEmpty) {
            final statusUpdate = arguments[0] as Map<String, dynamic>?;
            if (statusUpdate != null) {
              final messageId = statusUpdate['id'] ?? statusUpdate['Id'];
              final newStatus =
                  statusUpdate['status'] ?? statusUpdate['Status'];
              print('Updating status for messageId: $messageId to $newStatus');
              if (messageId != null &&
                  newStatus != null &&
                  mounted &&
                  !_isDisposed) {
                setState(() {
                  final index =
                      _messages.indexWhere((msg) => msg['Id'] == messageId);
                  if (index != -1) {
                    _messages[index]['Status'] = newStatus;
                    print(
                        'Real-time status updated in _messages at index $index: ${_messages[index]}');
                  } else {
                    print(
                        'MessageId $messageId not found in _messages, reloading messages...');
                    _loadMessages();
                  }
                });
                _triggerSaveMessages();
                _scrollToBottom();
              }
            }
          }
        });

        print('Starting SignalR connection...');
        await retry(
          () async {
            await _hubConnection!.start();
          },
          maxAttempts: 5,
          delayFactor: const Duration(seconds: 2),
          onRetry: (e) {
            print('Retrying SignalR start due to: $e');
          },
        );
        print('SignalR connection started. State: ${_hubConnection!.state}');

        print('Joining room: $roomId with idEmployee: $idEmployee');
        await _hubConnection!.invoke('JoinRoom', args: [roomId!, "a", "a"]);
        print('Successfully joined room: $roomId');
        if (mounted && !_isDisposed) {
          setState(() {
            _errorMessage = null;
            _showConnectedMessage = true;
          });
          Timer(const Duration(seconds: 3), () {
            if (mounted && !_isDisposed) {
              setState(() => _showConnectedMessage = false);
            }
          });
        }
        _reconnectAttempts = 0;
      } else {
        print('Failed to initialize HubConnection');
        if (mounted && !_isDisposed) {
          setState(
              () => _errorMessage = 'Gagal menginisialisasi koneksi SignalR.');
        }
      }
    } catch (e, stackTrace) {
      print('Error initializing SignalR: $e\nStack trace: $stackTrace');
      if (e.toString().contains('Invocation canceled')) {
        print('SignalR invocation canceled, falling back to HTTP...');
        await _joinRoomViaHttp();
      } else if (mounted && !_isDisposed) {
        setState(
            () => _errorMessage = 'Gagal menghubungkan ke server SignalR: $e');
        _scheduleReconnect();
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinRoomViaHttp() async {
    if (roomId == null || idEmployee == null || _isDisposed) {
      print(
          'Cannot join room via HTTP: roomId or idEmployee is null or page is disposed');
      return;
    }

    try {
      final url =
          Uri.parse('http://192.168.100.140:5555/api/ChatMessages/join-room');
      final response = await retry(
        () => http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'roomId': roomId, 'userId': idEmployee}),
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Joining room via HTTP: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 && mounted && !_isDisposed) {
        setState(() {
          _errorMessage = null;
          _showConnectedMessage = true;
        });
        Timer(const Duration(seconds: 3), () {
          if (mounted && !_isDisposed) {
            setState(() => _showConnectedMessage = false);
          }
        });
      } else if (mounted && !_isDisposed) {
        setState(() => _errorMessage =
            'Gagal bergabung ke room via HTTP: ${response.body}');
        _scheduleReconnect();
      }
    } catch (e) {
      print('Error joining room via HTTP: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Gagal bergabung ke room via HTTP: $e');
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) {
      print(
          'Max reconnect attempts reached or page is disposed. Stopping reconnection.');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage =
            'Gagal menghubungkan setelah beberapa percobaan. Silakan coba lagi nanti.');
      }
      return;
    }

    final delay = Duration(seconds: _reconnectAttempts + 1);
    _reconnectAttempts++;
    print(
        'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds} seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (mounted &&
          !_isDisposed &&
          _hubConnection?.state != HubConnectionState.Connected) {
        print('Attempting to reconnect to SignalR...');
        try {
          await _initializeSignalR();
          if (_hubConnection?.state == HubConnectionState.Connected &&
              mounted &&
              !_isDisposed) {
            print('Reconnection successful.');
            setState(() => _errorMessage = null);
          } else {
            print('Reconnection failed, scheduling next attempt...');
            _scheduleReconnect();
          }
        } catch (e) {
          print('Reconnection error: $e');
          _scheduleReconnect();
        }
      } else if (_hubConnection?.state == HubConnectionState.Connected &&
          mounted &&
          !_isDisposed) {
        print('Connection already established, skipping reconnect.');
        _reconnectAttempts = 0;
        setState(() => _errorMessage = null);
      }
    });
  }

  void _handleMessage(List<dynamic>? arguments) {
    if (_isDisposed) {
      print('Skipping handleMessage: Page is disposed');
      return;
    }
    print('Handling message: $arguments');
    if (arguments == null || arguments.isEmpty) {
      print('Empty or invalid SignalR message');
      return;
    }

    var message = arguments[0] is List ? arguments[0][0] : arguments[0];
    if (message is! Map<String, dynamic>) {
      print('Invalid message format: $message');
      return;
    }

    if (message['roomId']?.toString() == roomId ||
        message['RoomId']?.toString() == roomId) {
      final messageId = message['Id'] ?? message['id'];
      if (messageId != null &&
          !_messages.any((msg) => msg['Id'] == messageId)) {
        final createdAt = message['CreatedAt'] ?? message['createdAt'];
        final timestamp = _formatTimestamp(createdAt);
        var sender = message['Sender'] is Map
            ? Map<String, dynamic>.from(message['Sender'] as Map)
            : {};
        print('Sender data: $sender');
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

        final messageStatus =
            message['Status'] ?? message['status'] ?? 'Terkirim';
        print(
            'Adding message with messageId: $messageId, SenderId: ${message['SenderId']}, Status: $messageStatus');

        if (mounted && !_isDisposed) {
          setState(() {
            _messages.add({
              'Id': messageId,
              'Message': message['Message'] ??
                  message['message'] ??
                  message['Content'] ??
                  '',
              'SenderId': message['SenderId'] ?? message['senderId'],
              'CreatedAt': createdAt,
              'FormattedTime': timestamp['time'],
              'FormattedDate': timestamp['date'],
              'Status': messageStatus,
              'Sender': sender,
              'roomId': message['roomId'] ?? message['RoomId'],
            });
          });
          _triggerSaveMessages();
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _fixServerStatus(int messageId, String correctStatus) async {
    if (_isDisposed) {
      print('Skipping fixServerStatus: Page is disposed');
      return;
    }
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/update-status/$messageId');
      final response = await retry(
        () => http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': correctStatus}),
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Fixing server status for messageId $messageId to $correctStatus: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 && mounted && !_isDisposed) {
        print('Successfully fixed server status for messageId $messageId');
      } else if (mounted && !_isDisposed) {
        setState(() => _errorMessage =
            'Gagal memperbaiki status pesan di server: ${response.body}');
      }
    } catch (e) {
      print('Error fixing server status for messageId $messageId: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Gagal memperbaiki status pesan: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted && !_isDisposed) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    print('Disposing ChatPageState...');
    _isDisposed = true;
    _saveMessagesTimer?.cancel();
    _reconnectTimer?.cancel();
    _hubConnection?.stop();
    _hubConnection = null;
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
    print('ChatPageState disposed.');
  }

  Future<void> _loadChatRoom() async {
    if (!mounted || _isDisposed) {
      print('Skipping loadChatRoom: Page is disposed');
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    idEmployee = prefs.getInt('idEmployee');
    print('idEmployee: $idEmployee');
    if (idEmployee == null) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ID karyawan tidak ditemukan. Silakan login ulang.';
        });
      }
      return;
    }

    roomId = prefs.getString('roomId');
    konsultasiId = prefs.getString('konsultasiId');

    if (roomId != null) {
      final isRoomValid = await _verifyRoomExists(roomId!);
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
      if (existingConsultation != null && mounted && !_isDisposed) {
        setState(() {
          konsultasiId = existingConsultation['KonsultasiId']?.toString() ??
              existingConsultation['Id']?.toString();
          roomId = existingConsultation['ChatRoomId']?.toString() ??
              existingConsultation['ChatRoom']?['Id']?.toString();
        });
        await prefs.setString('konsultasiId', konsultasiId!);
        if (roomId != null) await prefs.setString('roomId', roomId!);
      } else {
        await _createKonsultasi(idEmployee!);
      }
    }

    if (roomId != null) {
      print('Loading messages for room: $roomId');
      await _loadMessages();
      print('Loading local messages...');
      await _loadLocalMessages();
      print('Initializing SignalR...');
      await _initializeSignalR();
      if (mounted &&
          !_isDisposed &&
          _hubConnection?.state == HubConnectionState.Connected) {
        setState(() => _errorMessage = null);
      }
    } else {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat room chat. Silakan coba lagi.';
        });
      }
    }
  }

  Future<bool> _verifyRoomExists(String roomId) async {
    if (_isDisposed) {
      print('Skipping verifyRoomExists: Page is disposed');
      return false;
    }
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await retry(
        () => http.get(url, headers: {'Content-Type': 'application/json'}),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Verifying room $roomId: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else {
        if (mounted && !_isDisposed) {
          setState(() => _errorMessage =
              'Gagal memverifikasi room: Status ${response.statusCode}, ${response.body}');
        }
        return false;
      }
    } catch (e) {
      print('Error verifying room $roomId: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Gagal memverifikasi room: $e');
      }
      return false;
    }
  }

  Future<void> _clearLocalChatData(SharedPreferences prefs) async {
    if (_isDisposed) {
      print('Skipping clearLocalChatData: Page is disposed');
      return;
    }
    await prefs.remove('roomId');
    await prefs.remove('konsultasiId');
    if (roomId != null) await prefs.remove('messages_$roomId');
    if (mounted && !_isDisposed) {
      setState(() {
        _messages.clear();
        roomId = null;
        konsultasiId = null;
      });
    }
    print('Cleared local chat data.');
  }

  Future<void> _loadLocalMessages() async {
    if (_isDisposed) {
      print('Skipping loadLocalMessages: Page is disposed');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('messages_$roomId');
    if (messagesJson != null) {
      try {
        final messages = jsonDecode(messagesJson) as List<dynamic>;
        if (mounted && !_isDisposed) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages
                .where((msg) => msg['Id'] != null && msg['CreatedAt'] != null)
                .map((msg) {
              final timestamp = _formatTimestamp(msg['CreatedAt']);
              var sender = msg['Sender'] is Map
                  ? Map<String, dynamic>.from(msg['Sender'] as Map)
                  : {};
              print('Local sender data: $sender');
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
              final status = msg['Status']?.toString() ?? 'Terkirim';
              print(
                  'Loading local message Id: ${msg['Id']}, SenderId: ${msg['SenderId']}, Status: $status');
              return {
                ...msg as Map<String, dynamic>,
                'FormattedTime': timestamp['time'],
                'FormattedDate': timestamp['date'],
                'Sender': sender,
              };
            }));
          });
          print('Loaded ${_messages.length} messages from local storage');
          _scrollToBottom();
          _loadMessages();
        }
      } catch (e) {
        print('Error loading local messages: $e');
        await prefs.remove('messages_$roomId');
        if (mounted && !_isDisposed) {
          setState(() => _errorMessage = 'Gagal memuat pesan lokal: $e');
        }
      }
    }
  }

  Future<void> _saveMessagesLocally() async {
    _saveMessagesTimer?.cancel();
    _saveMessagesTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || _isDisposed) {
        print('Skipping saveMessagesLocally: State is not mounted or disposed');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      try {
        final validMessages = _messages
            .where((msg) => msg['Id'] != null && msg['CreatedAt'] != null)
            .map((msg) => {
                  'Id': msg['Id'],
                  'Message': msg['Message'],
                  'SenderId': msg['SenderId'],
                  'CreatedAt': msg['CreatedAt'], // Pastikan format ISO 8601
                  'FormattedTime': msg['FormattedTime'],
                  'FormattedDate': msg['FormattedDate'],
                  'Status': msg['Status'],
                  'Sender': msg['Sender'],
                  'roomId': msg['roomId'],
                })
            .toList();
        await prefs.setString('messages_$roomId', jsonEncode(validMessages));
        print('Saved ${validMessages.length} messages to local storage');
      } catch (e) {
        print('Error saving messages: $e');
        if (mounted && !_isDisposed) {
          setState(() => _errorMessage = 'Gagal menyimpan pesan lokal: $e');
        }
      }
    });
  }

  void _triggerSaveMessages() {
    if (!_isDisposed) {
      _saveMessagesLocally();
    }
  }

  Future<Map<String, dynamic>?> _checkExistingConsultation(
      int idEmployee) async {
    if (_isDisposed) {
      print('Skipping checkExistingConsultation: Page is disposed');
      return null;
    }
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/Konsultasis/employee/$idEmployee');
      final response = await retry(
        () => http.get(url, headers: {'Content-Type': 'application/json'}),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Checking consultation for idEmployee $idEmployee: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data is List && data.isNotEmpty)
            ? Map<String, dynamic>.from(data[0] as Map)
            : (data is Map ? Map<String, dynamic>.from(data) : null);
      } else {
        if (mounted && !_isDisposed) {
          setState(() =>
              _errorMessage = 'Gagal memeriksa konsultasi: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('Error checking consultation: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Gagal memeriksa konsultasi: $e');
      }
      return null;
    }
  }

  Future<void> _createKonsultasi(int idEmployee) async {
    if (_isDisposed) {
      print('Skipping createKonsultasi: Page is disposed');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(
        'http://192.168.100.140:5555/api/Konsultasis/create-consultation');
    try {
      final response = await retry(
        () => http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idEmployee': idEmployee}),
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Creating consultation for idEmployee $idEmployee: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted && !_isDisposed) {
          setState(() {
            konsultasiId =
                data['KonsultasiId']?.toString() ?? data['Id']?.toString();
            roomId = data['ChatRoomId']?.toString() ??
                data['ChatRoom']?['Id']?.toString();
            _errorMessage = null;
          });
        }
        await prefs.setString('konsultasiId', konsultasiId!);
        if (roomId != null) await prefs.setString('roomId', roomId!);
      } else if (response.statusCode == 409) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        if (error['Message'] == 'Room chat sudah ada.') {
          if (mounted && !_isDisposed) {
            setState(() {
              roomId = error['ChatRoomId']?.toString();
              _errorMessage = null;
            });
          }
          if (roomId != null) await prefs.setString('roomId', roomId!);
          final existingConsultation =
              await _checkExistingConsultation(idEmployee);
          if (existingConsultation != null && mounted && !_isDisposed) {
            setState(() {
              konsultasiId = existingConsultation['KonsultasiId']?.toString() ??
                  existingConsultation['Id']?.toString();
            });
            if (konsultasiId != null) {
              await prefs.setString('konsultasiId', konsultasiId!);
            }
          }
        }
      }
    } catch (e) {
      print('Error creating consultation: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (roomId == null || idEmployee == null || _isDisposed) {
      print('Error: roomId or idEmployee is null or page is disposed');
      return;
    }

    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/room/$roomId?currentUserId=$idEmployee');
      final response = await retry(
        () => http.get(url, headers: {'Content-Type': 'application/json'}),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Loading messages for room $roomId: Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = data['Messages'] as List<dynamic>? ?? [];
        print('Raw messages from server: $messages');

        // Update status pesan dari opponent menjadi "Dibaca" saat halaman chat dimuat
        final messagesToUpdate = messages
            .whereType<Map>()
            .where((msg) =>
                msg['SenderId'] != idEmployee && msg['Status'] != 'Dibaca')
            .toList();

        for (var msg in messagesToUpdate) {
          final messageId = msg['Id'];
          if (messageId != null) {
            await _updateMessageStatus(messageId, 'Dibaca');
          }
        }

        if (mounted && !_isDisposed) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages.whereType<Map>().map((msg) {
              final msgMap = Map<String, dynamic>.from(msg as Map);
              final timestamp = _formatTimestamp(msgMap['CreatedAt']);
              var sender = msgMap['Sender'] is Map
                  ? Map<String, dynamic>.from(msgMap['Sender'] as Map)
                  : {};
              print('Server sender data: $sender');
              if (sender.isEmpty &&
                  opponent != null &&
                  msgMap['SenderId'] == opponent!['Id']) {
                sender = {
                  'Id': opponent!['Id'],
                  'EmployeeName': opponent!['Name'],
                  'Email': null,
                  'ProfilePhoto': opponent!['ProfilePhoto'],
                };
              }
              final status = msgMap['Status']?.toString() ?? 'Terkirim';
              print(
                  'Loading server message Id: ${msgMap['Id']}, SenderId: ${msgMap['SenderId']}, Status: $status');
              return {
                ...msgMap,
                'FormattedTime': timestamp['time'],
                'FormattedDate': timestamp['date'],
                'Sender': sender,
                'Status': status,
              };
            }));
            opponent = data['Opponent'] is Map
                ? Map<String, dynamic>.from(data['Opponent'] as Map)
                : null;
          });
          print('Loaded ${_messages.length} messages');
          _triggerSaveMessages();
          _scrollToBottom();
          if (mounted && !_isDisposed) {
            setState(() => _errorMessage = null);
          }
        }
      } else if (response.statusCode == 404) {
        print(
            'Room not found, clearing local data and creating new consultation');
        final prefs = await SharedPreferences.getInstance();
        await _clearLocalChatData(prefs);
        await _createKonsultasi(idEmployee!);
        await _loadChatRoom();
      } else if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal memuat pesan: Status ${response.statusCode}, ${response.body}';
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat pesan: $e';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_isDisposed) {
      print('Skipping sendMessage: Page is disposed');
      return;
    }
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || idEmployee == null || roomId == null) {
      print('Cannot send message: empty message or invalid roomId/idEmployee');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Pesan kosong atau room tidak valid.');
      }
      return;
    }

    final timestamp = _formatTimestamp(DateTime.now().toIso8601String());
    final tempMessage = {
      'Id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'Message': messageText,
      'SenderId': idEmployee,
      'CreatedAt': DateTime.now().toIso8601String(), // Gunakan ISO 8601
      'FormattedTime': timestamp['time'],
      'FormattedDate': timestamp['date'],
      'Status': 'Mengirim',
      'Sender': {
        'Id': idEmployee,
        'EmployeeName': 'You',
        'Email': null,
        'ProfilePhoto': null,
      },
      'roomId': roomId,
    };

    if (mounted && !_isDisposed) {
      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();
    }

    try {
      final messageArgs = {
        'roomId': roomId,
        'senderId': idEmployee,
        'message': messageText,
      };
      print('Sending SignalR message with args: $messageArgs');
      await _hubConnection?.invoke('SendMessage', args: [messageArgs]);
      print('Message sent via SignalR: $messageText');
      if (mounted && !_isDisposed) {
        _messageController.clear();
        await _loadMessages();
      }
    } catch (e, stackTrace) {
      print('Error sending message via SignalR: $e\nStack trace: $stackTrace');
      try {
        final url = Uri.parse(
            'http://192.168.100.140:5555/api/ChatMessages/send-message');
        final response = await retry(
          () => http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'roomId': roomId,
              'senderId': idEmployee,
              'message': messageText,
            }),
          ),
          maxAttempts: 3,
          delayFactor: const Duration(seconds: 1),
        );
        print(
            'Sending message via HTTP: Status: ${response.statusCode}, Body: ${response.body}');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (mounted && !_isDisposed) {
            _messageController.clear();
            await _loadMessages();
          }
        } else if (jsonDecode(response.body)['Message'] ==
            'Chat room tidak ditemukan.') {
          final prefs = await SharedPreferences.getInstance();
          await _clearLocalChatData(prefs);
          await _createKonsultasi(idEmployee!);
          await _loadChatRoom();
          await _sendMessage();
        } else if (mounted && !_isDisposed) {
          setState(
              () => _errorMessage = 'Gagal mengirim pesan: ${response.body}');
        }
      } catch (e) {
        print('Error sending message via HTTP: $e');
        if (mounted && !_isDisposed) {
          setState(() => _errorMessage = 'Gagal mengirim pesan: $e');
        }
      }
    }
  }

  Future<void> _updateMessageStatus(int messageId, String status) async {
    if (_isDisposed) {
      print('Skipping updateMessageStatus: Page is disposed');
      return;
    }
    try {
      final url = Uri.parse(
          'http://192.168.100.140:5555/api/ChatMessages/update-status/$messageId');
      final response = await retry(
        () => http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': status}),
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );
      print(
          'Updating message status for messageId $messageId to $status: Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 && mounted && !_isDisposed) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg['Id'] == messageId);
          if (index != -1) {
            _messages[index]['Status'] = status;
            print(
                'Updated status in _messages at index $index: ${_messages[index]}');
          } else {
            print(
                'MessageId $messageId not found in _messages, reloading messages...');
            _loadMessages();
          }
        });
        _triggerSaveMessages();
        if (mounted && !_isDisposed) {
          setState(() => _errorMessage = null);
        }
      } else if (mounted && !_isDisposed) {
        setState(() =>
            _errorMessage = 'Gagal memperbarui status pesan: ${response.body}');
      }
    } catch (e) {
      print('Error updating message status for messageId $messageId: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Gagal memperbarui status pesan: $e');
      }
    }
  }

  Map<String, String> _formatTimestamp(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      print('Warning: timeString is null or empty');
      return {'time': '--:--', 'date': 'Unknown Date'};
    }

    print('Parsing timestamp: $timeString');
    try {
      final dateTime = DateTime.parse(timeString).toLocal();
      final now = DateTime.now();
      final isToday = dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day;
      return {
        'time':
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
        'date':
            isToday ? '' : DateFormat('dd MMM yyyy', 'id_ID').format(dateTime),
      };
    } catch (e) {
      try {
        final formatter = DateFormat('dd MMMM yyyy HH.mm', 'id_ID');
        final dateTime = formatter.parseLoose(timeString).toLocal();
        final now = DateTime.now();
        final isToday = dateTime.year == now.year &&
            dateTime.month == now.month &&
            dateTime.day == now.day;
        return {
          'time':
              "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
          'date': isToday
              ? ''
              : DateFormat('dd MMM yyyy', 'id_ID').format(dateTime),
        };
      } catch (e) {
        print('Error parsing timestamp: $timeString, Error: $e');
        return {'time': '--:--', 'date': 'Unknown Date'};
      }
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
              child: opponent != null && opponent!['ProfilePhoto'] != null
                  ? Image.network(
                      opponent!['ProfilePhoto'].toString(),
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.grey),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent != null
                      ? opponent!['Name']?.toString() ?? 'N/A'
                      : 'Chat',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  opponent != null
                      ? opponent!['Department']?.toString() ?? ''
                      : '',
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/chat_background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: Column(
              children: [
                if (_showConnectedMessage)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        'Terhubung',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['SenderId'] == idEmployee;
                      final message =
                          msg['Message']?.toString() ?? '[Pesan kosong]';
                      final sender = msg['Sender'] is Map
                          ? Map<String, dynamic>.from(msg['Sender'] as Map)
                          : {};
                      print('Rendering sender data for msg $index: $sender');
                      final senderName = sender['EmployeeName']?.toString() ??
                          (opponent != null &&
                                  msg['SenderId'] == opponent!['Id']
                              ? opponent!['Name']?.toString() ?? 'Unknown'
                              : 'Unknown');
                      final formattedTime =
                          msg['FormattedTime']?.toString() ?? '--:--';
                      final formattedDate =
                          msg['FormattedDate']?.toString() ?? '';
                      final status = msg['Status']?.toString() ?? 'Mengirim';
                      print(
                          'Rendering message $index: isMe=$isMe, messageId=${msg['Id']}, status=$status');

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                margin: EdgeInsets.only(
                                  left: isMe ? 50 : 8,
                                  right: isMe ? 8 : 50,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFFE1FFC7)
                                      : Colors.white,
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
                                          formattedDate.isNotEmpty
                                              ? '$formattedDate $formattedTime'
                                              : formattedTime,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (isMe)
                                          Icon(
                                            status == 'Dibaca'
                                                ? Icons.done_all
                                                : status == 'Terkirim'
                                                    ? Icons.done
                                                    : Icons.access_time,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          if (mounted && !_isDisposed) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
  