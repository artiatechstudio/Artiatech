import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_chapters_page.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import 'chapter_reader_page.dart';

class NovelDetailsPage extends StatefulWidget {
  final String novelId;
  final String title;
  final String imageUrl;

  const NovelDetailsPage({
    super.key,
    required this.novelId,
    required this.title,
    required this.imageUrl,
  });

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage> {
  final FirestoreService _firestore = FirestoreService();

  // ✅ الفصول مشتركة بين الأزرار وقائمة الفصول
  List<QueryDocumentSnapshot> _chapters = [];

  void _goToFirstChapter() {
    if (_chapters.isEmpty) return;
    final first = _chapters[0].data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterReaderPage(
          novelTitle: widget.title,
          chapterTitle: first['title'] ?? '',
          content: first['content'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── صورة الغلاف ──
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.menu_book, size: 80, color: Colors.white24),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── الأزرار ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        // ✅ مفعّل فقط بعد تحميل الفصول
                        onPressed: _chapters.isNotEmpty ? _goToFirstChapter : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('ابدأ القراءة'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        // ✅ إبلاغ المستخدم بدلاً من صمت تام
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تحميل الرواية سيتوفر قريباً إن شاء الله 📚'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('تحميل'),
                      ),
                      // ✅ زر "إضافة فصول": التحقق الذكي من صاحب الرواية الأصلي حتى لو كانت فارغة
                      if (context.read<UserProvider>().isAdmin)
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageChaptersPage(novelId: widget.novelId, novelTitle: widget.title))),
                          icon: const Icon(Icons.add_circle, color: Colors.amber),
                          tooltip: 'أضف فصلاً جديداً',
                        )
                      else if (FirebaseAuth.instance.currentUser != null)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('posts').doc(widget.novelId).get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              if ((snapshot.data!.data() as Map<String, dynamic>)['authorId'] == FirebaseAuth.instance.currentUser!.uid) {
                                return IconButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageChaptersPage(novelId: widget.novelId, novelTitle: widget.title))),
                                  icon: const Icon(Icons.add_circle, color: Colors.amber),
                                  tooltip: 'أضف فصلاً (كمؤلف)',
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'الفصول',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // ── قائمة الفصول ──
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.getChapters(
              widget.novelId, 
              isAdmin: context.read<UserProvider>().isAdmin // ✅ السماح للأدمن برؤية الفصول المعلقة للمراجعة
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('خطأ في جلب الفصول')),
                );
              }

              // ✅ تحديث القائمة المشتركة عند وصول البيانات
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final newChapters = snapshot.data?.docs ?? [];
                if (newChapters.length != _chapters.length) {
                  setState(() => _chapters = newChapters);
                }
              });

              final chapters = snapshot.data?.docs ?? [];
              if (chapters.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('هذه الرواية لا فصول لها بعد!')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = chapters[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${data['number']}')),
                      title: Text(data['title'] ?? 'عنوان الفصل'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderPage(
                              novelTitle: widget.title,
                              chapterTitle: data['title'] ?? '',
                              content: data['content'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: chapters.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
