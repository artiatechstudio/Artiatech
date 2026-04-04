import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/horizontal_section.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب البيانات من المحرك المركزي (Logic Leap)
    final userProvider = context.watch<UserProvider>();
    final firestore = FirestoreService();

    return RefreshIndicator(
      onRefresh: () async {
        await userProvider.refreshUserContext();
      },
      child: ListView(
        children: [
          // 0. إعلانات الإدارة
          HorizontalSection(
            title: '📢 إعلانات وتحديثات منصة أرتياتك',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getPosts('announcement', isAdmin: userProvider.isAdmin),
          ),

          // 1. رائج (Featured)
          HorizontalSection(
            title: '🔥 رائج الآن',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getFeaturedPosts(isAdmin: userProvider.isAdmin),
          ),

          // 2. تتابع (Following) - منطق ذكي: لا نطلب البيانات إذا كانت قائمة المتابعة فارغة
          HorizontalSection(
            title: '🤝 تتابعهم',
            emptyFollowingMsg: userProvider.followingIds.isEmpty,
            streamItems: firestore.getFollowingPosts(userProvider.followingIds),
          ),

          // 3. الأحدث (Latest)
          HorizontalSection(
            title: '🆕 الأحدث في أرتياتك',
            isAdmin: userProvider.isAdmin,
            streamItems: firestore.getLatestPosts(isAdmin: userProvider.isAdmin),
          ),
          
          const SizedBox(height: 100), // مساحة لشريط التنقل العائم
        ],
      ),
    );
  }
}
