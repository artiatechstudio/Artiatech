import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'post_card.dart';
import '../models/article_model.dart';
import '../screens/search_page.dart';
import '../screens/profile_page.dart';
import '../screens/novels/novel_details_page.dart';
import '../screens/games/html_game_player.dart';
import '../screens/app_details_page.dart';
import '../screens/articles/article_viewer.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';

class HorizontalSection extends StatelessWidget {
  final String title;
  final bool emptyFollowingMsg;
  final bool isAdmin;
  final VoidCallback? onSearchTap;
  final Future<List<ArticleModel>>? futureItems;
  final Stream<QuerySnapshot>? streamItems;
  final FirestoreService _firestore = FirestoreService();

  HorizontalSection({
    super.key,
    required this.title,
    this.emptyFollowingMsg = false,
    this.isAdmin = false,
    this.onSearchTap,
    this.futureItems,
    this.streamItems,
  });

  void _saveTo(BuildContext context, String postId, String title, String collection) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }
    await _firestore.savePostToCollection(user.uid, postId, collection);
    if (context.mounted) {
      String msg = collection == 'library' ? 'تمت الإضافة للمكتبة' : 'تمت الإضافة للمعرض';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg: $title')));
    }
  }

  void _showDownloadOptions(BuildContext context, String postId, String workTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('حفظ في مجموعتك', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('أين تريد إضافة "$workTitle"؟'),
        actions: [
          ListTile(leading: const Icon(Icons.grid_view, color: Colors.blueAccent), title: const Text('في المعرض (المفضلة)'), onTap: () { Navigator.pop(context); _saveTo(context, postId, workTitle, 'gallery'); }),
          ListTile(leading: const Icon(Icons.library_books, color: Colors.teal), title: const Text('في المكتبة الشخصية'), onTap: () { Navigator.pop(context); _saveTo(context, postId, workTitle, 'library'); }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String postId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المحتوى'),
        content: Text('هل تريد حذف "$title"؟ لا يمكن لمن استلمه من قبل رؤيته مجدداً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.deletePost(postId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (emptyFollowingMsg)
          _buildEmptyFollowing(context)
        else
          SizedBox(
            height: 230,
            child: streamItems != null 
              ? StreamBuilder<QuerySnapshot>(stream: streamItems, builder: (context, snapshot) => _buildListFromDocs(context, snapshot))
              : FutureBuilder<List<ArticleModel>>(future: futureItems, builder: (context, snapshot) => _buildListFromFuture(context, snapshot)),
          ),
      ],
    );
  }

  Widget _buildEmptyFollowing(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Text('نحن نشجعك على متابعة المبدعين لتظهر أعمالهم هنا!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: onSearchTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('استكشف المبدعين الآن'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )
        ],
      ),
    );
  }

  Widget _buildListFromDocs(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmer(context);
    if (snapshot.hasError) return const Center(child: Text('خطأ تقني'));
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) return const Center(child: Text('لا توجد عناصر حالياً', style: TextStyle(color: Colors.grey)));

    final userProvider = context.watch<UserProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final id = docs[index].id;
        final authorId = data['authorId'] ?? '';
        bool canDelete = userProvider.isAdmin || (currentUser != null && currentUser.uid == authorId);

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Stack(
            children: [
              PostCard(
                title: data['title'] ?? '',
                publisher: data['authorName'] ?? '',
                imageUrl: data['thumbnailUrl'] ?? '',
                likes: (data['likesCount'] as num?)?.toInt() ?? 0,
                onDownload: () => _showDownloadOptions(context, id, data['title'] ?? ''),
                onTap: () => _showPostDetails(context, data, id),
              ),
              if (canDelete)
                Positioned(
                  top: 5, left: 5,
                  child: GestureDetector(
                    onTap: () => _confirmDelete(context, id, data['title'] ?? ''),
                    child: const CircleAvatar(radius: 14, backgroundColor: Colors.redAccent, child: Icon(Icons.delete, size: 16, color: Colors.white)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListFromFuture(BuildContext context, AsyncSnapshot<List<ArticleModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmer(context);
    final items = snapshot.data ?? [];
    if (items.isEmpty) return const Center(child: Text('جاري جلب البيانات...'));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PostCard(
          title: item.title,
          publisher: item.authorName,
          imageUrl: item.thumbnailUrl ?? '',
          likes: 150 + index,
          onDownload: () => _saveTo(context, item.id, item.title, 'library'),
          onTap: () => _showPostDetailsFallback(context, item),
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, _) => Container(width: 170, margin: const EdgeInsets.only(left: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  void _showPostDetails(BuildContext context, Map<String, dynamic> data, String id) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 25),
        Text(data['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(data['description'] ?? 'وصف مختصر غير متاح لهذا العمل حالياً.', style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _openPost(context, data, id); },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('دخول الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 15),
            Container(
              height: 55, width: 55,
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: IconButton(
                icon: Icon(
                  (data['likes'] as List?)?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false 
                    ? Icons.favorite : Icons.favorite_border,
                  color: Colors.redAccent,
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجل دخول للإعجاب بالأعمال!')));
                    return;
                  }
                  await _firestore.likePost(
                    user.uid, id, data['authorId'] ?? '', 
                    data['title'] ?? '', 
                    context.read<UserProvider>().profileData?['username'] ?? 'مبدع أرتياتك'
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _openPost(BuildContext context, Map<String, dynamic> data, String id) {
    String type = data['type'] ?? '';
    if (type == 'novel') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailsPage(novelId: id, title: data['title'] ?? '', imageUrl: data['thumbnailUrl'] ?? '')));
    } else if (type == 'game_html') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlGamePlayer(title: data['title'] ?? '', htmlContent: data['content'] ?? '', description: data['description'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    } else if (type == 'app_apk') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailsPage(appId: id, data: data)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleViewer(title: data['title'] ?? '', content: data['content'] ?? '', link: data['link'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    }
  }

  void _showPostDetailsFallback(BuildContext context, ArticleModel item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleViewer(title: item.title, content: item.content, link: item.link, publisher: item.authorName, createdAt: null)));
  }
}
