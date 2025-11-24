import 'dart:async';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import 'package:frontend/chat/message_api.dart';
import 'package:frontend/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/chat/group_api.dart';
import 'package:frontend/chat/create_group_screen.dart';

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
  List<Map<String, dynamic>> _groups = []; // ← Thêm biến này
  bool _isLoadingGroups = false;

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
              avatar: u["photoUrl"] ?? "https://ui-avatars.com/api/?name=Unknown&background=random",
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

  /// Load groups từ API
  Future<void> _loadGroupsFromApi() async {
    if (_isLoadingGroups) return;

    setState(() => _isLoadingGroups = true);

    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 📡 LOADING GROUPS FROM API            ║');
      debugPrint('║ User ID: $_currentUserId              ║');
      debugPrint('╚═══════════════════════════════════════╝');

      final groups = await GroupApi.getUserGroups(_currentUserId);

      if (mounted) {
        setState(() {
          // ✅ Đảm bảo ID có prefix 'group_'
          _groups = groups.map((group) {
            final id = group['id'] ?? group['conversationId'] ?? '';
            if (!id.startsWith('group_')) {
              group['id'] = 'group_$id';
            }
            return group;
          }).toList();
        });
      }

      debugPrint('✅ Loaded ${_groups.length} groups');

      if (_groups.isNotEmpty) {
        for (var group in _groups) {
          debugPrint('  • ${group['name']} (ID: ${group['id']}, ${(group['memberIds'] as List?)?.length ?? 0} members)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingGroups = false);
      }
    }
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
      await _loadGroupsFromApi(); // ← THÊM DÒNG NÀY

      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ ✅ App Data Initialized               ║');
      debugPrint('║ Friends loaded: ${_friends.length}     ║');
      debugPrint('║ Chats loaded: ${_chats.length}         ║');
      debugPrint('║ Groups loaded: ${_groups.length}       ║'); // ← THÊM DÒNG NÀY

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

      // ✅ THÊM FILTER NÀY: Chỉ lấy 1-1 chat, loại bỏ group chat
      final oneOnOneConversations = conversations.where((conv) {
        final conversationId = conv['conversationId'] ?? '';
        final isGroupChat = conversationId.startsWith('group_');

        if (isGroupChat && !silent) {
          debugPrint('⚠️ Filtering out group chat: $conversationId');
        }

        return !isGroupChat; // Chỉ giữ lại các cuộc trò chuyện KHÔNG phải group
      }).toList();

      if (oneOnOneConversations.isEmpty) {
        if (!silent) {
          debugPrint('║ ℹ️  API returned empty 1-1 conversations');
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

      for (var conv in oneOnOneConversations) { // ← ĐỔI conversations → oneOnOneConversations
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
        debugPrint('║ ✅ Loaded ${apiChats.length} 1-1 chats from API (filtered out ${conversations.length - oneOnOneConversations.length} group chats)');
        debugPrint('╚═══════════════════════════════════════╝');
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

    if (conversationId.startsWith('group_')) {
        debugPrint('⚠️ Ignoring group chat update in _updateChatPreview');
        return;
      }
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
                                                                      title: const Text('New Message'),
                                                                      content: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          ListTile(
                                                                            leading: const Icon(Icons.person_add, color: Colors.blue),
                                                                            title: const Text('New Chat'),
                                                                            subtitle: const Text('Start a direct conversation'),
                                                                            onTap: () {
                                                                              Navigator.pop(context);
                                                                              _showFriendSelectionDialog();
                                                                            },
                                                                          ),
                                                                          const Divider(),
                                                                          ListTile(
                                                                            leading: const Icon(Icons.group_add, color: Colors.green),
                                                                            title: const Text('New Group'),
                                                                            subtitle: const Text('Create a group chat'),
                                                                            onTap: () {
                                                                              Navigator.pop(context);

                                                                              final friendsList = _friends.map((friend) => {
                                                                                'firebaseUid': friend.userId,
                                                                                'fullName': friend.name,
                                                                                'username': friend.name,
                                                                                'photoUrl': friend.avatar,
                                                                              }).toList();

                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder: (context) => CreateGroupScreen(
                                                                                    currentUserId: _currentUserId,
                                                                                    friends: friendsList,
                                                                                  ),
                                                                                ),
                                                                              ).then((result) {                      // ← THAY _ BẰNG result
                                                                                if (result != null && result['success'] == true) {
                                                                                  _loadGroupsFromApi();               // ← Load groups
                                                                                  setState(() {
                                                                                    _selectedTab = 1;                 // ← Switch to Groups tab
                                                                                  });

                                                                                  final groupName = result['groupName'] ?? 'Group';
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text('✅ Group "$groupName" created!'),
                                                                                      backgroundColor: Colors.green,
                                                                                      duration: const Duration(seconds: 2),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              });
                                                                            },
                                                                          ),

                                                                        ],
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(context),
                                                                          child: const Text('Cancel'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }

                                                                void _showFriendSelectionDialog() {
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (context) => AlertDialog(
                                                                      title: const Text('Select Friend'),
                                                                      content: SizedBox(
                                                                        width: double.maxFinite,
                                                                        height: 400,
                                                                        child: _friends.isEmpty
                                                                            ? const Center(
                                                                                child: Text('No friends available'),
                                                                              )
                                                                            : ListView.builder(
                                                                                shrinkWrap: true,
                                                                                itemCount: _friends.length,
                                                                                itemBuilder: (context, index) {
                                                                                  final friend = _friends[index];
                                                                                  return ListTile(
                                                                                    leading: CircleAvatar(
                                                                                      backgroundImage: friend.avatar.startsWith('http')
                                                                                          ? NetworkImage(friend.avatar)
                                                                                          : AssetImage(friend.avatar) as ImageProvider,
                                                                                    ),
                                                                                    title: Text(friend.name),
                                                                                    onTap: () {
                                                                                      Navigator.pop(context);
                                                                                      _openChatWithFriend(friend);
                                                                                    },
                                                                                  );
                                                                                },
                                                                              ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(context),
                                                                          child: const Text('Cancel'),
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
                                                                // Show loading
                                                                if (_isLoadingGroups) {
                                                                  return const Center(child: CircularProgressIndicator());
                                                                }

                                                                // Empty state
                                                                if (_groups.isEmpty) {
                                                                  return Center(
                                                                    child: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        Icon(Icons.group_outlined, size: 100, color: Colors.grey[400]),
                                                                        const SizedBox(height: 20),
                                                                        Text(
                                                                          'No Groups Yet',
                                                                          style: TextStyle(
                                                                            fontSize: 24,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.grey[600],
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 10),
                                                                        Text(
                                                                          'Create a group to start chatting',
                                                                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                                                                        ),
                                                                        const SizedBox(height: 20),
                                                                        ElevatedButton.icon(
                                                                          onPressed: () {
                                                                            final friendsList = _friends.map((friend) => {
                                                                              'firebaseUid': friend.userId,
                                                                              'fullName': friend.name,
                                                                              'username': friend.name,
                                                                              'photoUrl': friend.avatar,
                                                                            }).toList();

                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => CreateGroupScreen(
                                                                                  currentUserId: _currentUserId,
                                                                                  friends: friendsList,
                                                                                ),
                                                                              ),
                                                                            ).then((result) {
                                                                              if (result != null && result['success'] == true) {
                                                                                _loadGroupsFromApi();
                                                                              }
                                                                            });
                                                                          },
                                                                          icon: const Icon(Icons.add),
                                                                          label: const Text('Create Group'),
                                                                          style: ElevatedButton.styleFrom(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }

                                                                // Show groups list
                                                                return RefreshIndicator(
                                                                  onRefresh: _loadGroupsFromApi,
                                                                  child: ListView.builder(
                                                                    itemCount: _groups.length,
                                                                    itemBuilder: (context, index) {
                                                                      final group = _groups[index];
                                                                      return _buildGroupItem(group);
                                                                    },
                                                                  ),
                                                                );
                                                              }
                                                              /// Build group list item
                                                                /// Build group list item
                                                                Widget _buildGroupItem(Map<String, dynamic> group) {
                                                                  final groupId = group['id'] ?? '';
                                                                  final groupName = group['name'] ?? 'Unnamed Group';
                                                                  final groupAvatar = group['avatar'];
                                                                  final memberIds = (group['memberIds'] as List?)?.cast<String>() ?? [];
                                                                  final memberCount = memberIds.length;
                                                                  final lastMessage = group['lastMessage'];
                                                                  final lastTime = group['lastTime'];

                                                                  String timeStr = '';
                                                                  if (lastTime != null) {
                                                                    try {
                                                                      final dateTime = DateTime.parse(lastTime.toString());
                                                                      timeStr = _formatTime(dateTime);
                                                                    } catch (e) {
                                                                      timeStr = '';
                                                                    }
                                                                  }

                                                                  return ListTile(
                                                                    onTap: () {
                                                                      debugPrint('═══════════════════════════════════════');
                                                                      debugPrint('📱 Opening group: $groupName');
                                                                      debugPrint('   Group ID: $groupId');
                                                                      debugPrint('   Members: $memberCount');
                                                                      debugPrint('═══════════════════════════════════════');

                                                                      // Navigate to group chat screen
                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) => ChatDetailScreen(
                                                                            name: groupName,
                                                                            avatar: groupAvatar ?? '',
                                                                            status: '$memberCount members',
                                                                            conversationId: groupId,
                                                                            currentUserId: _currentUserId,
                                                                            isGroupChat: true,
                                                                            onUpdateChatPreview: (id, msg, {isTyping = false}) {
                                                                              if (!isTyping && msg.isNotEmpty) {
                                                                                debugPrint('╔═══════════════════════════════════════╗');
                                                                                debugPrint('║ 🔄 UPDATING GROUP PREVIEW             ║');
                                                                                debugPrint('║ Group ID: $id');
                                                                                debugPrint('║ Message: $msg');
                                                                                debugPrint('╚═══════════════════════════════════════╝');

                                                                                setState(() {
                                                                                  final groupIndex = _groups.indexWhere((g) => g['id'] == id);
                                                                                  if (groupIndex != -1) {
                                                                                    _groups[groupIndex]['lastMessage'] = msg;
                                                                                    _groups[groupIndex]['lastTime'] = DateTime.now().toIso8601String();

                                                                                    debugPrint('✅ Updated group preview: ${_groups[groupIndex]['name']}');
                                                                                  } else {
                                                                                    debugPrint('⚠️ Group not found in list: $id');
                                                                                  }
                                                                                });
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ).then((_) {
                                                                        debugPrint('🔙 Returned from group chat, reloading groups...');
                                                                        _loadGroupsFromApi();
                                                                      });
                                                                    },
                                                                    // ✅ THÊM onLongPress
                                                                    onLongPress: () {
                                                                      _showGroupOptions(groupId, groupName);
                                                                    },
                                                                    leading: CircleAvatar(
                                                                      radius: 28,
                                                                      backgroundColor: Colors.blue[100],
                                                                      backgroundImage: groupAvatar != null && groupAvatar.startsWith('http')
                                                                          ? NetworkImage(groupAvatar)
                                                                          : null,
                                                                      child: groupAvatar == null || !groupAvatar.startsWith('http')
                                                                          ? Icon(Icons.group, color: Colors.blue[700], size: 28)
                                                                          : null,
                                                                    ),
                                                                    title: Text(
                                                                      groupName,
                                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                    ),
                                                                    subtitle: Text(
                                                                      lastMessage ?? '$memberCount members',
                                                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    trailing: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        if (timeStr.isNotEmpty)
                                                                          Text(
                                                                            timeStr,
                                                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                                          )
                                                                        else
                                                                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }

                                                                /// Show group options menu
                                                                void _showGroupOptions(String groupId, String groupName) {
                                                                  showModalBottomSheet(
                                                                    context: context,
                                                                    shape: const RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                                    ),
                                                                    builder: (context) => SafeArea(
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          const SizedBox(height: 12),
                                                                          Container(
                                                                            width: 40,
                                                                            height: 4,
                                                                            decoration: BoxDecoration(
                                                                              color: Colors.grey[300],
                                                                              borderRadius: BorderRadius.circular(2),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 20),
                                                                          Padding(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                                                            child: Text(
                                                                              groupName,
                                                                              style: const TextStyle(
                                                                                fontSize: 18,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                              textAlign: TextAlign.center,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 20),
                                                                          ListTile(
                                                                            leading: const Icon(Icons.delete_sweep, color: Colors.red),
                                                                            title: const Text(
                                                                              'Xóa toàn bộ đoạn chat',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                            subtitle: Text(
                                                                              'Xóa tất cả tin nhắn trong nhóm này',
                                                                              style: TextStyle(
                                                                                fontSize: 12,
                                                                                color: Colors.grey[600],
                                                                              ),
                                                                            ),
                                                                            onTap: () {
                                                                              Navigator.pop(context);
                                                                              _confirmDeleteGroupMessages(groupId, groupName);
                                                                            },
                                                                          ),
                                                                          const Divider(),
                                                                          ListTile(
                                                                            leading: Icon(Icons.exit_to_app, color: Colors.orange[700]),
                                                                            title: const Text(
                                                                              'Rời nhóm',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                            subtitle: Text(
                                                                              'Rời khỏi nhóm chat này',
                                                                              style: TextStyle(
                                                                                fontSize: 12,
                                                                                color: Colors.grey[600],
                                                                              ),
                                                                            ),
                                                                            onTap: () {
                                                                              Navigator.pop(context);
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                const SnackBar(
                                                                                  content: Text('Tính năng đang phát triển'),
                                                                                  duration: Duration(seconds: 2),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                          const SizedBox(height: 12),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                }

                                                                /// Confirm delete all group messages
                                                                void _confirmDeleteGroupMessages(String groupId, String groupName) {
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (context) => AlertDialog(
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(16),
                                                                      ),
                                                                      title: const Text('Xóa nhóm?'), // ← Đổi text
                                                                      content: Text(
                                                                        'Bạn có chắc chắn muốn xóa nhóm "$groupName"?\n\nTất cả tin nhắn và thông tin nhóm sẽ bị xóa vĩnh viễn.',
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(context),
                                                                          child: const Text('Hủy'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(context);
                                                                            _deleteGroupMessages(groupId, groupName);
                                                                          },
                                                                          style: TextButton.styleFrom(
                                                                            foregroundColor: Colors.red,
                                                                          ),
                                                                          child: const Text(
                                                                            'Xóa nhóm',
                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }

                                                                /// Delete all messages in group
                                                                /// Delete all messages in group
                                                                /// Delete all messages in group AND remove group from list
                                                                Future<void> _deleteGroupMessages(String groupId, String groupName) async {
                                                                  try {
                                                                    debugPrint('╔═══════════════════════════════════════╗');
                                                                    debugPrint('║ 🗑️  DELETING GROUP COMPLETELY         ║');
                                                                    debugPrint('║ Group ID: $groupId');
                                                                    debugPrint('║ Group Name: $groupName');
                                                                    debugPrint('╚═══════════════════════════════════════╝');

                                                                    // Show loading
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Row(
                                                                            children: [
                                                                              SizedBox(
                                                                                width: 20,
                                                                                height: 20,
                                                                                child: CircularProgressIndicator(
                                                                                  strokeWidth: 2,
                                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                                                ),
                                                                              ),
                                                                              SizedBox(width: 12),
                                                                              Text('Đang xóa nhóm...'),
                                                                            ],
                                                                          ),
                                                                          duration: Duration(seconds: 30),
                                                                        ),
                                                                      );
                                                                    }

                                                                    // Step 1: Delete all messages
                                                                    debugPrint('📝 Step 1: Deleting messages...');
                                                                    await MessageApi.deleteAllMessages(groupId);
                                                                    debugPrint('✅ Messages deleted');

                                                                    // Step 2: Delete the group itself
                                                                    debugPrint('📝 Step 2: Deleting group...');
                                                                    final groupDeleted = await GroupApi.deleteGroup(groupId);

                                                                    // Hide loading
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                    }

                                                                    if (groupDeleted) {
                                                                      // Step 3: Remove from local state immediately
                                                                      setState(() {
                                                                        _groups.removeWhere((g) => g['id'] == groupId);
                                                                      });

                                                                      debugPrint('✅ Group completely deleted: $groupId');
                                                                      debugPrint('📊 Remaining groups: ${_groups.length}');

                                                                      if (mounted) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text('✅ Đã xóa nhóm "$groupName"'),
                                                                            backgroundColor: Colors.green,
                                                                            duration: const Duration(seconds: 2),
                                                                          ),
                                                                        );
                                                                      }

                                                                      // Step 4: Reload to sync with backend
                                                                      await _loadGroupsFromApi();
                                                                    } else {
                                                                      debugPrint('⚠️ Failed to delete group from backend');

                                                                      if (mounted) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          const SnackBar(
                                                                            content: Text('⚠️ Không thể xóa nhóm. Vui lòng thử lại.'),
                                                                            backgroundColor: Colors.orange,
                                                                            duration: Duration(seconds: 3),
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  } catch (e) {
                                                                    debugPrint('❌ Error deleting group: $e');

                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('❌ Lỗi: $e'),
                                                                          backgroundColor: Colors.red,
                                                                          duration: const Duration(seconds: 3),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                }

                                                                Widget _buildStoryCircle(ChatPreview friend) {
                                                                  return GestureDetector(
                                                                    onTap: () => _openChatWithFriend(friend),
                                                                    child: Container(
                                                                      margin: const EdgeInsets.only(right: 12),
                                                                      width: 70,
                                                                      child: Column(
                                                                        children: [
                                                                          Container(
                                                                            width: 64,
                                                                            height: 64,
                                                                            decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              gradient: LinearGradient(
                                                                                colors: [Colors.purple.shade400, Colors.orange.shade400],
                                                                                begin: Alignment.topLeft,
                                                                                end: Alignment.bottomRight,
                                                                              ),
                                                                            ),
                                                                            padding: const EdgeInsets.all(3),
                                                                            child: CircleAvatar(
                                                                              backgroundColor: Colors.white,
                                                                              child: CircleAvatar(
                                                                                radius: 28,
                                                                                backgroundImage: friend.avatar.startsWith('http')
                                                                                    ? NetworkImage(friend.avatar)
                                                                                    : AssetImage(friend.avatar) as ImageProvider,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          Text(
                                                                            friend.name,
                                                                            style: const TextStyle(
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            textAlign: TextAlign.center,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                }

                                                                /// Build tab button
                                                                Widget _buildTab(String title, {required bool isSelected}) {
                                                                  return Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                    decoration: BoxDecoration(
                                                                      color: isSelected ? Colors.blue : Colors.transparent,
                                                                      borderRadius: BorderRadius.circular(20),
                                                                    ),
                                                                    child: Text(
                                                                      title,
                                                                      style: TextStyle(
                                                                        color: isSelected ? Colors.white : Colors.grey[700],
                                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                        fontSize: 16,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }

                                                                /// Build chat item in list
                                                                Widget _buildChatItem(ChatPreview chat) {
                                                                  return Dismissible(
                                                                    key: Key(chat.conversationId),
                                                                    direction: DismissDirection.endToStart,
                                                                    confirmDismiss: (direction) async {
                                                                      return await showDialog(
                                                                        context: context,
                                                                        builder: (context) => AlertDialog(
                                                                          title: const Text('Delete Chat'),
                                                                          content: Text('Delete conversation with ${chat.name}?'),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(context, false),
                                                                              child: const Text('Cancel'),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(context, true),
                                                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                                              child: const Text('Delete'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                    onDismissed: (direction) {
                                                                      _deleteChat(chat);
                                                                    },
                                                                    background: Container(
                                                                      color: Colors.red,
                                                                      alignment: Alignment.centerRight,
                                                                      padding: const EdgeInsets.only(right: 20),
                                                                      child: const Icon(Icons.delete, color: Colors.white),
                                                                    ),
                                                                    child: ListTile(
                                                                      onTap: () => _openChatWithFriend(chat),
                                                                      onLongPress: () {
                                                                        showModalBottomSheet(
                                                                          context: context,
                                                                          builder: (context) => SafeArea(
                                                                            child: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                ListTile(
                                                                                  leading: const Icon(Icons.delete, color: Colors.red),
                                                                                  title: const Text('Delete Chat'),
                                                                                  onTap: () {
                                                                                    Navigator.pop(context);
                                                                                    _showDeleteChatDialog(chat);
                                                                                  },
                                                                                ),
                                                                                ListTile(
                                                                                  leading: const Icon(Icons.block, color: Colors.orange),
                                                                                  title: const Text('Block User'),
                                                                                  onTap: () {
                                                                                    Navigator.pop(context);
                                                                                    _showBlockUserDialog(chat);
                                                                                  },
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      leading: Stack(
                                                                        children: [
                                                                          CircleAvatar(
                                                                            radius: 28,
                                                                            backgroundColor: Colors.grey[300],
                                                                            backgroundImage: chat.avatar.startsWith('http')
                                                                                ? NetworkImage(chat.avatar)
                                                                                : AssetImage(chat.avatar) as ImageProvider,
                                                                          ),
                                                                          if (chat.isLocalUpdate)
                                                                            Positioned(
                                                                              right: 0,
                                                                              bottom: 0,
                                                                              child: Container(
                                                                                width: 16,
                                                                                height: 16,
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.green,
                                                                                  shape: BoxShape.circle,
                                                                                  border: Border.all(color: Colors.white, width: 2),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                      title: Text(
                                                                        chat.name,
                                                                        style: TextStyle(
                                                                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                                                          fontSize: 16,
                                                                        ),
                                                                      ),
                                                                      subtitle: chat.isTyping
                                                                          ? Row(
                                                                              children: [
                                                                                Text(
                                                                                  'typing',
                                                                                  style: TextStyle(
                                                                                    color: Colors.blue[600],
                                                                                    fontSize: 14,
                                                                                    fontStyle: FontStyle.italic,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(width: 4),
                                                                                SizedBox(
                                                                                  width: 20,
                                                                                  height: 14,
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                    children: List.generate(3, (index) {
                                                                                      return AnimatedContainer(
                                                                                        duration: const Duration(milliseconds: 300),
                                                                                        width: 4,
                                                                                        height: 4,
                                                                                        decoration: const BoxDecoration(
                                                                                          color: Colors.blue,
                                                                                          shape: BoxShape.circle,
                                                                                        ),
                                                                                      );
                                                                                    }),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            )
                                                                          : Text(
                                                                              chat.lastMessage,
                                                                              style: TextStyle(
                                                                                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                                                                fontSize: 14,
                                                                                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                      trailing: Column(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            chat.time,
                                                                            style: TextStyle(
                                                                              color: chat.unreadCount > 0 ? Colors.blue : Colors.grey[500],
                                                                              fontSize: 12,
                                                                              fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                                                            ),
                                                                          ),
                                                                          if (chat.unreadCount > 0) ...[
                                                                            const SizedBox(height: 4),
                                                                            Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.blue,
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                              constraints: const BoxConstraints(minWidth: 20),
                                                                              child: Text(
                                                                                '${chat.unreadCount}',
                                                                                style: const TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 12,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                                textAlign: TextAlign.center,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              }