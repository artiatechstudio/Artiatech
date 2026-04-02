import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/blogger_service.dart';
import '../models/article_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final BloggerService _blogger = BloggerService();
  bool _isSyncing = false;
  List<ArticleModel> _bloggerPosts = [];
  bool _loadingBlogger = false;
  final Map<String, String> _selectedTypes = {};
  String _userSearchQuery = '';

  final Map<String, String> _typeOptions = {
    'art': '🎨 فني حصري (Arts)',
    'tech': '💻 مشروع تقني (Tech)',
    'article': '📝 مقالة / تدوينة',
    'game_html': '🎮 لعبة HTML / سكراتش',
    'app_apk': '📱 تطبيق أندرويد (APK)',
    'novel': '📖 رواية',
  };

  @override
  void initState() {
    super.initState();
    _loadBloggerPosts();
  }

  Future<void> _loadBloggerPosts() async {
    setState(() => _loadingBlogger = true);
    try {
      final posts = await _blogger.fetchPosts(maxResults: 30);
      setState(() { _bloggerPosts = posts; _loadingBlogger = false; });
    } catch (e) { setState(() => _loadingBlogger = false); }
  }

  void _approvePost(String postId, String authorId) async {
    // 1. الموافقة على المنشور
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({'status': 'approved'});
    // 2. ترقية الناشر ليصبح موثوقاً (Logic Leap)
    if (authorId != 'Blogger_Admin') {
      await FirebaseFirestore.instance.collection('users').doc(authorId).update({'isTrusted': true});
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة وترقية الناشر لموثوق!')));
  }

  void _toggleUserTrust(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'isTrusted': !currentStatus});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الثقة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة المركزية'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.sync), text: 'استيراد بلوجر'),
            Tab(icon: Icon(Icons.pending_actions), text: 'طلبات النشر'),
            Tab(icon: Icon(Icons.people_outline), text: 'المبدعين'),
          ]),
        ),
        body: TabBarView(children: [
          _buildBloggerTab(),
          _buildRequestsTab(),
          _buildUsersTab(),
        ]),
      ),
    );
  }

  Widget _buildBloggerTab() {
    if (_loadingBlogger) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _bloggerPosts.length,
      itemBuilder: (context, i) {
        final p = _bloggerPosts[i];
        return Card(
          margin: const EdgeInsets.all(10),
          child: Column(children: [
            ListTile(title: Text(p.title), subtitle: Text('بواسطة: ${p.authorName}')),
            DropdownButton<String>(
              value: _selectedTypes[p.title] ?? 'article',
              items: _typeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _selectedTypes[p.title] = v!),
            ),
            ElevatedButton(onPressed: _isSyncing ? null : () => _importToBlogger(p), child: const Text('تأكيد الاستيراد لفايرستور')),
          ]),
        );
      },
    );
  }

  void _importToBlogger(ArticleModel post) async {
    setState(() => _isSyncing = true);
    String type = _selectedTypes[post.title] ?? 'article';
    await FirebaseFirestore.instance.collection('posts').add({
      'title': post.title, 'titleLower': post.title.toLowerCase(), 'content': post.content, 'source': 'blogger',
      'thumbnailUrl': post.thumbnailUrl, 'authorName': post.authorName, 'type': type, 'status': 'approved', 'link': post.link, 'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() { _bloggerPosts.removeWhere((p) => p.title == post.title); _isSyncing = false; });
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة حالياً'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(d['title'] ?? ''),
              subtitle: Text('النوع: ${d['type']}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approvePost(docs[i].id, d['authorId'] ?? '')),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => docs[i].reference.delete()),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: 'ابحث عن اسم المستخدم...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _userSearchQuery = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').orderBy('username').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final users = snap.data!.docs.where((u) => (u['username'] ?? '').toString().toLowerCase().contains(_userSearchQuery)).toList();
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i].data() as Map<String, dynamic>;
                bool isTr = u['isTrusted'] ?? false;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u['username'] ?? 'مبدع'),
                  subtitle: Text(isTr ? '✅ موثوق' : '👤 عضو'),
                  trailing: Switch(value: isTr, onChanged: (v) => _toggleUserTrust(users[i].id, isTr)),
                );
              },
            );
          },
        ),
      )
    ]);
  }
}
