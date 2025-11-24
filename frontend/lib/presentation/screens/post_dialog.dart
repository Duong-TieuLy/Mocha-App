import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../view_models/profile_view_model.dart';


class PostDialog extends StatefulWidget {
  const PostDialog({super.key});

  @override
  _PostDialogState createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool _isPickingImage = false; // 🔒 khóa để tránh picker bị gọi nhiều lần

  // Chọn ảnh từ gallery
  Future<void> _pickImage() async {
    if (_isPickingImage) return; // đã đang pick, không làm gì
    _isPickingImage = true;

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image')));
    } finally {
      _isPickingImage = false;
    }
  }

  // Upload post
  Future<void> _submit() async {
    if (_captionController.text.isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final postVM = Provider.of<PostViewModel>(context, listen: false);
      await postVM.createPost(_captionController.text, _selectedImage);

      // Clear và đóng dialog
      _captionController.clear();
      setState(() => _selectedImage = null);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload post: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField caption
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Write a caption...",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),

            // Preview ảnh hoặc tap chọn
            _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
                : GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Tap to select image",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nút Cancel & Post
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
