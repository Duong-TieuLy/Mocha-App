import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/chat/message_api.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/chat/chat_list_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final String status;
  final String conversationId;
  final String currentUserId;
  final Map<String, String>? extraHeaders;
  final Function(String conversationId, String lastMessage, {bool isTyping})? onUpdateChatPreview;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.avatar,
    this.status = 'Online',
    required this.conversationId,
    required this.currentUserId,
    this.extraHeaders,
    this.onUpdateChatPreview,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  bool _isLoading = true;
  String? _loadError;
  FlutterSoundRecorder? _recorder;

  Timer? _pollTimer;
  bool _isPolling = false;

  Timer? _typingTimer;
  bool _otherUserIsTyping = false;

  // ⭐ THÊM: Biến theo dõi xem đã có tin nhắn được gửi chưa
  bool _hasMessageBeenSent = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadHistory();
    _startPolling();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission not granted');
      return;
    }
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder?.closeRecorder();
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      _sendTypingStatus(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _sendTypingStatus(false);
      });
    }
  }

  void _sendTypingStatus(bool isTyping) {
    // ⭐ CHỈ gửi typing status nếu ĐÃ có ít nhất 1 tin nhắn được gửi
    if (_hasMessageBeenSent) {
      widget.onUpdateChatPreview?.call(widget.conversationId, '', isTyping: true);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isPolling && mounted) {
        await _loadHistoryQuietly();
      }
    });
  }

  Future<void> _loadHistoryQuietly() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final rawList = await MessageApi.getMessages(
        conversationId: widget.conversationId,
        extraHeaders: widget.extraHeaders,
      );

      final pendingMessages = messages.where((m) => m['pending'] == true).toList();

      final mapped = rawList.map((m) {
        final senderId = m['senderId'] ?? m['sender_id'] ?? m['sender'] ?? m['from'];
        final text = m['content'] ?? m['text'] ?? m['body'] ?? m['message'] ?? '';
        final created = m['createdAt'] ?? m['created_at'] ?? m['timestamp'] ?? m['time'];
        final id = m['id'] ?? m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        final status = (m['status'] ?? 'delivered').toString().toLowerCase();
        final isTyping = m['isTyping'] ?? false;

        return {
          'id': id,
          'text': text,
          'senderId': senderId,
          'createdAt': created,
          'isSent': senderId.toString() == widget.currentUserId.toString(),
          'status': status,
          'isTyping': isTyping,
        };
      }).toList();

      mapped.addAll(pendingMessages);

      mapped.sort((a, b) {
        final t1 = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final t2 = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return t1.compareTo(t2);
      });

      final hasTypingUser = rawList.any((m) =>
      (m['isTyping'] == true || m['typing'] == true) &&
          (m['senderId'] ?? m['sender_id']) != widget.currentUserId
      );

      if (mounted) {
        final shouldScroll = _scrollController.hasClients &&
            _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100;

        setState(() {
          messages = mapped;
          _otherUserIsTyping = hasTypingUser;
        });

        if (shouldScroll) {
          _scrollToBottom();
        }

        // ⭐ CHỈ UPDATE PREVIEW NẾU ĐÃ CÓ TIN NHẮN
        if (messages.isNotEmpty && _hasMessageBeenSent) {
          final lastMessage = messages.last;
          widget.onUpdateChatPreview?.call(
            widget.conversationId,
            lastMessage['text'] ?? '',
            isTyping: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Quiet load failed: $e');
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final rawList = await MessageApi.getMessages(
        conversationId: widget.conversationId,
        extraHeaders: widget.extraHeaders,
      );

      final pendingMessages = messages.where((m) => m['pending'] == true).toList();

      final mapped = rawList.map((m) {
        final senderId = m['senderId'] ?? m['sender_id'] ?? m['sender'] ?? m['from'];
        final text = m['content'] ?? m['text'] ?? m['body'] ?? m['message'] ?? '';
        final created = m['createdAt'] ?? m['created_at'] ?? m['timestamp'] ?? m['time'];
        final id = m['id'] ?? m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        final status = (m['status'] ?? 'delivered').toString().toLowerCase();

        return {
          'id': id,
          'text': text,
          'senderId': senderId,
          'createdAt': created,
          'isSent': senderId.toString() == widget.currentUserId.toString(),
          'status': status,
        };
      }).toList();

      mapped.addAll(pendingMessages);

      mapped.sort((a, b) {
        final t1 = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final t2 = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return t1.compareTo(t2);
      });

      setState(() {
        messages = mapped;
        _isLoading = false;
        _loadError = null;
      });

      // ⭐ KHÔNG GỌI onUpdateChatPreview khi load history lần đầu
      // Chat preview sẽ chỉ được tạo khi user GỬI TIN NHẮN
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 📖 Loaded ${messages.length} messages');
      debugPrint('║ 🚫 NOT updating chat preview (waiting for first message)');
      debugPrint('╚═══════════════════════════════════════╝');

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      debugPrint('Load history failed: $e\n$st');
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
        messages = [];
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    _sendTypingStatus(false);

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final optimistic = {
      'id': tempId,
      'text': text,
      'senderId': widget.currentUserId,
      'isSent': true,
      'status': 'sent',
      'createdAt': DateTime.now().toIso8601String(),
      'pending': true,
    };

    setState(() {
      messages.add(optimistic);
      _messageController.clear();
    });

    _scrollToBottom();

    // ⭐ QUAN TRỌNG: Đánh dấu đã gửi tin nhắn + gọi callback
    debugPrint('╔═══════════════════════════════════════╗');
    debugPrint('║ 💬 FIRST MESSAGE SENT                 ║');
    debugPrint('║ ✅ Creating chat preview now          ║');
    debugPrint('╚═══════════════════════════════════════╝');

    _hasMessageBeenSent = true;
    widget.onUpdateChatPreview?.call(widget.conversationId, text, isTyping: false);

    try {
      final response = await MessageApi.sendMessage({
        'conversationId': widget.conversationId,
        'senderId': widget.currentUserId,
        'content': text,
        'type': 'text',
      }, tempId: tempId, extraHeaders: widget.extraHeaders);

      if (response['success'] == true && response['message'] != null) {
        final saved = Map<String, dynamic>.from(response['message'] as Map);
        final returnedTempId = response['tempId'] ?? tempId;

        final uiSaved = {
          'id': saved['id'],
          'text': saved['content'] ?? saved['text'] ?? '',
          'senderId': saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId,
          'createdAt': saved['createdAt'] ?? saved['created_at'],
          'isSent': (saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId) == widget.currentUserId,
          'status': saved['status'] != null ? saved['status'].toString().toLowerCase() : 'delivered',
        };

        setState(() {
          final idx = messages.indexWhere((m) => m['id'] == returnedTempId);
          if (idx != -1) {
            messages[idx] = uiSaved;
          } else {
            messages.add(uiSaved);
          }
        });

        _scrollToBottom();

        // ⭐ Update lại với message từ server
        widget.onUpdateChatPreview?.call(widget.conversationId, uiSaved['text'], isTyping: false);
      } else {
        _markFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Failed to send message: $e");
      _markFailed(tempId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message")),
        );
      }
    }
  }

  void _markFailed(String tempId) {
    setState(() {
      final idx = messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) {
        messages[idx]['status'] = 'failed';
        messages[idx].remove('pending');
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: AssetImage(widget.avatar),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(
                    _otherUserIsTyping ? 'Typing...' : widget.status,
                    style: TextStyle(
                        color: _otherUserIsTyping ? Colors.blue : Colors.green,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBodyContent()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load messages: $_loadError', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (_otherUserIsTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _otherUserIsTyping) {
          return _buildTypingIndicator();
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No messages yet', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
              ],
            ),
          );
        }

        final msg = messages[index];
        return msg["isSent"] == true ? _buildSentMessage(msg) : _buildReceivedMessage(msg);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBouncingDot(delay: 0),
            const SizedBox(width: 4),
            _buildBouncingDot(delay: 200),
            const SizedBox(width: 4),
            _buildBouncingDot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingDot({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -8 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () {}),
                GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onTap: () {
                        if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: _toggleEmojiPicker,
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
              ],
            ),
            Offstage(
              offstage: !_showEmojiPicker,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text += emoji.emoji;
                    _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length));
                  },
                  config: const Config(columns: 7, emojiSizeMax: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)),
        child: Text(msg["text"], style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildSentMessage(Map<String, dynamic> msg) {
    Icon statusIcon;
    Widget? errorText;

    switch (msg["status"]) {
      case "seen":
        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.green);
        break;
      case "delivered":
        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.white70);
        break;
      case "failed":
        statusIcon = const Icon(Icons.error, size: 16, color: Colors.red);
        errorText = const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text("Failed to send", style: TextStyle(fontSize: 10, color: Colors.red)),
        );
        break;
      default:
        statusIcon = const Icon(Icons.done, size: 16, color: Colors.white70);
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(msg["text"] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(width: 5),
                statusIcon,
              ],
            ),
          ),
          if (errorText != null) errorText,
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_recorder == null) return;
    await _recorder!.startRecorder(toFile: 'audio.aac');
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) return;
    final path = await _recorder!.stopRecorder();
    setState(() => _isRecording = false);
    if (path != null) debugPrint('Recorded audio file: $path');
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) FocusScope.of(context).unfocus();
    });
  }
}