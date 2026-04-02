import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/horizontal_section.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import 'apk_store_page.dart';

class TechPage extends StatelessWidget {
  const TechPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final firestore = FirestoreService();

    return RefreshIndicator(
      onRefresh: () async {
        await userProvider.refreshUserContext();
      },
      child: ListView(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApkStorePage())),
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [Colors.purpleAccent.withValues(alpha: 0.8), Colors.blueAccent.withValues(alpha: 0.8)]),
                boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 5))],
              ),
              child: Stack(
                children: [
                   Positioned(right: 20, top: 20, child: Icon(Icons.shop_two, size: 80, color: Colors.white.withValues(alpha: 0.2))),
                   const Center(child: Text('متجر التطبيقات والألعاب', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
          ),
          HorizontalSection(
            title: '⚙️ الأكثر رواجاً التقنية',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('tech', isAdmin: userProvider.isAdmin),
          ),
          HorizontalSection(
            title: '🤝 تتابعه', 
            emptyFollowingMsg: userProvider.followingIds.isEmpty,
            streamItems: firestore.getFollowingPosts(userProvider.followingIds),
          ),
          HorizontalSection(
            title: '📲 أحدث الأخبار والمشاريع',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('tech', isAdmin: userProvider.isAdmin),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
