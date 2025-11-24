import 'package:flutter/material.dart';
import 'package:frontend/chat/group_api.dart'; // ← Đổi import này
// import 'package:frontend/chat/message_api.dart'; // ← XÓA dòng này

class CreateGroupScreen extends StatefulWidget {
  final String currentUserId;
  final List<Map<String, dynamic>> friends;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
    required this.friends,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedFriends = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFriends.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 members'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 🆕 CREATING GROUP CHAT                ║');
      debugPrint('╠═══════════════════════════════════════╣');
      debugPrint('║ Group Name: $groupName');
      debugPrint('║ Created By: ${widget.currentUserId}');
      debugPrint('║ Members: ${_selectedFriends.length + 1}');

      // Add creator to members list
      final memberIds = [widget.currentUserId, ..._selectedFriends];

      // ✅ Đổi từ MessageApi sang GroupApi
      final response = await GroupApi.createGroup(
        name: groupName,
        memberIds: memberIds,
        createdBy: widget.currentUserId,
      );

      if (response['success'] == true) {
        final conversationId = response['conversationId'];

        debugPrint('║ ✅ Group created successfully!');
        debugPrint('║ ConversationId: $conversationId');
        debugPrint('╚═══════════════════════════════════════╝');

        if (mounted) {
          Navigator.pop(context, {
            'success': true,
            'conversationId': conversationId,
            'groupName': groupName,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Group "$groupName" created!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to create group');
      }
    } catch (e) {
      debugPrint('❌ Error creating group: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text(
                'Create',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group Name Input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),

          const Divider(height: 1),

          // Selected Members Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'Selected: ${_selectedFriends.length} members',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_selectedFriends.length < 2)
                  Text(
                    'Select at least 2',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Friends List
          Expanded(
            child: widget.friends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No friends available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.friends.length,
                    itemBuilder: (context, index) {
                      final friend = widget.friends[index];
                      final userId = friend['userId'] ?? friend['firebaseUid'] ?? '';
                      final name = friend['name'] ?? friend['fullName'] ?? friend['username'] ?? 'Unknown';
                      final avatar = friend['avatar'] ?? friend['photoUrl'];

                      final isSelected = _selectedFriends.contains(userId);

                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriends.remove(userId);
                            } else {
                              _selectedFriends.add(userId);
                            }
                          });
                        },
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: avatar != null && avatar.startsWith('http')
                                  ? NetworkImage(avatar)
                                  : null,
                              child: avatar == null || !avatar.startsWith('http')
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedFriends.add(userId);
                              } else {
                                _selectedFriends.remove(userId);
                              }
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}