import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/post_card.dart';
import 'auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'legal_page.dart';
import 'about_page.dart';
import 'help_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  void _shareApp(String? username) {
    String name = username ?? 'مبدع أرتياتك';
    Share.share('🚀 انضم إلى "$name" في أرتياتك ستوديو! عالم من الإبداع التقني والألعاب والقصص بانتظارك. حمله الآن وكن جزءاً من المستقبل: https://artiatechstudio.com.ly');
  }

  void _confirmDelete(BuildContext context, String postId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "$title" نهائياً من المنصة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().deletePost(postId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العمل بنجاح')));
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
    final userProvider = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirestoreService();

    if (user == null) return _buildLoggedOutView(context);
    if (userProvider.isLoading) return const Center(child: CircularProgressIndicator());

    final data = userProvider.profileData ?? {};

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      children: [
        _buildAvatarHeader(context, user.uid, data),
        const SizedBox(height: 15),
        Center(child: Text(data['username'] ?? 'مبدع أرتياتك', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        Center(child: Text(data['bio'] ?? 'إلى اللانهاية وما بعدها! 🚀', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        const SizedBox(height: 30),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('متابعون', data['followersCount'] ?? 0),
            _buildStatCard('أتابع', data['followingCount'] ?? 0),
          ],
        ),
        const SizedBox(height: 40),

        _buildSectionTitle('أعمالك المنشورة (إدارة)'),
        _buildHorizontalList(context, firestore.getPostsByUser(user.uid), userProvider, isAuthor: true),

        _buildSectionTitle('المعرض الشخصي'),
        _buildHorizontalList(context, firestore.getSavedPosts(data['gallery'] ?? []), userProvider),

        const SizedBox(height: 40),
        const Divider(),
        
        if (userProvider.isAdmin)
          _buildActionItem(context, Icons.admin_panel_settings, 'لوحة تحكم المشرف', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
          
        _buildActionItem(context, Icons.share, 'مشاركة التطبيق مع الأصدقاء', Colors.blue, () => _shareApp(data['username'])),
        _buildActionItem(context, Icons.help_outline, 'مركز التعليمات (دليل المستخدم)', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()))),
        _buildActionItem(context, Icons.info_outline, 'من نحن (فلسفة أرتياتك)', Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))),
        _buildActionItem(context, Icons.gavel, 'سياسة الخصوصية والشروط', Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage()))),
        _buildActionItem(context, Icons.bug_report, 'الإبلاغ عن مشكلة / اقتراح', Colors.orange, () {
           const phone = "+218929196425";
           _launchUrl(context, "https://wa.me/$phone?text=مرحباً أرتياتك، أود الإبلاغ عن:");
        }),

        const SizedBox(height: 30),
        _buildSectionTitle('تجدنا على التواصل الاجتماعي'),
        _buildSocialGrid(context),

        const SizedBox(height: 40),
        _buildLogoutButton(context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAvatarHeader(BuildContext context, String uid, Map<String, dynamic> data) {
    return Center(child: AvatarWidget(userId: uid, base64String: data['avatarBase64'], radius: 50));
  }

  Widget _buildStatCard(String label, int count) {
    return Column(children: [Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }

  Widget _buildSocialGrid(BuildContext context) {
    const socialLinks = {'Insta': 'https://www.instagram.com/artiatechstudio', 'X': 'https://twitter.com/artiatechstudio', 'YouTube': 'https://www.youtube.com/@artiatechstudio', 'FB': 'https://www.facebook.com/artiatechstudio', 'WA Channel': 'https://whatsapp.com/channel/0029VbBNHwi9mrGjTo79LV3u'};
    return Wrap(spacing: 12, runSpacing: 12, children: socialLinks.entries.map((e) => GestureDetector(onTap: () => _launchUrl(context, e.value), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(15)), child: Text(e.key, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))))).toList());
  }

  Widget _buildHorizontalList(BuildContext context, Stream<QuerySnapshot> stream, UserProvider userProvider, {bool isAuthor = false}) {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('هذه القائمة فارغة', style: TextStyle(color: Colors.grey, fontSize: 12)));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
               final d = docs[index].data() as Map<String, dynamic>;
               final postId = docs[index].id;
               return Padding(
                 padding: const EdgeInsets.only(right: 12),
                 child: Stack(
                   children: [
                     PostCard(title: d['title'] ?? '', publisher: d['authorName'] ?? '', imageUrl: d['thumbnailUrl'] ?? '', likes: (d['likesCount']as num?)?.toInt() ?? 0, onDownload: () {}, onTap: () {}),
                     if (isAuthor || userProvider.isAdmin)
                       Positioned(
                         top: 5, left: 5,
                         child: GestureDetector(
                           onTap: () => _confirmDelete(context, postId, d['title'] ?? ''),
                           child: const CircleAvatar(radius: 14, backgroundColor: Colors.redAccent, child: Icon(Icons.delete, size: 16, color: Colors.white)),
                         ),
                       ),
                   ],
                 ),
               );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout, color: Colors.redAccent), label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_outline, size: 80, color: Colors.grey), const SizedBox(height: 20), const Text('يرجى تسجيل الدخول لعرض ملفك الشخصي'), const SizedBox(height: 30), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('تسجيل الدخول الآن'))]));
  }
}
