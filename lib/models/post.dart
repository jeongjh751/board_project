class Post {
  final int id;
  final String title;
  final String content;
  final String author;
  final String createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: _parseInt(json['id']),
      title: _parseString(json['title']),
      content: _parseString(json['content']),
      author: _parseString(json['author']),
      createdAt: _parseString(json['created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}