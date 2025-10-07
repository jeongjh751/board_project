import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/post.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> getPostsWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts?page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'posts': (data['posts'] as List)
            .map((json) => Post.fromJson(json))
            .toList(),
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('게시글 목록을 불러오는데 실패했습니다');
    }
  }

  // 기존 메서드도 유지 (호환성)
  static Future<List<Post>> getPosts() async {
    final result = await getPostsWithPagination(page: 1, limit: 100);
    return result['posts'];
  }

  static Future<void> createPost(String title, String content, String author) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'content': content,
          'author': author,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('게시글 작성 실패');
      }
    } catch (e) {
      throw Exception('서버 연결 실패: $e');
    }
  }
  
  // 게시글 수정 (토큰 필요)
  static Future<void> updatePost(
    int id,
    String title,
    String content,
    String token, // 토큰 추가
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 토큰 헤더 추가
      },
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? '게시글 수정 실패');
    }
  }

  // 게시글 삭제 (토큰 필요)
  static Future<void> deletePost(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('삭제 실패');
    }
  }

  // 회원가입
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? '회원가입 실패');
    }
  }

  // 로그인
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? '로그인 실패');
    }
  }

  // 토큰을 사용한 게시글 작성
  static Future<void> createPostWithToken(
    String title,
    String content,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        // author는 서버에서 토큰으로부터 가져옴
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? '게시글 작성 실패');
    }
  }
}