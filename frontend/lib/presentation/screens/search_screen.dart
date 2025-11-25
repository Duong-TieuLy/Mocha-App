import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/other_profile_screen.dart';
import 'package:provider/provider.dart';
import '../view_models/user_view_model.dart';
import '../../data/models/user_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    final vm = context.read<UserViewModel>();
    final currentUserId = vm.profile?.firebaseUid ?? "";

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      vm.performSearch(currentUserId, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();
    final uid = vm.profile?.firebaseUid ?? "";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Thanh kéo
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),

          // TextField tìm kiếm
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 20),

          // Kết quả tìm kiếm
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: vm.searchResults.length,
              itemBuilder: (context, index) {
                final UserProfile user = vm.searchResults[index];
                final int targetId = user.id; // id của user trong DB
                print("targetId: $targetId");
                // Lấy trạng thái follow từ ViewModel
                final bool isFollowed = vm.isFollowing(targetId);

                // Load trạng thái follow (1 lần)
                vm.checkFollowStatus(uid, targetId);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.photoUrl),
                    radius: 25,
                  ),
                    title: Text(user.fullName),
                    subtitle: Text(user.email),

                    trailing: (user.firebaseUid == uid)
                        ? null // không hiện nút cho chính mình
                        : ElevatedButton(
                      onPressed: () async {
                        try {
                          if (isFollowed) {
                            await vm.unfollow(uid, targetId);
                          } else {
                            await vm.follow(uid, targetId);
                          }
                        } catch (e, stack) {
                          debugPrint("Follow/unfollow error: $e");
                          debugPrintStack(stackTrace: stack);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isFollowed ? Colors.grey : Colors.blue,
                      ),
                      child: Text(isFollowed ? "Following" : "Follow"),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (_) => OtherProfileScreen(
                        userId: user.firebaseUid,
                      ),
                      ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
