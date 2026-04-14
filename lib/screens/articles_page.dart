import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/horizontal_section.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

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
          HorizontalSection(
            title: '📝 المقالات الأكثر رواجاً',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getTrendingPosts(type: 'article', isAdmin: userProvider.isAdmin),
          ),
          HorizontalSection(
            title: '🤝 تتابعهم', 
            emptyFollowingMsg: userProvider.followingIds.isEmpty,
            streamItems: firestore.getFollowingPosts(userProvider.followingIds),
          ),
          HorizontalSection(
            title: '💡 أحدث المقالات والروايات',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('article', isAdmin: userProvider.isAdmin),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
