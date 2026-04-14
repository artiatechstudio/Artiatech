import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/horizontal_section.dart';
import '../main.dart'; // Access soundNotifier

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String username;

  const PublicProfilePage({super.key, required this.userId, required this.username});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final FirestoreService _firestore = FirestoreService();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isFollowing = false;

  void _playClickEffect() {
    if (soundNotifier.value) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.getUserProfile(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _checkFollowing(data);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 10),
              Center(child: AvatarWidget(base64String: data['avatarBase64'], url: data['avatarUrl'], userId: widget.userId, radius: 55)),
              const SizedBox(height: 15),
              Center(child: Text(data['username'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              const SizedBox(height: 5),
              Center(child: Text(data['role'] ?? 'مبدع في أرتياتك', style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildStat(context, 'متابعون', data['followersCount'] ?? 0, data['followers'] ?? []),
                   _buildStat(context, 'أتابع', data['followingCount'] ?? 0, data['following'] ?? []),
                ],
              ),

              const SizedBox(height: 30),

              if (currentUser != null && currentUser!.uid != widget.userId)
                ElevatedButton(
                  onPressed: () async {
                    _playClickEffect();
                    if (_isFollowing) {
                      // الغاء المتابعة
                      await _firestore.unfollowUser(currentUser!.uid, widget.userId);
                      setState(() => _isFollowing = false);
                    } else {
                      // متابعة جديدة
                      await _firestore.followUser(currentUser!.uid, widget.userId);
                      await _firestore.sendInAppNotification(
                        targetUserId: widget.userId,
                        fromUserId: currentUser!.uid,
                        fromUserName: context.read<UserProvider>().profileData?['username'] ?? 'مبدع',
                        type: 'follow',
                      );
                      setState(() => _isFollowing = true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.redAccent.withOpacity(0.1) : Colors.blueAccent,
                    side: _isFollowing ? const BorderSide(color: Colors.redAccent, width: 1) : null,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _isFollowing ? 'إلغاء المتابعة' : 'متابعة الناشر', 
                    style: TextStyle(color: _isFollowing ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),

              const SizedBox(height: 40),
              const Divider(),
              
              // ✅ الأقسام المنشورة
              HorizontalSection(
                title: '🎨 أعماله المنشورة',
                streamItems: _firestore.getPostsByUser(widget.userId),
              ),

              // ✅ المعرض العام (المحفوظات التي شاركها أو حفظها)
              if ((data['gallery'] as List?)?.isNotEmpty ?? false)
                HorizontalSection(
                  title: '🖼️ معرض ${widget.username}',
                  streamItems: _firestore.getSavedPosts(data['gallery'] ?? []),
                ),

              const SizedBox(height: 100), // مساحة إضافية للتمرير
            ],
          );
        },
      ),
    );
  }

  void _checkFollowing(Map<String, dynamic> data) {
    if (currentUser == null) return;
    List followers = data['followers'] ?? [];
    _isFollowing = followers.contains(currentUser!.uid);
  }

  Widget _buildStat(BuildContext context, String label, int count, List ids) {
    return GestureDetector(
      onTap: () => _showUsersList(context, label, ids),
      child: Column(
        children: [
          Text(count.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  void _showUsersList(BuildContext context, String title, List ids) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                stream: _firestore.getUsersByIds(ids),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  List<QueryDocumentSnapshot> docs = [];
                  if (snap.data is QuerySnapshot) {
                    docs = (snap.data as QuerySnapshot).docs;
                  } else if (snap.data is List<QueryDocumentSnapshot>) {
                    docs = snap.data as List<QueryDocumentSnapshot>;
                  }
                  
                  if (docs.isEmpty) return const Center(child: Text('القائمة فارغة حالياً'));
                  
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final u = docs[idx].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: AvatarWidget(userId: docs[idx].id, base64String: u['avatarBase64'], url: u['avatarUrl'], radius: 20),
                        title: Text(u['username'] ?? ''),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: docs[idx].id, username: u['username'] ?? '')));
                        },
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
