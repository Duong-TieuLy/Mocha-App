import 'dart:async';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import 'package:frontend/chat/message_api.dart';
import 'package:frontend/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPreview {
  final String conversationId;
  final String name;
  final String avatar;
  final String userId;
  String lastMessage;
  String time;
  bool isTyping;
  int unreadCount;
  DateTime? lastMessageTime;
  bool isLocalUpdate;

  ChatPreview({
    required this.conversationId,
    required this.name,
    required this.avatar,
    required this.userId,
    this.lastMessage = '',
    this.time = '',
    this.isTyping = false,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.isLocalUpdate = false,
  });

  ChatPreview copyWith({
    String? lastMessage,
    String? time,
    bool? isTyping,
    int? unreadCount,
    DateTime? lastMessageTime,
    bool? isLocalUpdate,
  }) {
    return ChatPreview(
      conversationId: conversationId,
      name: name,
      avatar: avatar,
      userId: userId,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      isTyping: isTyping ?? this.isTyping,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isLocalUpdate: isLocalUpdate ?? this.isLocalUpdate,
    );
  }
}

class ChatListScreen extends StatefulWidget {
  final String? currentUserId;

  const ChatListScreen({
    super.key,
    this.currentUserId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;
  late String _currentUserId;
  late UserService _userService;

  // ✅ CRITICAL: Thêm biến để ngăn spam requests
  DateTime? _lastApiCall;
  bool _isLoadingFromApi = false;

  Timer? _refreshTimer;
  Timer? _timeUpdateTimer;
  bool _isInChat = false;
  bool _hasInitialized = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _activeConversations = {};

  List<ChatPreview> _friends = [];
  List<ChatPreview> _chats = [];

  List<ChatPreview> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ChatPreview> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((friend) {
      return friend.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadFriendsFromApi() async {
    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 📡 Loading Friends from API           ║');
      debugPrint('║ Current User ID: $_currentUserId      ║');
      debugPrint('╚═══════════════════════════════════════╝');

      final data = await _userService.getFriends(_currentUserId);

      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ ✅ Friends API Response               ║');
      debugPrint('║ Total friends: ${data.length}          ║');

      if (mounted) {
        setState(() {
          _friends = data.map((u) {
            final friend = ChatPreview(
              conversationId: "",
              name: u["fullName"] ?? u["username"] ?? "Unknown",
              avatar: u["photoUrl"] ?? "assets/images/default.png",
              userId: u["firebaseUid"] ?? "unknown",
            );
            debugPrint('║   • ${friend.name} (${friend.userId})');
            return friend;
          }).toList();
        });
      }

      debugPrint('║ ✅ Successfully loaded ${_friends.length} friends');
      debugPrint('╚═══════════════════════════════════════╝');

    } catch (e, stackTrace) {
      debugPrint("╔═══════════════════════════════════════╗");
      debugPrint("║ ❌ Error loading friends              ║");
      debugPrint("║ Error: $e                              ║");
      debugPrint("║ Stack trace:                          ║");
      debugPrint(stackTrace.toString().split('\n').take(3).join('\n'));
      debugPrint("╚═══════════════════════════════════════╝");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load friends: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _chats.length; i++) {
          final chat = _chats[i];
          if (chat.lastMessageTime != null) {
            _chats[i] = chat.copyWith(time: _formatTime(chat.lastMessageTime!));
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      _currentUserId = 'unknown';
    }

    _userService = UserService(baseUrl: 'http://10.0.2.2:8082');

    _initializeData();
    _startAutoRefresh();
    _startTimeUpdateTimer();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 🚀 Initializing App Data              ║');
      debugPrint('║ Current User ID: $_currentUserId      ║');
      debugPrint('╚═══════════════════════════════════════╝');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ ERROR: No Firebase user logged in!');
        return;
      }

      debugPrint('✅ Firebase User logged in:');
      debugPrint('   - UID: ${user.uid}');
      debugPrint('   - Email: ${user.email}');
      debugPrint('   - Display Name: ${user.displayName}');

      await _loadFriendsFromApi();
      await _loadChatsFromApi();

      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ ✅ App Data Initialized               ║');
      debugPrint('║ Friends loaded: ${_friends.length}     ║');
      debugPrint('║ Chats loaded: ${_chats.length}         ║');

      if (_friends.isNotEmpty) {
        debugPrint('║ Friends Details:                      ║');
        for (var friend in _friends) {
          debugPrint('║   • ${friend.name} (${friend.userId})');
        }
      } else {
        debugPrint('║ ⚠️  No friends found!                 ║');
      }

      debugPrint('╚═══════════════════════════════════════╝');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing data: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _searchController.dispose();
    _isLoadingFromApi = false;
    super.dispose();
  }

  // ✅ FIX: Tăng interval từ 5s lên 30s
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isInChat && !_isLoadingFromApi) {
        _loadChatsFromApi(silent: true);
      }
    });
  }

  Future<void> _loadChatsFromApi({bool silent = false, int retryCount = 0}) async {
    if (_isLoadingFromApi) {
      debugPrint('⚠️ Already loading chats, skipping...');
      return;
    }

    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall.inSeconds < 3) {
        debugPrint('⏱️ Rate limited: Only ${timeSinceLastCall.inSeconds}s since last call');
        return;
      }
    }

    _lastApiCall = DateTime.now();
    _isLoadingFromApi = true;

    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      if (!silent) {
        debugPrint('╔═══════════════════════════════════════╗');
        debugPrint('║ 🔄 LOADING CHATS FROM API             ║');
        debugPrint('╠═══════════════════════════════════════╣');
        debugPrint('║ Current User: $_currentUserId');
        if (retryCount > 0) {
          debugPrint('║ Retry attempt: $retryCount/3');
        }
      }

      final conversations = await MessageApi.getUserConversations(
        _currentUserId,
        timeoutSeconds: 30,
      );

      if (conversations.isEmpty) {
        if (!silent) {
          debugPrint('║ ℹ️  API returned empty conversations');
        }

        if (!_hasInitialized && _chats.isEmpty) {
          debugPrint('║ 🆕 First time - starting with empty chat list');
          if (mounted) {
            setState(() {
              _chats = [];
              _hasInitialized = true;
            });
          }
        } else {
          debugPrint('║ ✅ API empty but KEEPING existing local chats (${_chats.length} chats)');
        }

        if (!silent) {
          debugPrint('╚═══════════════════════════════════════╝');
        }
        return;
      }

      // ✅ FIX: Explicitly type and use complete mapping
      final List<ChatPreview> apiChats = [];

      for (var conv in conversations) {
        try {
          // Get other user ID
          final participants = conv['participants'] as List?;
          final otherUserId = participants?.firstWhere(
            (p) => p != _currentUserId,
            orElse: () => 'unknown',
          ) ?? 'unknown';

          // Find friend info
          final friend = _friends.firstWhere(
            (f) => f.userId == otherUserId,
            orElse: () => ChatPreview(
              conversationId: conv['conversationId'] ?? '',
              name: 'Unknown',
              avatar: 'assets/images/default.png',
              userId: otherUserId,
            ),
          );

          // Get message info
          final lastMessage = conv['lastMessage'] as Map<String, dynamic>?;
          final messageType = lastMessage?['type']?.toString() ?? 'text';
          final rawContent = lastMessage?['content']?.toString() ?? '';

          String displayMessage;
          if (messageType == 'image') {
            displayMessage = '📷 Ảnh';
          } else if (messageType == 'audio') {
            displayMessage = '🎤 Tin nhắn thoại';
          } else {
            displayMessage = rawContent;
          }

          // Parse timestamp
          final timestamp = lastMessage?['createdAt'] ??
              lastMessage?['timestamp'] ??
              lastMessage?['created_at'];

          DateTime? lastMsgTime;
          if (timestamp != null) {
            try {
              lastMsgTime = DateTime.parse(timestamp.toString());
            } catch (e) {
              lastMsgTime = null;
            }
          }

          // Create ChatPreview
          final chat = ChatPreview(
            conversationId: conv['conversationId'] ?? '',
            name: friend.name,
            avatar: friend.avatar,
            userId: friend.userId,
            lastMessage: displayMessage,
            time: lastMsgTime != null ? _formatTime(lastMsgTime) : '',
            lastMessageTime: lastMsgTime,
            unreadCount: conv['unreadCount'] ?? 0,
          );

          apiChats.add(chat);
        } catch (e) {
          debugPrint('⚠️ Error parsing conversation: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _chats = apiChats;
          _hasInitialized = true;
        });
      }

      if (!silent) {
        debugPrint('║ ✅ Loaded ${apiChats.length} chats from API');
        debugPrint('╚═══════════════════════════════════════╝');
      }

    } on TimeoutException catch (e) {
      debugPrint('❌ TIMEOUT (attempt ${retryCount + 1}/3): $e');

      if (retryCount < 2 && mounted) {
        final waitSeconds = (retryCount + 1) * 2;
        debugPrint('⏳ Retrying in ${waitSeconds}s...');

        await Future.delayed(Duration(seconds: waitSeconds));

        _isLoadingFromApi = false;
        await _loadChatsFromApi(silent: silent, retryCount: retryCount + 1);
        return;
      }

      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Cannot connect to server. Using cached data.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Error loading chats: $e');

      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load chats'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isLoadingFromApi = false;
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshChats() async {
    await _loadFriendsFromApi();
    await _loadChatsFromApi();
  }

  Future<void> _openChatWithFriend(ChatPreview friend) async {
    final userIds = [_currentUserId, friend.userId]..sort();
    final conversationId = '${userIds[0]}-${userIds[1]}-chat';

    debugPrint('═══════════════════════════════════════');
    debugPrint('🆕 Opening chat with friend: ${friend.name}');
    debugPrint('   Friend userId: ${friend.userId}');
    debugPrint('   ConversationId: $conversationId');
    debugPrint('═══════════════════════════════════════');

    final existingChatIndex = _chats.indexWhere((c) => c.conversationId == conversationId);

    if (existingChatIndex == -1) {
      debugPrint('║ 🔍 Chat not in list, checking for existing messages...');

      try {
        final messages = await MessageApi.getMessages(conversationId: conversationId);

        if (messages.isNotEmpty) {
          debugPrint('║ 📬 Found ${messages.length} existing messages!');

          final lastMessage = messages.last;
          final messageType = lastMessage['type']?.toString() ?? 'text';

          String displayMessage;
          if (messageType == 'image') {
            displayMessage = '📷 Ảnh';
          } else if (messageType == 'audio') {
            displayMessage = '🎤 Tin nhắn thoại';
          } else {
            displayMessage = lastMessage['content']?.toString() ?? '';
          }

          final timestamp = lastMessage['createdAt'] ??
              lastMessage['timestamp'] ??
              lastMessage['created_at'];

          DateTime lastMsgTime = DateTime.now();
          if (timestamp != null) {
            try {
              lastMsgTime = DateTime.parse(timestamp.toString());
            } catch (e) {
              lastMsgTime = DateTime.now();
            }
          }

          final newChat = ChatPreview(
            conversationId: conversationId,
            name: friend.name,
            avatar: friend.avatar,
            userId: friend.userId,
            lastMessage: displayMessage,
            time: _formatTime(lastMsgTime),
            lastMessageTime: lastMsgTime,
            isTyping: false,
            unreadCount: 0,
            isLocalUpdate: false,
          );

          setState(() {
            _chats.insert(0, newChat);
            _activeConversations.add(conversationId);
          });

          debugPrint('║ ✅ Chat added to list with existing messages!');
          debugPrint('║ 💬 Last message: "$displayMessage"');
        } else {
          debugPrint('║ 📭 No existing messages found');
          debugPrint('║ 🚫 NOT creating chat preview yet');
          debugPrint('║ 💡 Chat preview will be created when user sends first message');
        }
      } catch (e) {
        debugPrint('║ ⚠️ Error loading messages: $e');
        debugPrint('║ 🚫 NOT creating chat preview (will wait for first message)');
      }
    } else {
      debugPrint('║ ✅ Chat already exists in list at index $existingChatIndex');
    }

    debugPrint('═══════════════════════════════════════');

    setState(() => _isInChat = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          name: friend.name,
          avatar: friend.avatar,
          status: 'Online',
          conversationId: conversationId,
          currentUserId: _currentUserId,
          onUpdateChatPreview: (id, msg, {isTyping = false, DateTime? messageTime}) {
            if (!isTyping && msg.isNotEmpty) {
              _updateChatPreview(id, msg, messageTime: messageTime);
            }
          },
        ),
      ),
    );

    setState(() => _isInChat = false);
    await _loadChatsFromApi(silent: true);
  }

  void _updateChatPreview(String conversationId, String lastMessage, {bool isTyping = false, DateTime? messageTime}) {
    if (conversationId.isEmpty) return;

    String displayMessage = lastMessage;
    if (lastMessage.startsWith('http') && (lastMessage.contains('.jpg') ||
        lastMessage.contains('.jpeg') || lastMessage.contains('.png') ||
        lastMessage.contains('.gif') || lastMessage.contains('.webp') ||
        lastMessage.contains('cloudinary') || lastMessage.contains('imgur'))) {
      displayMessage = '📷 Ảnh';
    } else if (lastMessage.startsWith('http') && (lastMessage.contains('.mp3') ||
        lastMessage.contains('.wav') || lastMessage.contains('.m4a') ||
        lastMessage.contains('.ogg') || lastMessage.contains('audio'))) {
      displayMessage = '🎤 Tin nhắn thoại';
    }

    final now = messageTime ?? DateTime.now();

    debugPrint('╔═══════════════════════════════════════╗');
    debugPrint('║ 🔄 UPDATE CHAT PREVIEW                ║');
    debugPrint('╠═══════════════════════════════════════╣');
    debugPrint('║ ConversationId: $conversationId');
    debugPrint('║ Display Message: "$displayMessage"');
    debugPrint('║ IsTyping: $isTyping');

    setState(() {
      final chatIndex = _chats.indexWhere((c) => c.conversationId == conversationId);

      if (chatIndex != -1) {
        debugPrint('║ ✅ Chat EXISTS in list at index $chatIndex');

        if (!isTyping && lastMessage.isNotEmpty) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(
            lastMessage: displayMessage,
            lastMessageTime: now,
            time: _formatTime(now),
            isTyping: false,
            isLocalUpdate: true,
          );

          final updatedChat = _chats.removeAt(chatIndex);
          _chats.insert(0, updatedChat);
          debugPrint('║ ✅ Chat updated and moved to top: ${updatedChat.name}');
        } else if (isTyping) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(isTyping: true);
          debugPrint('║ 💬 Chat updated with typing status');
        }
      } else {
        debugPrint('║ 🆕 Chat NOT in list yet');

        final shouldCreatePreview = !isTyping && lastMessage.isNotEmpty;

        if (shouldCreatePreview) {
          debugPrint('║ ✅ CREATING NEW CHAT PREVIEW!');

          _activeConversations.add(conversationId);

          final parts = conversationId.split('-');
          String? otherUserId;

          if (parts.length >= 2) {
            otherUserId = parts[0] == _currentUserId ? parts[1] : parts[0];
          }

          if (otherUserId != null) {
            final friend = _friends.firstWhere(
                  (f) => f.userId == otherUserId,
              orElse: () => ChatPreview(
                conversationId: conversationId,
                name: 'Unknown User',
                avatar: 'assets/images/default.png',
                userId: otherUserId!,
              ),
            );

            final newChat = ChatPreview(
              conversationId: conversationId,
              name: friend.name,
              avatar: friend.avatar,
              userId: friend.userId,
              lastMessage: displayMessage,
              time: _formatTime(now),
              lastMessageTime: now,
              isTyping: false,
              unreadCount: 0,
              isLocalUpdate: true,
            );

            _chats.insert(0, newChat);

            debugPrint('║ ✅ NEW CHAT CREATED!');
            debugPrint('║ 👤 Name: ${newChat.name}');
            debugPrint('║ 💬 First message: "$displayMessage"');
          }
        }
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          final chatIndex = _chats.indexWhere((c) => c.conversationId == conversationId);
          if (chatIndex != -1) {
            _chats[chatIndex] = _chats[chatIndex].copyWith(isLocalUpdate: false);
          }
        });
      }
    });

    debugPrint('╚═══════════════════════════════════════╝');
  }

  String _formatTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    if (messageDate == today) {
      final hour = localDateTime.hour;
      final minute = localDateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return 'Yesterday';
    }

    final daysAgo = today.difference(messageDate).inDays;
    if (daysAgo < 7) {
      const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekDays[messageDate.weekday - 1];
    }

    return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
  }

  void _showDeleteChatDialog(ChatPreview chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete your conversation with ${chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog(ChatPreview chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Block ${chat.name}?'),
            const SizedBox(height: 8),
            Text(
              'They won\'t be able to message you or see your profile.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(chat);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatPreview chat) async {
    final deletedChat = chat;
    final deletedIndex = _chats.indexOf(chat);

    _activeConversations.remove(chat.conversationId);

    setState(() {
      _chats.removeWhere((c) => c.conversationId == chat.conversationId);
    });

    try {
      await MessageApi.deleteAllMessages(chat.conversationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat with ${chat.name} deleted'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _activeConversations.add(deletedChat.conversationId);
                setState(() {
                  _chats.insert(deletedIndex, deletedChat);
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      _activeConversations.add(deletedChat.conversationId);
      setState(() {
        _chats.insert(deletedIndex, deletedChat);
      });
    }
  }

  Future<void> _blockUser(ChatPreview chat) async {
    _activeConversations.remove(chat.conversationId);

    setState(() {
      _chats.removeWhere((c) => c.conversationId == chat.conversationId);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${chat.name} has been blocked'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.blue),
            onPressed: _showNewChatDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: _filteredFriends.isEmpty
                ? Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'No friends found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filteredFriends.map((f) => _buildStoryCircle(f)).toList(),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: _buildTab('Chats', isSelected: _selectedTab == 0),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: _buildTab('Groups', isSelected: _selectedTab == 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedTab == 0 ? _buildChatsList() : _buildEmptyFolder(),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }

                                                              void _showNewChatDialog() {
                                                                showDialog(
                                                                  context: context,
                                                                  builder: (context) => AlertDialog(
                                                                    title: const Text('New Chat'),
                                                                    content: const Text(
                                                                      'Feature coming soon!\n\nYou will be able to:\n• Search for users\n• Start new conversations\n• Create group chats',
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () => Navigator.pop(context),
                                                                        child: const Text('OK'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }

                                                              Widget _buildChatsList() {
                                                                if (_isLoading && _chats.isEmpty) {
                                                                  return const Center(child: CircularProgressIndicator());
                                                                }

                                                                final displayChats = _filteredChats;

                                                                if (displayChats.isEmpty && _searchQuery.isNotEmpty) {
                                                                  final matchingFriends = _friends
                                                                      .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                                                      .toList();

                                                                  if (matchingFriends.isNotEmpty) {
                                                                    return ListView.builder(
                                                                      itemCount: matchingFriends.length,
                                                                      itemBuilder: (context, index) {
                                                                        final friend = matchingFriends[index];
                                                                        return ListTile(
                                                                          onTap: () => _openChatWithFriend(friend),
                                                                          leading: CircleAvatar(
                                                                            radius: 28,
                                                                            backgroundColor: Colors.grey[300],
                                                                            backgroundImage: AssetImage(friend.avatar),
                                                                          ),
                                                                          title: Text(
                                                                            friend.name,
                                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                          ),
                                                                          subtitle: Text(
                                                                            'Tap to start chatting',
                                                                            style: TextStyle(
                                                                              color: Colors.grey[500],
                                                                              fontSize: 14,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                          ),
                                                                          trailing: Icon(Icons.chat_bubble_outline, color: Colors.grey[400]),
                                                                        );
                                                                      },
                                                                    );
                                                                  }
                                                                }

                                                                if (displayChats.isEmpty) {
                                                                  return Center(
                                                                    child: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        Icon(
                                                                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline,
                                                                          size: 80,
                                                                          color: Colors.grey[400],
                                                                        ),
                                                                        const SizedBox(height: 16),
                                                                        Text(
                                                                          _searchQuery.isNotEmpty ? 'No results found' : 'No chats yet',
                                                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        if (_searchQuery.isEmpty)
                                                                          Text(
                                                                            'Start a conversation with your friends!',
                                                                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                                                          ),
                                                                        if (_searchQuery.isEmpty) const SizedBox(height: 16),
                                                                        if (_searchQuery.isEmpty)
                                                                          TextButton.icon(
                                                                            onPressed: _refreshChats,
                                                                            icon: const Icon(Icons.refresh),
                                                                            label: const Text('Refresh'),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }

                                                                return RefreshIndicator(
                                                                  onRefresh: _refreshChats,
                                                                  child: ListView.builder(
                                                                    itemCount: displayChats.length,
                                                                    itemBuilder: (context, index) {
                                                                      final chat = displayChats[index];
                                                                      return _buildChatItem(chat);
                                                                    },
                                                                  ),
                                                                );
                                                              }

                                                              Widget _buildEmptyFolder() {
                                                                return Center(
                                                                  child: Column(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      Icon(Icons.folder_open_outlined, size: 100, color: Colors.grey[400]),
                                                                      const SizedBox(height: 20),
                                                                      Text(
                                                                        'Empty Folder',
                                                                        style: TextStyle(
                                                                          fontSize: 24,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 10),
                                                                      Text(
                                                                        'No groups yet',
                                                                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }

                                                              Widget _buildStoryCircle(ChatPreview friend) {
                                                                return GestureDetector(
                                                                  onTap: () => _openChatWithFriend(friend),
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.only(right: 16),
                                                                    child: Column(
                                                                      children: [
                                                                        Container(
                                                                          width: 60,
                                                                          height: 60,
                                                                          decoration: BoxDecoration(
                                                                            shape: BoxShape.circle,
                                                                            border: Border.all(
                                                                              color: Colors.blue,
                                                                              width: 2,
                                                                            ),
                                                                          ),
                                                                          child: ClipOval(
                                                                            child: friend.avatar.startsWith('http')
                                                                                ? Image.network(
                                                                                    friend.avatar,
                                                                                    fit: BoxFit.cover,
                                                                                    errorBuilder: (context, error, stackTrace) {
                                                                                      return CircleAvatar(
                                                                                        backgroundColor: Colors.grey[300],
                                                                                        child: Icon(Icons.person, color: Colors.grey[600]),
                                                                                      );
                                                                                    },
                                                                                  )
                                                                                : Image.asset(
                                                                                    friend.avatar,
                                                                                    fit: BoxFit.cover,
                                                                                    errorBuilder: (context, error, stackTrace) {
                                                                                      return CircleAvatar(
                                                                                        backgroundColor: Colors.grey[300],
                                                                                        child: Icon(Icons.person, color: Colors.grey[600]),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 4),
                                                                        Text(
                                                                          friend.name,
                                                                          style: const TextStyle(fontSize: 12),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              }

                                                              Widget _buildTab(String title, {required bool isSelected}) {
                                                                return Column(
                                                                  children: [
                                                                    Text(
                                                                      title,
                                                                      style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                        color: Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 8),
                                                                    if (isSelected)
                                                                      Container(
                                                                        height: 3,
                                                                        width: 40,
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.blue,
                                                                          borderRadius: BorderRadius.circular(2),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                );
                                                              }

                                                              Widget _buildChatItem(ChatPreview chat) {
                                                                return ListTile(
                                                                  onTap: () async {
                                                                    debugPrint('═══════════════════════════════════════');
                                                                    debugPrint('📱 Opening existing chat with: ${chat.name}');
                                                                    debugPrint('   ConversationId: ${chat.conversationId}');
                                                                    debugPrint('   CurrentUserId: $_currentUserId');
                                                                    debugPrint('═══════════════════════════════════════');

                                                                    setState(() => _isInChat = true);

                                                                    await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => ChatDetailScreen(
                                                                          name: chat.name,
                                                                          avatar: chat.avatar,
                                                                          status: chat.isTyping ? 'Typing...' : 'Online',
                                                                          conversationId: chat.conversationId,
                                                                          currentUserId: _currentUserId,
                                                                          onUpdateChatPreview: _updateChatPreview,
                                                                        ),
                                                                      ),
                                                                    );

                                                                    setState(() => _isInChat = false);
                                                                    await _loadChatsFromApi(silent: true);
                                                                  },
                                                                  leading: CircleAvatar(
                                                                    radius: 28,
                                                                    backgroundColor: Colors.grey[300],
                                                                    backgroundImage: chat.avatar.startsWith('http')
                                                                        ? NetworkImage(chat.avatar)
                                                                        : AssetImage(chat.avatar) as ImageProvider,
                                                                  ),
                                                                  title: Text(
                                                                    chat.name,
                                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                  ),
                                                                  subtitle: Text(
                                                                    chat.lastMessage,
                                                                    style: TextStyle(
                                                                      color: chat.isTyping ? Colors.blue : Colors.grey[600],
                                                                      fontSize: 14,
                                                                      fontStyle: chat.isTyping ? FontStyle.italic : FontStyle.normal,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                  trailing: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Column(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            chat.time,
                                                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                                          ),
                                                                          if (chat.unreadCount > 0)
                                                                            Container(
                                                                              margin: const EdgeInsets.only(top: 4),
                                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.red,
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                              child: Text(
                                                                                chat.unreadCount.toString(),
                                                                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                      PopupMenuButton<String>(
                                                                        icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                                                                        offset: const Offset(0, 40),
                                                                        onSelected: (value) {
                                                                          if (value == 'delete') {
                                                                            _showDeleteChatDialog(chat);
                                                                          } else if (value == 'block') {
                                                                            _showBlockUserDialog(chat);
                                                                          }
                                                                        },
                                                                        itemBuilder: (context) => [
                                                                          const PopupMenuItem(
                                                                            value: 'delete',
                                                                            child: Row(
                                                                              children: [
                                                                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                                                SizedBox(width: 12),
                                                                                Text('Delete Chat', style: TextStyle(color: Colors.red)),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          const PopupMenuItem(
                                                                            value: 'block',
                                                                            child: Row(
                                                                              children: [
                                                                                Icon(Icons.block, color: Colors.orange, size: 20),
                                                                                SizedBox(width: 12),
                                                                                Text('Block User', style: TextStyle(color: Colors.orange)),
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