import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'public_profile_page.dart';
import 'articles/article_viewer.dart';
import 'games/html_game_player.dart';
import 'novels/novel_details_page.dart';
import 'app_details_page.dart';
import 'auth/login_screen.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildLoggedOutView(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات والتفاعلات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, size: 20),
            onPressed: () {
              // ✅ تحديد الكل كمقروء
              FirestoreService().markAllNotificationsAsRead(user.uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
              );
            },
            tooltip: 'تحديد الكل كمقروء',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              return _buildNotificationCard(context, d, docs[index].id, user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data, String notifId, String currentUserId) {
    String type = data['type'] ?? '';
    String fromName = data['fromUserName'] ?? 'مبدع';
    String postTitle = data['postTitle'] ?? '';
    bool isRead = data['isRead'] ?? false;
    Timestamp? ts = data['createdAt'] as Timestamp?;
    String time = ts != null ? DateFormat('HH:mm - yyyy/MM/dd').format(ts.toDate()) : '';

    IconData icon;
    Color color;
    String message;

    if (type == 'like') {
      icon = Icons.favorite;
      color = Colors.redAccent;
      message = 'أعجب "$fromName" بعملك "$postTitle"';
    } else if (type == 'follow') {
      icon = Icons.person_add;
      color = Colors.blueAccent;
      message = 'بدأ "$fromName" بمتابعتك الآن!';
    } else if (type == 'new_post') {
      icon = Icons.auto_awesome;
      color = Colors.amber;
      message = 'نشر "$fromName" عملاً جديداً يستحق المشاهدة';
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
      message = 'لديك تنبيه جديد من أرتياتك';
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.transparent : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRead ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(message, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13, height: 1.4)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
        onTap: () async {
          // ✅ تعليم كمقروء
          FirestoreService().markNotificationAsRead(currentUserId, notifId);
          
          if (type == 'follow') {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PublicProfilePage(userId: data['fromUserId'], username: fromName)
            ));
          } else if (data['postId'] != null) {
            // جلب العمل وعرضه
            final doc = await FirebaseFirestore.instance.collection('posts').doc(data['postId']).get();
            if (doc.exists && context.mounted) {
              _openPost(context, doc.data() as Map<String, dynamic>, doc.id);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، هذا العمل لم يعد متاحاً أو تم حذفه.')));
            }
          }
        },
      ),
    );
  }

  void _openPost(BuildContext context, Map<String, dynamic> data, String id) {
    String type = data['type'] ?? '';
    if (type == 'game_html') {
      final String gameSource = (data['source'] == 'blogger' || (data['link'] ?? '').isNotEmpty)
          ? (data['link'] ?? '') : (data['content'] ?? '');
      Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlGamePlayer(title: data['title'] ?? '', htmlContent: gameSource, description: data['description'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    } else if (type == 'novel') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailsPage(novelId: id, title: data['title'] ?? '', imageUrl: data['thumbnailUrl'] ?? '')));
    } else if (type == 'app_apk') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AppDetailsPage(appId: id, data: data)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleViewer(title: data['title'] ?? '', content: data['content'] ?? '', link: data['link'] ?? '', publisher: data['authorName'] ?? '', createdAt: data['createdAt'])));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text('لا توجد تفاعلات جديدة حالياً', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('انشر المزيد من الإبداع لتجذب المعجبين! 🚀', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('يرجى تسجيل الدخول لعرض إشعاراتك وتفاعلاتك'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('تسجيل الدخول الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
