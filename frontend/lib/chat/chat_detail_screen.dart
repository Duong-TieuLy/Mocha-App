import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/chat/message_api.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'chat_cache.dart';

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
  final FocusNode _messageFocusNode = FocusNode();
  List<Map<String, dynamic>> messages = [];
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  bool _isLoading = true;
  String? _loadError;
  FlutterSoundRecorder? _recorder;
  final ImagePicker _imagePicker = ImagePicker();

  String formatMessageTime(dynamic createdAt) {
    if (createdAt == null) return '';
    DateTime dt;

    if (createdAt is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else if (createdAt is String) {
      try {
        dt = DateTime.parse(createdAt);
      } catch (_) {
        return '';
      }
    } else {
      return '';
    }

    dt = dt.toLocal();
    return DateFormat('HH:mm').format(dt);
  }

  Timer? _pollTimer;
  bool _isPolling = false;

  Timer? _typingTimer;
  bool _otherUserIsTyping = false;

  bool _hasMessageBeenSent = false;

  @override
  void initState() {
    super.initState();
    messages = ChatCache.instance.getMessages(widget.conversationId);

    _initRecorder();
    _loadHistory();
    _startPolling();
    _messageController.addListener(_onTextChanged);

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
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
    _messageFocusNode.dispose();
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
        final type = m['type'] ?? 'text'; // ✅ Lấy type

        return {
          'id': id,
          'text': text,
          'content': text,
          'senderId': senderId,
          'createdAt': created,
          'isSent': senderId.toString() == widget.currentUserId.toString(),
          'status': status,
          'isTyping': isTyping,
          'type': type, // ✅ Thêm type
          'imageUrl': m['imageUrl'] ?? m['image_url'], // ✅ Thêm imageUrl nếu có
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

        if (messages.isNotEmpty && _hasMessageBeenSent) {
          final lastMessage = messages.last;

          // ✅ Format message based on type
          String displayMessage;
          final messageType = lastMessage['type'] ?? 'text';
          final content = lastMessage['text'] ?? lastMessage['content'] ?? '';

          if (messageType == 'image') {
            displayMessage = '📷 Ảnh';
          } else if (messageType == 'audio') {
            displayMessage = '🎤 Tin nhắn thoại';
          } else {
            displayMessage = content;
          }

          widget.onUpdateChatPreview?.call(
            widget.conversationId,
            displayMessage,
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
        final type = m['type'] ?? 'text'; // ✅ Lấy type

        return {
          'id': id,
          'text': text,
          'content': text,
          'senderId': senderId,
          'createdAt': created,
          'isSent': senderId.toString() == widget.currentUserId.toString(),
          'status': status,
          'type': type, // ✅ Thêm type
          'imageUrl': m['imageUrl'] ?? m['image_url'], // ✅ Thêm imageUrl nếu có
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

      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 📖 Loaded ${messages.length} messages');
      debugPrint('║ 🔄 Updating chat preview with last message');
      debugPrint('╚═══════════════════════════════════════╝');

      if (messages.isNotEmpty) {
        final lastMessage = messages.last;

        // ✅ Format message based on type
        String displayMessage;
        final messageType = lastMessage['type'] ?? 'text';
        final content = lastMessage['content'] ?? lastMessage['text'] ?? '';

        if (messageType == 'image') {
          displayMessage = '📷 Ảnh';
        } else if (messageType == 'audio') {
          displayMessage = '🎤 Tin nhắn thoại';
        } else {
          displayMessage = content;
        }

        widget.onUpdateChatPreview?.call(
          widget.conversationId,
          displayMessage,
          isTyping: false,
        );
      }

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
      'content': text,
      'senderId': widget.currentUserId,
      'isSent': true,
      'status': 'sent',
      'createdAt': DateTime.now().toIso8601String(),
      'pending': true,
      'type': 'text',
    };

    setState(() {
      messages.add(optimistic);
      _messageController.clear();
    });

    _scrollToBottom();

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
          'content': saved['content'] ?? saved['text'] ?? '',
          'senderId': saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId,
          'createdAt': saved['createdAt'] ?? saved['created_at'],
          'isSent': (saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId) == widget.currentUserId,
          'status': saved['status'] != null ? saved['status'].toString().toLowerCase() : 'delivered',
          'type': 'text',
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

  Future<void> _deleteMessageLocally(String messageId) async {
    try {
      setState(() {
        messages.removeWhere((m) => m['id'] == messageId);
      });

      final success = await MessageApi.deleteMessage(
        messageId,
        extraHeaders: widget.extraHeaders,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã xóa tin nhắn ở phía bạn"),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
        debugPrint('✅ Deleted message locally: $messageId');
      } else {
        debugPrint("⚠️ API delete failed, reloading messages...");
        await _loadHistoryQuietly();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Không thể xóa tin nhắn trên server"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to delete message locally: $e");
      await _loadHistoryQuietly();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi khi xóa tin nhắn"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recallMessage(String messageId) async {
    try {
      setState(() {
        final idx = messages.indexWhere((m) => m['id'] == messageId);
        if (idx != -1) {
          messages[idx]['text'] = '📵 Tin nhắn đã được thu hồi';
          messages[idx]['recalled'] = true;
        }
      });

      final success = await MessageApi.recallMessage(
        messageId,
        extraHeaders: widget.extraHeaders,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã thu hồi tin nhắn"),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
        debugPrint('✅ Recalled message: $messageId');

        widget.onUpdateChatPreview?.call(
          widget.conversationId,
          '📵 Tin nhắn đã được thu hồi',
          isTyping: false,
        );
      } else {
        debugPrint("⚠️ API recall failed, reloading messages...");
        await _loadHistoryQuietly();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Không thể thu hồi tin nhắn"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to recall message: $e");
      await _loadHistoryQuietly();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi khi thu hồi tin nhắn"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteOptions(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tùy chọn tin nhắn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageLocally(msg['id']);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red[700], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xóa ở phía bạn',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tin nhắn chỉ bị xóa với bạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (msg['isSent'] == true) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _recallMessage(msg['id']);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Colors.orange[700], size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thu hồi tin nhắn',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Xóa tin nhắn ở cả hai phía',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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

        return GestureDetector(
          onLongPress: () => _showDeleteOptions(msg),
          child: msg["isSent"] == true
              ? _buildSentMessage(msg)
              : _buildReceivedMessage(msg),
        );
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
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  onPressed: _pickImage,
                ),
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
                  child: GestureDetector(
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() => _showEmojiPicker = false);
                      }
                      _messageFocusNode.requestFocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                        autofocus: false,
                        enableInteractiveSelection: true,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: Colors.grey
                  ),
                  onPressed: _toggleEmojiPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
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

  // ✅ FIXED: _buildReceivedMessage
  Widget _buildReceivedMessage(Map<String, dynamic> msg) {
    final isRecalled = msg['recalled'] == true;
    final createdAt = formatMessageTime(msg['createdAt']);
    final isImage = msg['type'] == 'image';
    final imageUrl = msg['imageUrl'] ?? msg['content'] ?? '';

    return Align(
        alignment: Alignment.centerLeft,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRecalled ? Colors.grey[200] : (isImage ? Colors.transparent : Colors.grey[300]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: isImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              'http://localhost:8081${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}',
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error loading image: $error');
                debugPrint('❌ Image URL: http://localhost:8081$imageUrl');
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
              : Text(
            msg["text"] ?? msg["content"] ?? '',
            style: TextStyle(
              fontSize: 16,
              fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
              color: isRecalled ? Colors.grey[600] : Colors.black,
            ),
          ),
        ),
              Text(
                createdAt,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
        ),
    );
  }

  // ✅ FIXED: _buildSentMessage
  Widget _buildSentMessage(Map<String, dynamic> msg) {
    final isRecalled = msg['recalled'] == true;
    final createdAt = formatMessageTime(msg['createdAt']);
    final isImage = msg['type'] == 'image';
    final isPending = msg['pending'] == true;
    final imageUrl = msg['imageUrl'] ?? msg['content'] ?? '';

    Widget statusIcon;
    Widget? errorText;

    if (isRecalled) {
      statusIcon = const Icon(Icons.restore, size: 16, color: Colors.white70);
    } else {
      switch (msg["status"]) {
        case "seen":
          statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.green);
          break;
        case "delivered":
          statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.white70);
          break;
        case "sending":
          statusIcon = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          );
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
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRecalled ? Colors.grey[400] : (isImage ? Colors.transparent : Colors.blue),
              borderRadius: BorderRadius.circular(15),
            ),
            child: isImage
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('['))
                    Image.network(
                      'http://localhost:8081${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}',
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Error loading image: $error');
                        debugPrint('❌ Image URL: http://localhost:8081$imageUrl');
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  else if (kIsWeb && msg['imageBytes'] != null)
                    Image.memory(
                      msg['imageBytes'] as Uint8List,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                  else if (!kIsWeb && msg['imageFile'] != null)
                      Image.file(
                        msg['imageFile'] as File,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: statusIcon,
                    ),
                  ),
                ],
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    msg["text"] ?? msg["content"] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: isRecalled ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                statusIcon,
              ],
            ),
          ),
          Text(
            createdAt,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
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
      if (_showEmojiPicker) {
        _messageFocusNode.unfocus();
      } else {
        _messageFocusNode.requestFocus();
      }
    });
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (mounted) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          _showImagePreviewWeb(bytes, pickedFile);
        } else {
          _showImagePreview(File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  void _showImagePreviewWeb(Uint8List imageBytes, XFile pickedFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(imageBytes),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendImageMessageWeb(imageBytes, pickedFile);
                    },
                    child: const Text('Gửi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(imageFile),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendImageMessage(imageFile);
                    },
                    child: const Text('Gửi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImageMessage(File imageFile) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final optimistic = {
      'id': tempId,
      'text': '[Đang gửi ảnh...]',
      'content': '[Đang gửi ảnh...]',
      'senderId': widget.currentUserId,
      'isSent': true,
      'status': 'sending',
      'createdAt': DateTime.now().toIso8601String(),
      'pending': true,
      'type': 'image',
      'imageFile': imageFile,
    };

    setState(() {
      messages.add(optimistic);
    });

    _scrollToBottom();

    _hasMessageBeenSent = true;
    widget.onUpdateChatPreview?.call(widget.conversationId, '📷 Ảnh', isTyping: false);

    try {
      final response = await MessageApi.sendImageMessage(
        conversationId: widget.conversationId,
        senderId: widget.currentUserId,
        imageFile: imageFile,
        tempId: tempId,
        extraHeaders: widget.extraHeaders,
      );

      if (response['success'] == true && response['message'] != null) {
        final saved = Map<String, dynamic>.from(response['message'] as Map);
        final returnedTempId = response['tempId'] ?? tempId;

        final uiSaved = {
          'id': saved['id'],
          'text': saved['content'] ?? saved['text'] ?? '',
          'content': saved['content'] ?? saved['text'] ?? '',
          'imageUrl': response['imageUrl'] ?? saved['content'],
          'senderId': saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId,
          'createdAt': saved['createdAt'] ?? saved['created_at'],
          'isSent': (saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId) == widget.currentUserId,
          'status': saved['status'] != null ? saved['status'].toString().toLowerCase() : 'delivered',
          'type': 'image',
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
        widget.onUpdateChatPreview?.call(widget.conversationId, '📷 Ảnh', isTyping: false);
      } else {
        _markFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Failed to send image: $e");
      _markFailed(tempId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể gửi ảnh")),
        );
      }
    }
  }

  Future<void> _sendImageMessageWeb(Uint8List imageBytes, XFile pickedFile) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final optimistic = {
      'id': tempId,
      'text': '[Đang gửi ảnh...]',
      'content': '[Đang gửi ảnh...]',
      'senderId': widget.currentUserId,
      'isSent': true,
      'status': 'sending',
      'createdAt': DateTime.now().toIso8601String(),
      'pending': true,
      'type': 'image',
      'imageBytes': imageBytes,
    };

    setState(() {
      messages.add(optimistic);
    });

    _scrollToBottom();

    _hasMessageBeenSent = true;
    widget.onUpdateChatPreview?.call(widget.conversationId, '📷 Ảnh', isTyping: false);

    try {
      final response = await MessageApi.sendImageMessage(
        conversationId: widget.conversationId,
        senderId: widget.currentUserId,
        imageBytes: imageBytes,
        fileName: pickedFile.name,
        tempId: tempId,
        extraHeaders: widget.extraHeaders,
      );

      if (response['success'] == true && response['message'] != null) {
        final saved = Map<String, dynamic>.from(response['message'] as Map);
        final returnedTempId = response['tempId'] ?? tempId;

        final uiSaved = {
          'id': saved['id'],
          'text': saved['content'] ?? saved['text'] ?? '',
          'content': saved['content'] ?? saved['text'] ?? '',
          'imageUrl': response['imageUrl'] ?? saved['content'],
          'senderId': saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId,
          'createdAt': saved['createdAt'] ?? saved['created_at'],
          'isSent': (saved['senderId'] ?? saved['sender_id'] ?? widget.currentUserId) == widget.currentUserId,
          'status': saved['status'] != null ? saved['status'].toString().toLowerCase() : 'delivered',
          'type': 'image',
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
        widget.onUpdateChatPreview?.call(widget.conversationId, '📷 Ảnh', isTyping: false);
      } else {
        _markFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Failed to send image: $e");
      _markFailed(tempId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể gửi ảnh")),
        );
      }
    }
  }
}