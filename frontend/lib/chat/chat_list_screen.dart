import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedTab = 0;

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
            onPressed: () {},
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
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStoryCircle('You', 'assets/images/profiles.png', isYou: true),
                _buildStoryCircle('Bella', 'assets/images/woman.png'),
                _buildStoryCircle('Emma', 'assets/images/emma.png'),
                _buildStoryCircle('Aron', 'assets/images/boy.png'),
                _buildStoryCircle('Mia', 'assets/images/mia.png'),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: _buildTab('Chats', isSelected: _selectedTab == 0),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
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

  Widget _buildChatsList() {
    return ListView(
      children: [
        _buildChatItem(
          context,
          'Tommy',
          'Typing......',
          '9:41 AM',
          'assets/images/tommy.png',
        ),
        _buildChatItem(
          context,
          'Bella',
          'Typing......',
          '9:41 AM',
          'assets/images/woman.png',
          isTyping: true,
        ),
      ],
    );
  }

  Widget _buildEmptyFolder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(String name, String imagePath, {bool isYou = false}) {
    return Padding(
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
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          ),
        ],
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
    BuildContext context,
    String name,
    String message,
    String time,
    String imagePath, {
    bool isTyping = false,
  }) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              name: name,
              avatar: imagePath,
              status: isTyping ? 'Typing...' : 'Online',
            ),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[300],
        backgroundImage: AssetImage(imagePath),
        onBackgroundImageError: (exception, stackTrace) {},
        child: null,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        message,
        style: TextStyle(
          color: isTyping ? Colors.grey : Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}