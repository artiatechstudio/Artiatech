import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات والتفاعلات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, size: 20),
            onPressed: () {
              // منطق "تحديد الكل كمقروء" (مستقبلاً)
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
              return _buildNotificationCard(context, d);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data) {
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
        onTap: () {
          // منطق الانتقال للعمل أو الملف الشخصي (مستقبلاً)
        },
      ),
    );
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
}
