import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import 'package:frontend/chat/message_api.dart';

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

  Timer? _refreshTimer;
  Timer? _timeUpdateTimer;
  bool _isInChat = false;
  bool _hasInitialized = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ChatPreview> _friends = [
    ChatPreview(
      conversationId: 'You',
      name: 'You',
      avatar: 'assets/images/profiles.png',
      userId: 'me',
    ),
    ChatPreview(
      conversationId: 'Bella',
      name: 'Bella',
      avatar: 'assets/images/woman.png',
      userId: 'bella',
    ),
    ChatPreview(
      conversationId: 'Emma',
      name: 'Emma',
      avatar: 'assets/images/emma.png',
      userId: 'emma',
    ),
    ChatPreview(
      conversationId: 'Aron',
      name: 'Aron',
      avatar: 'assets/images/boy.png',
      userId: 'aron',
    ),
    ChatPreview(
      conversationId: 'Mia',
      name: 'Mia',
      avatar: 'assets/images/mia.png',
      userId: 'mia',
    ),
  ];

  List<ChatPreview> _chats = [];

  List<ChatPreview> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ChatPreview> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return _friends;
    }
    return _friends.where((friend) {
      return friend.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUserId ?? 'bella';
    _loadChatsFromApi();
    _startAutoRefresh();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isInChat) {
        _loadChatsFromApi(silent: true);
      }
    });
  }

  Future<void> _loadChatsFromApi({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      if (!silent) {
        debugPrint('╔═══════════════════════════════════════╗');
        debugPrint('║ 🔄 LOADING CHATS FROM API             ║');
        debugPrint('╠═══════════════════════════════════════╣');
        debugPrint('║ Current User: $_currentUserId');
      }

      final conversations = await MessageApi.getUserConversations(_currentUserId);

      if (conversations.isEmpty) {
        if (!silent) {
          debugPrint('║ ⚠️  API returned empty list');
        }

        // ⭐ CHỈ INIT HARDCODED CHO TOMMY VÀ BELLA
        if (!_hasInitialized && _chats.isEmpty) {
          if (_currentUserId == 'tommy' || _currentUserId == 'bella') {
            debugPrint('║ 💡 Tommy/Bella - using hardcoded data with real messages');
            await _initChatsHardcoded();
          } else {
            debugPrint('║ 🚫 Other user ($_currentUserId) - starting with empty chat list');
            setState(() {
              _chats = [];
              _hasInitialized = true;
            });
          }
        } else {
          debugPrint('║ ✅ Keeping existing chat data (${_chats.length} chats)');
        }
      } else {
        final newChats = conversations.map((conv) {
          return ChatPreview(
            conversationId: conv['conversationId']?.toString() ?? '',
            name: conv['otherUserName']?.toString() ?? 'Unknown',
            avatar: conv['otherUserAvatar']?.toString() ?? 'assets/images/default.png',
            userId: conv['otherUserId']?.toString() ?? '',
            lastMessage: conv['lastMessage']?.toString() ?? '',
            time: _formatTimeFromString(conv['lastMessageTime']?.toString()),
            unreadCount: conv['unreadCount'] as int? ?? 0,
            lastMessageTime: _parseIsoTime(conv['lastMessageTime']?.toString()),
          );
        }).toList();

        setState(() {
          final existingChatsMap = {
            for (var chat in _chats) chat.conversationId: chat
          };

          final mergedChats = <ChatPreview>[];

          for (var newChat in newChats) {
            final existingChat = existingChatsMap[newChat.conversationId];

            if (existingChat != null) {
              final existingTime = existingChat.lastMessageTime;
              final newTime = newChat.lastMessageTime;

              if (newTime != null &&
                  (existingTime == null || newTime.isAfter(existingTime))) {
                if (!silent) {
                  debugPrint('║ ✅ Server message newer for ${newChat.name} - updating');
                }
                mergedChats.add(newChat.copyWith(
                  unreadCount: newChat.unreadCount,
                  isLocalUpdate: false,
                ));
                continue;
              }

              if (newTime != null &&
                  existingTime != null &&
                  newTime.isAtSameMomentAs(existingTime)) {
                if (existingChat.isLocalUpdate) {
                  if (!silent) {
                    debugPrint('║ 🔄 Timestamps equal - keeping local update for ${newChat.name}');
                  }
                  mergedChats.add(existingChat.copyWith(
                    unreadCount: newChat.unreadCount,
                  ));
                } else {
                  if (!silent) {
                    debugPrint('║ ✅ Timestamps equal - using server data for ${newChat.name}');
                  }
                  mergedChats.add(newChat.copyWith(
                    unreadCount: newChat.unreadCount,
                  ));
                }
                continue;
              }

              if (existingTime != null &&
                  newTime != null &&
                  existingTime.isAfter(newTime)) {
                if (!silent) {
                  debugPrint('║ 🔄 Local message newer for ${newChat.name} - keeping local');
                }
                mergedChats.add(existingChat.copyWith(
                  unreadCount: newChat.unreadCount,
                ));
                continue;
              }

              if (!silent) {
                debugPrint('║ ⚠️  No timestamp comparison - using server data for ${newChat.name}');
              }
              mergedChats.add(newChat.copyWith(
                unreadCount: newChat.unreadCount,
              ));
            } else {
              mergedChats.add(newChat);
            }
          }

          mergedChats.sort((a, b) {
            final timeA = a.lastMessageTime;
            final timeB = b.lastMessageTime;

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;

            return timeB.compareTo(timeA);
          });

          _chats = mergedChats;
          _hasInitialized = true;
        });

        if (!silent) {
          debugPrint('║ ✅ Loaded ${_chats.length} conversations from API');
          for (var chat in _chats) {
            debugPrint('║   • ${chat.name}: ${chat.lastMessage}');
          }
        }
      }

      if (!silent) {
        debugPrint('╚═══════════════════════════════════════╝');
      }
    } catch (e) {
      if (!silent) {
        debugPrint('║ ❌ Error loading from API: $e');
      }

      // ⭐ CHỈ INIT HARDCODED CHO TOMMY VÀ BELLA KHI CÓ LỖI
      if (!_hasInitialized && _chats.isEmpty) {
        if (_currentUserId == 'tommy' || _currentUserId == 'bella') {
          debugPrint('║ 💡 First time init after error (Tommy/Bella) - using hardcoded data');
          await _initChatsHardcoded();
        } else {
          debugPrint('║ 🚫 First time init after error (Other user) - starting empty');
          setState(() {
            _chats = [];
            _hasInitialized = true;
          });
        }
      } else {
        debugPrint('║ ✅ API failed but keeping existing data (${_chats.length} chats)');
      }

      if (!silent) {
        debugPrint('╚═══════════════════════════════════════╝');
      }
    } finally {
      if (!silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initChatsHardcoded() async {
    final now = DateTime.now();
    debugPrint('🕐 Initializing hardcoded chats at: ${_formatTime(now)}');

    final conversationId = 'tommy-bella-chat';

    final messages = await MessageApi.getMessages(
      conversationId: conversationId,
    );

    String lastMsg = 'Say hi to start chatting!';
    DateTime lastMsgTime = now;

    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      lastMsg = lastMessage['content']?.toString() ?? lastMsg;

      final timestamp = lastMessage['createdAt'] ??
          lastMessage['timestamp'] ??
          lastMessage['created_at'];
      if (timestamp != null) {
        try {
          lastMsgTime = DateTime.parse(timestamp.toString());
        } catch (e) {
          lastMsgTime = now;
        }
      }

      debugPrint('║ 📩 Loaded last message from API: "$lastMsg"');
    } else {
      debugPrint('║ 📭 No messages found, using default text');
    }

    final allChats = <ChatPreview>[
      ChatPreview(
        conversationId: conversationId,
        name: 'Tommy',
        avatar: 'assets/images/tommy.png',
        userId: 'tommy',
        lastMessage: lastMsg,
        time: _formatTime(lastMsgTime),
        lastMessageTime: lastMsgTime,
      ),
      ChatPreview(
        conversationId: conversationId,
        name: 'Bella',
        avatar: 'assets/images/woman.png',
        userId: 'bella',
        lastMessage: lastMsg,
        time: _formatTime(lastMsgTime),
        lastMessageTime: lastMsgTime,
      ),
    ];

    setState(() {
      _chats = allChats.where((chat) => chat.userId != _currentUserId).toList();
      _hasInitialized = true;
    });

    debugPrint('║ 📦 Using ${_chats.length} hardcoded chats for testing');
    for (var chat in _chats) {
      debugPrint('║   • ${chat.name}: ${chat.lastMessage} at ${chat.time}');
    }
  }

  Future<void> _refreshChats() async {
    await _loadChatsFromApi();
  }

  // ⭐ MỞ CHAT VỚI BẠN BÈ - KHÔNG TẠO PREVIEW
  Future<void> _openChatWithFriend(ChatPreview friend) async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 Opening chat with friend: ${friend.name}');
    debugPrint('   UserId: ${friend.userId}');
    debugPrint('   🚫 NOT creating preview - will wait for first message');
    debugPrint('═══════════════════════════════════════');

    final userIds = [_currentUserId, friend.userId]..sort();
    final conversationId = '${userIds[0]}-${userIds[1]}-chat';

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
          onUpdateChatPreview: _updateChatPreview,
        ),
      ),
    );

    setState(() => _isInChat = false);

    // ⭐ Sau khi đóng chat, refresh để lấy tin nhắn mới từ server
    await _loadChatsFromApi(silent: true);
  }

  // ⭐ UPDATE CHAT PREVIEW - CHỈ TẠO KHI CÓ TIN NHẮN
  void _updateChatPreview(String conversationId, String lastMessage, {bool isTyping = false}) {
    final now = DateTime.now();

    debugPrint('╔═══════════════════════════════════════╗');
    debugPrint('║ 📝 UPDATE CHAT PREVIEW                ║');
    debugPrint('╠═══════════════════════════════════════╣');
    debugPrint('║ ConversationId: $conversationId');
    debugPrint('║ New Message: $lastMessage');
    debugPrint('║ Is Typing: $isTyping');
    debugPrint('║ Current chats: ${_chats.length}');

    setState(() {
      final chatIndex = _chats.indexWhere((c) => c.conversationId == conversationId);

      if (chatIndex != -1) {
        // ⭐ Chat đã tồn tại - chỉ update
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          lastMessage: lastMessage,
          time: _formatTime(now),
          lastMessageTime: now,
          isTyping: isTyping,
          unreadCount: isTyping ? _chats[chatIndex].unreadCount : 0,
          isLocalUpdate: true,
        );

        final updatedChat = _chats.removeAt(chatIndex);
        _chats.insert(0, updatedChat);

        debugPrint('║ ✅ Chat updated: ${updatedChat.name}');
      } else {
        // ⭐ Chat chưa tồn tại - CHỈ TẠO KHI CÓ TIN NHẮN (không phải typing)
        if (!isTyping && lastMessage.isNotEmpty) {
          debugPrint('║ 💬 First message sent - creating new chat preview');

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
                name: 'Unknown',
                avatar: 'assets/images/default.png',
                userId: otherUserId!,
              ),
            );

            final newChat = ChatPreview(
              conversationId: conversationId,
              name: friend.name,
              avatar: friend.avatar,
              userId: friend.userId,
              lastMessage: lastMessage,
              time: _formatTime(now),
              lastMessageTime: now,
              isTyping: false,
              unreadCount: 0,
              isLocalUpdate: true,
            );

            _chats.insert(0, newChat);
            debugPrint('║ ✅ Created new chat: ${newChat.name}');
          } else {
            debugPrint('║ ❌ Could not extract userId from conversationId');
          }
        } else {
          debugPrint('║ 🚫 Typing indicator or empty message - NOT creating preview yet');
        }
      }

      debugPrint('║ Total chats after update: ${_chats.length}');
    });

    debugPrint('╚═══════════════════════════════════════╝');

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          final chatIndex = _chats.indexWhere((c) => c.conversationId == conversationId);
          if (chatIndex != -1) {
            _chats[chatIndex] = _chats[chatIndex].copyWith(isLocalUpdate: false);
            debugPrint('🔓 Cleared local update flag for: ${_chats[chatIndex].name}');
          }
        });
      }
    });
  }

  DateTime? _parseIsoTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatTimeFromString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return _formatTime(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[dateTime.weekday - 1];
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
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

    setState(() {
      _chats.removeWhere((c) => c.conversationId == chat.conversationId);
    });

    debugPrint('🗑️ Deleting chat with ${chat.name}');
    debugPrint('   ConversationId: ${chat.conversationId}');

    try {
      debugPrint('⚠️ Trying to delete messages instead of conversation');
      final success = await MessageApi.deleteAllMessages(chat.conversationId);

      if (success) {
        debugPrint('✅ Messages deleted from database');
      } else {
        debugPrint('⚠️ Could not delete messages from database (endpoint may not exist)');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat with ${chat.name} deleted'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _chats.insert(deletedIndex, deletedChat);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat restored'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _chats.insert(deletedIndex, deletedChat);
      });
    }
  }

  Future<void> _blockUser(ChatPreview chat) async {
    setState(() {
      _chats.removeWhere((c) => c.conversationId == chat.conversationId);
    });

    debugPrint('🚫 Blocking user: ${chat.name}');
    debugPrint('   UserId: ${chat.userId}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.name} has been blocked'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );

    debugPrint('✅ User blocked successfully');
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
              child: Text(
                'No friends found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            )
                : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filteredFriends
                  .map((f) => _buildStoryCircle(f.name, f.avatar, isYou: f.name == 'You'))
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: _buildTab('Chats', isSelected: _selectedTab == 0)),
                const SizedBox(width: 30),
                GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: _buildTab('Groups', isSelected: _selectedTab == 1)),
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
      final matchingFriends = _friends.where((f) =>
      f.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          f.name != 'You'
      ).toList();

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
            const SizedBox(height: 16),
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
          return _buildChatItem(
            chat,
            context,
            chat.name,
            chat.lastMessage,
            chat.time,
            chat.avatar,
            isTyping: chat.isTyping,
            unreadCount: chat.unreadCount,
          );
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

  Widget _buildStoryCircle(String name, String imagePath, {bool isYou = false}) {
    final friend = _friends.firstWhere(
          (f) => f.name == name,
      orElse: () => _friends.first,
    );

    return GestureDetector(
      onTap: isYou ? null : () => _openChatWithFriend(friend),
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
                  color: isYou ? Colors.grey : Colors.blue,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
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
            Text(name, style: const TextStyle(fontSize: 12)),
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

  Widget _buildChatItem(
      ChatPreview chat,
      BuildContext context,
      String name,
      String message,
      String time,
      String imagePath, {
        bool isTyping = false,
        int unreadCount = 0,
      }) {
    return ListTile(
      onTap: () async {
        debugPrint('═══════════════════════════════════════');
        debugPrint('📱 Opening existing chat with: $name');
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
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        message,
        style: TextStyle(
          color: isTyping ? Colors.blue : Colors.grey[600],
          fontSize: 14,
          fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
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
                time,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
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