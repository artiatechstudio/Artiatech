class ArticleModel {
  final String id;
  final String title;
  final String content;
  final String description;
  final String authorName;
  final String authorImage;
  final String publishedDate;
  final String link;
  final String? thumbnailUrl;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.description,
    required this.authorName,
    required this.authorImage,
    required this.publishedDate,
    required this.link,
    this.thumbnailUrl,
  });

  factory ArticleModel.fromBloggerJson(Map<String, dynamic> json) {
    String id = json['id']?['\$t'] ?? '';
    String title = json['title']?['\$t'] ?? '';
    String content = json['content']?['\$t'] ?? '';
    String publishedDate = json['published']?['\$t'] ?? '';

    // استخراج النصوص من المحتوى للوصف
    String plainText = _extractTextFromHtml(content);
    String description = plainText.length > 150
        ? plainText.substring(0, 150)
        : plainText;

    // Author
    var authorList = json['author'] as List?;
    String authorName = 'Unknown';
    String authorImage = 'https://via.placeholder.com/50';
    if (authorList != null && authorList.isNotEmpty) {
      authorName = authorList[0]['name']?['\$t'] ?? 'Unknown';
      authorImage =
          authorList[0]['gd\$image']?['src'] ??
          'https://via.placeholder.com/50';
      if (authorImage.startsWith('//')) {
        authorImage = 'https:$authorImage';
      }
    }

    // Thumbnail
    String? thumbnailUrl = json['media\$thumbnail']?['url'];

    // Link
    var links = json['link'] as List?;
    String link = '';
    if (links != null) {
      for (var l in links) {
        if (l['rel'] == 'alternate') {
          link = l['href'] ?? '';
          break;
        }
      }
    }

    return ArticleModel(
      id: id,
      title: title,
      content: content,
      description: description,
      authorName: authorName,
      authorImage: authorImage,
      publishedDate: publishedDate,
      link: link,
      thumbnailUrl: thumbnailUrl,
    );
  }

  factory ArticleModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ArticleModel(
      id: docId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      description: data['description'] ?? '',
      authorName: data['authorName'] ?? 'كاتب مجهول',
      authorImage: data['authorImage'] ?? 'https://via.placeholder.com/50',
      publishedDate: data['publishedDate'] ?? '',
      link: data['link'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  static String _extractTextFromHtml(String html) {
    // إزالة tags HTML بسيطة
    final RegExp exp = RegExp(
      r'<[^>]*>',
      multiLine: true,
      caseSensitive: false,
    );
    return html.replaceAll(exp, '').trim();
  }
}
