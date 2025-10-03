// lib/models/article.dart
class Article {
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String url;
  final String publishedAt;

  Article({
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.url,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      content: json['content'] ?? 'No Content',
      imageUrl: json['imageUrl'] ?? json['urlToImage'] ?? 'https://via.placeholder.com/300?text=No+Image',
      url: json['url'] ?? '',
      publishedAt: json['publishedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'url': url,
      'publishedAt': publishedAt,
    };
  }
}