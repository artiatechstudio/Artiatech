import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../services/firestore_service.dart';
import '../screens/novels/novel_details_page.dart';
import '../screens/games/html_game_player.dart';
import '../screens/app_details_page.dart';
import '../screens/public_profile_page.dart';
import '../screens/articles/article_viewer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<DocumentSnapshot> _postsResults = [];
  List<DocumentSnapshot> _usersResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _postsResults = []; _usersResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final postsSnap = await _firestore.searchPosts(query);
      final usersSnap = await _firestore.searchUsers(query);
      setState(() { _postsResults = postsSnap.docs; _usersResults = usersSnap.docs; _isSearching = false; });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استكشف أرتياتك'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'الأعمال والإبداعات'), Tab(text: 'المبدعين والناشرين')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'عن ماذا تبحث اليوم؟...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: TabBarView(controller: _tabController, children: [_buildPostsList(), _buildUsersList()])),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_postsResults.isEmpty) return _buildEmptyState('لا توجد أعمال مطابقة لبحثك حالياً');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _postsResults.length,
      itemBuilder: (context, index) {
        final data = _postsResults[index].data() as Map<String, dynamic>;
        final id = _postsResults[index].id;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: _buildThumbnail(data['thumbnailUrl'] ?? ''),
            title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('النوع: ${data['type']} | الناشر: ${data['authorName']}', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showPostDetails(data, id),
          ),
        );
      },
    );
  }

  Widget _buildUsersList() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_usersResults.isEmpty) return _buildEmptyState('لم نعثر على ناشر بهذا الاسم');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _usersResults.length,
      itemBuilder: (context, index) {
        final data = _usersResults[index].data() as Map<String, dynamic>;
        final userId = _usersResults[index].id;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(data['username'] ?? 'مستخدم مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(data['role'] ?? 'ناشر في أرتياتك', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: userId, username: data['username'] ?? ''))),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(String thumbnailUrl) {
    if (thumbnailUrl.isEmpty) return const Icon(Icons.image);
    if (thumbnailUrl.startsWith('http')) return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(thumbnailUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)));
    try { return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(thumbnailUrl), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))); } catch (e) { return const Icon(Icons.image); }
  }

  Widget _buildEmptyState(String msg) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.search_off, size: 60, color: Colors.grey), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey))])); }

  void _showPostDetails(Map<String, dynamic> data, String id) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 10),
        Text(data['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(data['description'] ?? 'لا يوجد وصف متاح.', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _openPost(data, id); },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text('بدء العرض / التجربة', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _openPost(Map<String, dynamic> data, String id) {
    String type = data['type'] ?? '';
    if (type == 'game_html') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlGamePlayer(title: data['title'] ?? '', htmlContent: data['content'] ?? '', description: data['description'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    } else if (type == 'article') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleViewer(title: data['title'] ?? '', content: data['content'] ?? '', link: data['link'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    } else if (type == 'app_apk') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailsPage(appId: id, data: data)));
    } else if (type == 'novel') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailsPage(novelId: id, title: data['title'] ?? '', imageUrl: data['thumbnailUrl'] ?? '')));
    }
  }
}
