import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../providers/user_provider.dart';
import '../models/article_model.dart';

class ArtsPage extends StatefulWidget {
  const ArtsPage({super.key});

  @override
  State<ArtsPage> createState() => _ArtsPageState();
}

class _ArtsPageState extends State<ArtsPage> {
  // ملاحظة للمطور: يرجى استبدال YOUR_CHANNEL_ID_HERE بمعرف القناة الحقيقي UC...
  final String rssUrl = 'https://www.youtube.com/feeds/videos.xml?channel_id=UCvS-z9jGq0_vLzQW9u-Hw8Q'; // مثال افتراضي

  Future<List<ArticleModel>> fetchYoutubeVideos() async {
    try {
      // قناة artiatechstudio
      // سنحاول جلب البيانات مباشرة عبر RSS
      final response = await http.get(Uri.parse('https://www.youtube.com/feeds/videos.xml?user=artiatechstudio'));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');
        
        return entries.map((entry) {
          final title = entry.findElements('title').first.innerText;
          final link = entry.findElements('link').first.getAttribute('href') ?? '';
          final videoId = entry.findElements('yt:videoId').first.innerText;
          final author = entry.findElements('author').first.findElements('name').first.innerText;
          
          return ArticleModel(
            id: videoId,
            title: title,
            content: '',
            description: 'فيديو من قناة أرتياتك ستوديو على يوتيوب',
            authorName: author,
            authorImage: 'https://www.youtube.com/favicon.ico',
            publishedDate: entry.findElements('published').first.innerText,
            link: link,
            thumbnailUrl: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Youtube fetch error: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await userProvider.refreshUserContext();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('قناة أرتياتك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_filled, size: 80, color: Colors.white24),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@artiatechstudio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('شروحات تقنية وحلول برمجية', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _launchURL('https://youtube.com/@artiatechstudio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('اشتراك'),
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<ArticleModel>>(
              future: fetchYoutubeVideos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())));
                }
                final videos = snapshot.data ?? [];
                if (videos.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد فيديوهات حالياً أو تأكد من الاتصال'))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildVideoCard(context, videos[index], isDark),
                    childCount: videos.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, ArticleModel video, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => _launchURL(video.link),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl!,
                height: 200, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black12, height: 200),
                errorWidget: (_, __, ___) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(video.authorName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

