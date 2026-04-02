import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'chapter_reader_page.dart';

class NovelDetailsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final FirestoreService firestore = FirestoreService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('ابدأ القراءة'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('تحميل الرواية'),
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

          StreamBuilder<QuerySnapshot>(
            stream: firestore.getChapters(novelId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              if (snapshot.hasError)
                return const SliverToBoxAdapter(
                  child: Center(child: Text('خطأ في جلب الفصول')),
                );

              final chapters = snapshot.data?.docs ?? [];
              if (chapters.isEmpty)
                return const SliverToBoxAdapter(
                  child: Center(child: Text('هذه الرواية لا فصول لها بعد!')),
                );

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = chapters[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(child: Text('${data['number']}')),
                    title: Text(data['title'] ?? 'عنوان الفصل'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterReaderPage(
                            novelTitle: title,
                            chapterTitle: data['title'] ?? '',
                            content: data['content'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                }, childCount: chapters.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
