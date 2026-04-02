import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/blogger_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BloggerService _blogger = BloggerService();

  // 1. استرجاع المنشورات حسب النوع (مع دعم المعاينة للأدمن)
  Stream<QuerySnapshot> getPosts(String type, {bool isAdmin = false}) {
    Query query = _db.collection('posts').where('type', isEqualTo: type);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 2. جلب أحدث المنشورات
  Stream<QuerySnapshot> getLatestPosts({bool isAdmin = false}) {
    Query query = _db.collection('posts').orderBy('createdAt', descending: true);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 3. جلب المنشورات الرائجة
  Stream<QuerySnapshot> getFeaturedPosts({bool isAdmin = false}) {
    Query query = _db.collection('posts').where('isFeatured', isEqualTo: true);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 4. جلب منشورات المبدعين الذين أتابعهم
  Stream<QuerySnapshot> getFollowingPosts(List<dynamic> followingIds) {
    if (followingIds.isEmpty) return const Stream.empty();
    return _db.collection('posts')
        .where('authorId', whereIn: followingIds.take(10).toList())
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 5. جلب منشورات مستخدم معين (للملف الشخصي العام)
  Stream<QuerySnapshot> getPostsByUser(String userId, {String? type}) {
    Query query = _db.collection('posts').where('authorId', isEqualTo: userId);
    if (type != null) query = query.where('type', isEqualTo: type);
    return query.snapshots();
  }

  // 6. البحث عن الأعمال والمستخدمين
  Future<QuerySnapshot> searchPosts(String query) {
    String q = query.toLowerCase();
    return _db.collection('posts')
        .where('status', isEqualTo: 'approved')
        .where('titleLower', isGreaterThanOrEqualTo: q)
        .where('titleLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(20)
        .get();
  }

  Future<QuerySnapshot> searchUsers(String query) {
    String q = query.toLowerCase();
    return _db.collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: q)
        .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(20)
        .get();
  }

  // 7. المتابعة والحفظ
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _db.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId]),
      'followingCount': FieldValue.increment(1)
    });
    await _db.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId]),
      'followersCount': FieldValue.increment(1)
    });
  }

  Future<void> savePostToCollection(String userId, String postId, String collectionName) async {
    await _db.collection('users').doc(userId).update({
      collectionName: FieldValue.arrayUnion([postId])
    });
  }

  Stream<QuerySnapshot> getSavedPosts(List<dynamic> postIds) {
    if (postIds.isEmpty) return const Stream.empty();
    return _db.collection('posts')
        .where(FieldPath.documentId, whereIn: postIds.take(10).toList())
        .snapshots();
  }

  // 8. الملف الشخصي
  Future<void> updateAvatarBase64(String userId, String base64String) async {
    await _db.collection('users').doc(userId).update({'avatarBase64': base64String});
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // 9. الروايات والفصول
  Stream<QuerySnapshot> getChapters(String novelId, {bool isAdmin = false}) {
    Query query = _db.collection('posts').doc(novelId).collection('chapters').orderBy('number');
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  Future<void> addChapter(String novelId, int number, String title, String content, {bool isTrusted = false}) async {
    await _db.collection('posts').doc(novelId).collection('chapters').add({
      'number': number,
      'title': title,
      'content': content,
      'status': isTrusted ? 'approved' : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 10. الحذف القوي (Logic Leap: صلاحيات الحذف)
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // 11. منظومة الإشعارات التفاعلية (The Social Spark)
  Future<void> likePost(String userId, String postId, String authorId, String postTitle, String userName) async {
    final postRef = _db.collection('posts').doc(postId);
    
    // استخدام Transaction لضمان دقة العد
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      
      List likes = (snapshot.data() as Map<String, dynamic>)['likes'] ?? [];
      bool alreadyLiked = likes.contains(userId);
      
      if (!alreadyLiked) {
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1)
        });
        
        // إرسال إشعار للمستهدف (فقط عند الإعجاب الجديد)
        if (userId != authorId) {
          sendInAppNotification(
            targetUserId: authorId,
            fromUserId: userId,
            fromUserName: userName,
            type: 'like',
            postId: postId,
            postTitle: postTitle,
          );
        }
      } else {
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1)
        });
      }
    });
  }

  Future<void> sendInAppNotification({
    required String targetUserId,
    required String fromUserId,
    required String fromUserName,
    required String type, // 'like', 'follow', 'new_post'
    String? postId,
    String? postTitle,
  }) async {
    await _db.collection('users').doc(targetUserId).collection('notifications').add({
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'type': type,
      'postId': postId,
      'postTitle': postTitle,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _db.collection('users').doc(userId).collection('notifications')
        .orderBy('createdAt', descending: true).limit(30).snapshots();
  }
}
