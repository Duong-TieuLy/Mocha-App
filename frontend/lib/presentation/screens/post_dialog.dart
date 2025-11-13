import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Widget riêng cho dialog đăng post
class PostDialog extends StatefulWidget {
  // Callback để thông báo khi post được tạo (truyền dữ liệu post mới về ExplorePage)
  final Function(Map<String, dynamic>) onPostCreated;

  const PostDialog({super.key, required this.onPostCreated});

  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm đăng post
  void _post() {
    if (_captionController.text.isNotEmpty || _selectedImage != null) {
      // Tạo post mới với Map
      final newPost = {
        'name': "You", // Giả lập tên người dùng hiện tại
        'username': "@YourUsername", // Giả lập username
        'image': _selectedImage?.path ?? "https://via.placeholder.com/300", // Nếu không có ảnh, dùng placeholder
        'caption': _captionController.text.isNotEmpty ? _captionController.text : "Không có caption",
        'likes': 0, // Bắt đầu với 0 like
        'comments': 0, // Bắt đầu với 0 comment
      };

      // Gọi callback để cập nhật danh sách posts trong ExplorePage
      widget.onPostCreated(newPost);

      // Reset form
      _captionController.clear();
      setState(() {
        _selectedImage = null;
      });
      Navigator.of(context).pop(); // Đóng dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Bo tròn giống post card
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD8E8FF), // Màu xanh nhạt giống post card
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (giống post card, bỏ icon 3 chấm)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde"), // Avatar giả lập
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You", // Tên người dùng hiện tại
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "@YourUsername", // Username giả lập
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Caption (dùng TextField để nhập, giống post card nhưng có thể edit)
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none, // Loại bỏ border để giống Text trong post
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // Ảnh preview (giống post card, nhưng "No Image selected" có thể nhấp để chọn ảnh)
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickImage, // Nhấp vào để chọn ảnh
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        'No image selected\n(Tap to select)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Nút Post ở cuối (bỏ row like/comment/share)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _post,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}