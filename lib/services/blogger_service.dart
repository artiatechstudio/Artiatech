import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class BloggerService {
  static const String bloggerUrl = 'https://artiatechstudio.com.ly';
  
  Future<List<ArticleModel>> fetchPosts({int maxResults = 10}) async {
    final url = Uri.parse('$bloggerUrl/feeds/posts/default?alt=json&max-results=$maxResults');
    return _fetchFromUrl(url);
  }

  Future<List<ArticleModel>> fetchPostsByLabel(String label, {int maxResults = 10}) async {
    final encodedLabel = Uri.encodeComponent(label);
    final url = Uri.parse('$bloggerUrl/feeds/posts/default/-/$encodedLabel?alt=json&max-results=$maxResults');
    return _fetchFromUrl(url);
  }

  Future<List<ArticleModel>> _fetchFromUrl(Uri url) async {
    try {
      Uri finalUrl = url;
      if (kIsWeb) {
        // حماية متصفح الويب (CORS) تمنع جلب البيانات مباشرة من بلوغر، لذلك نستخدم Proxy للتمكن من الاختبار.
        // لن تحتاج هذا الكود في الأندرويد اطلاقاً.
        final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url.toString())}';
        finalUrl = Uri.parse(proxyUrl);
      }
      
      final response = await http.get(finalUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feed = data['feed'];
        if (feed == null || feed['entry'] == null) return [];
        
        List items = feed['entry'];
        return items.map((item) => ArticleModel.fromBloggerJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load blogger posts');
      }
    } catch (e) {
      debugPrint('Blogger fetch error: $e');
      return [];
    }
  }
}
