import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/horizontal_section.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';

class ArtsPage extends StatelessWidget {
  const ArtsPage({super.key});

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
            title: '🎨 رائج في المعرض',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('art', isAdmin: userProvider.isAdmin),
          ),
          HorizontalSection(
            title: '🤝 تتابعه', 
            emptyFollowingMsg: userProvider.followingIds.isEmpty,
            streamItems: firestore.getFollowingPosts(userProvider.followingIds),
          ),
          HorizontalSection(
            title: '✨ أحدث الإبداعات',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('art', isAdmin: userProvider.isAdmin),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
