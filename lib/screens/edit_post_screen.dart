import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      try {
        await ApiService.updatePost(
          widget.post.id,
          _titleController.text,
          _contentController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 수정되었습니다')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수정 실패: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 수정'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 작성자는 수정 불가 (읽기 전용)
            TextFormField(
              initialValue: widget.post.author,
              decoration: const InputDecoration(
                labelText: '작성자',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '제목을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 140),
                  child: Icon(Icons.edit_note),
                ),
              ),
              maxLines: 10,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '내용을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text('수정 완료', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}