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
      final posts = await _blogger.fetchPosts(maxResults: 200);
      setState(() {
        _bloggerPosts = posts;
        _loadingBlogger = false;
      });
    } catch (e) {
      setState(() => _loadingBlogger = false);
    }
  }

  void _approvePost(String postId, String authorId) async {
    // 1. الموافقة على المنشور
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'status': 'approved',
    });
    // 2. ترقية الناشر ليصبح موثوقاً (Logic Leap) لضمان سرعة النشر للمبدعين الحقيقيين
    if (authorId != 'Blogger_Admin' && authorId != 'artiatech_system') {
      await FirebaseFirestore.instance.collection('users').doc(authorId).update(
        {'isTrusted': true},
      );
    }
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة وترقية الناشر لموثوق!')),
      );
  }

  void _toggleUserTrust(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isTrusted': !currentStatus,
    });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الثقة بنجاح')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة المركزية'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.sync), text: 'استيراد بلوجر'),
              Tab(icon: Icon(Icons.pending_actions), text: 'طلبات النشر'),
              Tab(icon: Icon(Icons.people_outline), text: 'المبدعين'),
              Tab(icon: Icon(Icons.build), text: 'أدوات الإصلاح'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBloggerTab(), 
            _buildRequestsTab(), 
            _buildUsersTab(),
            _buildFixToolsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFixToolsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🛠️ أدوات الصيانة للمشرفين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildToolCard(
            title: 'تنشيط محرك البحث (Migration)',
            desc: 'يقوم بإضافة فهارس البحث للأعمال القديمة والمبدعين المسجلين سابقاً لتظهر في نتائج البحث الجديدة.',
            icon: Icons.search,
            onTap: _runSearchIndexingMigration,
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({required String title, required String desc, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.1), child: Icon(icon, color: Colors.blueAccent)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  void _runSearchIndexingMigration() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    try {
      int postCount = 0;
      int userCount = 0;

      // 1. تحديث المنشورات
      final posts = await FirebaseFirestore.instance.collection('posts').get();
      for (var doc in posts.docs) {
        final d = doc.data();
        String title = d['title'] ?? '';
        String content = d['content'] ?? '';
        String type = d['type'] ?? '';
        
        Map<String, dynamic> updates = {};
        
        // إضافة مفتاح البحث
        if (title.isNotEmpty) updates['titleLower'] = title.toLowerCase();
        
        // استخراج الـ iframe للألعاب القديمة
        if (type == 'game_html' && content.contains('<iframe')) {
          final iframeMatch = RegExp(r'<iframe[^>]*>.*?<\/iframe>|<iframe[^>]*/?>', caseSensitive: false, dotAll: true).firstMatch(content);
          if (iframeMatch != null) {
            updates['content'] = iframeMatch.group(0)!;
            updates['link'] = ''; // إفراغ الرابط لتعمل الحاوية المخصصة
          }
        }

        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
          postCount++;
        }
      }

      // 2. تحديث المستخدمين
      final users = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in users.docs) {
        final d = doc.data();
        String username = d['username'] ?? '';
        if (username.isNotEmpty) {
          await doc.reference.update({'usernameLower': username.toLowerCase()});
          userCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تمت الهجرة بنجاح! تم تحديث $postCount عمل و $userCount مستخدم.')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل التحديث: $e')));
      }
    }
  }

  Widget _buildBloggerTab() {
    if (_loadingBlogger)
      return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _bloggerPosts.length,
      itemBuilder: (context, i) {
        final p = _bloggerPosts[i];
        return Card(
          margin: const EdgeInsets.all(10),
          child: Column(
            children: [
              ListTile(
                title: Text(p.title),
                subtitle: Text('بواسطة: ${p.authorName}'),
              ),
              DropdownButton<String>(
                value: _selectedTypes[p.title] ?? 'article',
                items: _typeOptions.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTypes[p.title] = v!),
              ),
              ElevatedButton(
                onPressed: _isSyncing ? null : () => _importToBlogger(p),
                child: const Text('تأكيد الاستيراد لفايرستور'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _importToBlogger(ArticleModel post) async {
    setState(() => _isSyncing = true);
    String type = _selectedTypes[post.title] ?? 'article';

    // ✅ فحص التكرار: لا نستورد إذا كان الرابط موجوداً مسبقاً
    final existing = await FirebaseFirestore.instance
        .collection('posts')
        .where('link', isEqualTo: post.link)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ هذه المقالة موجودة مسبقاً في المنصة!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String finalContent = post.content;
    String finalLink = post.link;

    if (type == 'game_html') {
      final iframeMatch = RegExp(
        r'<iframe[^>]*>.*?<\/iframe>|<iframe[^>]*/?>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(post.content);
      if (iframeMatch != null) {
        finalContent = iframeMatch.group(0)!;
        // بالنسبة للألعاب، نفضل إفراغ الرابط لنجبر البرنامج على استخدام المحتوى المستخرج
        finalLink = ''; 
      }
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'title': post.title,
      'titleLower': post.title.toLowerCase(),
      'content': finalContent,
      'description': post.description,
      'source': 'blogger',
      'thumbnailUrl': post.thumbnailUrl,
      'authorName': post.authorName,
      'authorId': 'artiatech_system',
      'type': type,
      'status': 'approved',
      'link': finalLink,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _bloggerPosts.removeWhere((p) => p.title == post.title);
      _isSyncing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم الاستيراد بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text('لا توجد طلبات معلقة حالياً'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(d['title'] ?? ''),
              subtitle: Text('النوع: ${d['type']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _approvePost(docs[i].id, d['authorId'] ?? ''),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => docs[i].reference.delete(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'ابحث عن اسم المستخدم...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                setState(() => _userSearchQuery = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('username')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final users = snap.data!.docs
                  .where(
                    (u) => (u['username'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_userSearchQuery),
                  )
                  .toList();
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i].data() as Map<String, dynamic>;
                  bool isTr = u['isTrusted'] ?? false;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u['username'] ?? 'مبدع'),
                    subtitle: Text(isTr ? '✅ موثوق' : '👤 عضو'),
                    trailing: Switch(
                      value: isTr,
                      onChanged: (v) => _toggleUserTrust(users[i].id, isTr),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
