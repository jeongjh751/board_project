import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'post_detail_screen.dart';
import 'write_post_screen.dart';
import 'login_screen.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({Key? key}) : super(key: key);

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  List<Post> posts = [];
  bool isLoading = false;
  String? errorMessage;
  String? token; // 로그인 토큰 저장
  String? username; // 로그인한 사용자 이름

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPosts = await ApiService.getPosts();
      setState(() {
        posts = loadedPosts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      await ApiService.deletePost(id);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _showLoginScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    
    if (result != null && result is String) {
      // 로그인 성공 시 토큰 받음
      setState(() {
        token = result;
      });
      // TODO: 토큰에서 사용자 정보 추출하거나 별도 API 호출
    }
  }

  void _logout() {
    setState(() {
      token = null;
      username = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그아웃되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        actions: [
          if (token != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  username ?? '로그인됨',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
          if (token == null)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _showLoginScreen,
              tooltip: '로그인',
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: '로그아웃',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('오류 발생', style: TextStyle(fontSize: 18, color: Colors.red)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(errorMessage!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : posts.isEmpty
                  ? const Center(
                      child: Text(
                        '게시글이 없습니다',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                post.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    post.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.author,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.createdAt,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('삭제 확인'),
                                      content: const Text('이 게시글을 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _deletePost(post.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(post: post),
                                  ),
                                );
                                if (result == true) {
                                  _loadPosts();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (token == null) {
            // 로그인 안 되어 있으면 로그인 화면으로
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('게시글 작성을 위해 로그인이 필요합니다')),
            );
            _showLoginScreen();
          } else {
            // 로그인 되어 있으면 글쓰기
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WritePostScreen(token: token!),
              ),
            );
            if (result == true) {
              _loadPosts();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}