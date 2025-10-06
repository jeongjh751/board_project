import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WritePostScreen extends StatefulWidget {
  final String token;
  
  const WritePostScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      try {
        await ApiService.createPostWithToken(
          _titleController.text,
          _contentController.text,
          widget.token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 작성되었습니다')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('작성 실패: $e')),
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
        title: const Text('게시글 작성'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                onPressed: isSubmitting ? null : _submitPost,
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
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('게시글 작성', style: TextStyle(fontSize: 16)),
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