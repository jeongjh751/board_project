import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
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
  String? token;
  String? username;
  String? currentUsername;

  // 페이지네이션 관련
  int currentPage = 1;
  int totalPages = 1;
  int totalPosts = 0;
  int postsPerPage = 5;
  bool hasNextPage = false;
  bool hasPreviousPage = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getPostsWithPagination(
        page: page,
        limit: postsPerPage,
      );
      
      setState(() {
        posts = result['posts'];
        final pagination = result['pagination'];
        currentPage = pagination['currentPage'];
        totalPages = pagination['totalPages'];
        totalPosts = pagination['totalPosts'];
        hasNextPage = pagination['hasNextPage'];
        hasPreviousPage = pagination['hasPreviousPage'];
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
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }
    
    try {
      await ApiService.deletePost(id, token!); // 토큰 전달
      _loadPosts(page: currentPage);
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

  // 로그인 성공 후
  Future<void> _showLoginScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    
    if (result != null && result is String) {
      setState(() {
        token = result;
        // 토큰에서 사용자명 추출
        try {
          Map<String, dynamic> payload = Jwt.parseJwt(result);
          currentUsername = payload['username'];
          username = payload['username']; // AppBar에 표시용
        } catch (e) {
          print('토큰 파싱 오류: $e');
        }
      });
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
            onPressed: () => _loadPosts(page: currentPage),
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
      body: Column(
        children: [
          // 페이지 정보
          if (!isLoading && posts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '전체 $totalPosts개 게시글 | $currentPage / $totalPages 페이지',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          
          // 게시글 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('오류 발생', 
                                style: TextStyle(fontSize: 18, color: Colors.red)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(errorMessage!, textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadPosts(page: currentPage),
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
                        : ListView.builder(
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
                                  // 본인 글일 때만 삭제 버튼 표시
                                  trailing: (token != null && post.author == currentUsername)
                                      ? IconButton(
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
                                                    child: const Text('삭제',
                                                        style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : null, // 본인 글 아니면 버튼 없음
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailScreen(
                                          post: post,
                                          token: token,
                                          currentUsername: currentUsername, // 추가!
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadPosts(page: currentPage);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
          ),
          
          // 페이지네이션 컨트롤
          if (!isLoading && posts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 첫 페이지
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: currentPage > 1
                        ? () => _loadPosts(page: 1)
                        : null,
                  ),
                  // 이전 페이지
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: hasPreviousPage
                        ? () => _loadPosts(page: currentPage - 1)
                        : null,
                  ),
                  // 페이지 번호
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentPage / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 다음 페이지
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: hasNextPage
                        ? () => _loadPosts(page: currentPage + 1)
                        : null,
                  ),
                  // 마지막 페이지
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: currentPage < totalPages
                        ? () => _loadPosts(page: totalPages)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('게시글 작성을 위해 로그인이 필요합니다')),
            );
            _showLoginScreen();
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WritePostScreen(token: token!),
              ),
            );
            if (result == true) {
              _loadPosts(page: 1); // 새 글 작성 후 첫 페이지로
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}