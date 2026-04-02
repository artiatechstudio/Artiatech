import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/horizontal_section.dart';

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
                   _buildStat('متابعون', data['followersCount'] ?? 0),
                   _buildStat('أتابع', data['followingCount'] ?? 0),
                ],
              ),

              const SizedBox(height: 30),

              if (currentUser != null && currentUser!.uid != widget.userId)
                ElevatedButton(
                  onPressed: () async {
                    await _firestore.followUser(currentUser!.uid, widget.userId);
                    
                    // إرسال إشعار متابعة (Logic Leap)
                    await _firestore.sendInAppNotification(
                      targetUserId: widget.userId,
                      fromUserId: currentUser!.uid,
                      fromUserName: context.read<UserProvider>().profileData?['username'] ?? 'مبدع',
                      type: 'follow',
                    );

                    setState(() => _isFollowing = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey : Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(_isFollowing ? 'أنت تتابع هذا المبدع' : 'متابعة الناشر', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 40),
              const Divider(),
              
              HorizontalSection(
                title: '🎨 إبداعات ${widget.username}',
                streamItems: _firestore.getPostsByUser(widget.userId, type: 'art'),
              ),

              HorizontalSection(
                title: '💻 مشاريع تقنية',
                streamItems: _firestore.getPostsByUser(widget.userId, type: 'tech'),
              ),

              const SizedBox(height: 20),
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

  Widget _buildStat(String label, int count) {
    return Column(children: [Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]);
  }
}
