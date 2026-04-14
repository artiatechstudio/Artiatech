import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ لتتبع بصمة المشاهدات محلياً ومنع التكرار

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. استرجاع المنشورات حسب النوع (مع حد أقصى للحفاظ على السرعة)
  Stream<QuerySnapshot> getPosts(String type, {bool isAdmin = false, int limit = 15}) {
    Query query = _db.collection('posts')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 2. جلب أحدث المنشورات (بحد أقصى 20 لتقليل الحمل)
  Stream<QuerySnapshot> getLatestPosts({bool isAdmin = false, int limit = 20}) {
    Query query = _db.collection('posts').orderBy('createdAt', descending: true).limit(limit);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 3. جلب المنشورات الرائجة (توب 5 حسب المشاهدات)
  Stream<QuerySnapshot> getTrendingPosts({String? type, bool isAdmin = false}) {
    Query query = _db.collection('posts')
        .orderBy('viewsCount', descending: true)
        .limit(5);
    
    if (type != null) query = query.where('type', isEqualTo: type);
    if (!isAdmin) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 4. جلب منشورات المبدعين الذين أتابعهم (تم الحل: تجاوز قيد الـ 10 باطراد)
  Stream<List<QueryDocumentSnapshot>> getFollowingPosts(List<dynamic> followingIds) async* {
    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    // تقسيم المعرفات لمجموعات كل مجموعة 10 (قيد فايرستور)
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < followingIds.length; i += 10) {
      chunks.add(followingIds.sublist(i, i + 10 > followingIds.length ? followingIds.length : i + 10));
    }

    List<Stream<QuerySnapshot>> streams = chunks.map((chunk) {
      return _db.collection('posts')
          .where('authorId', whereIn: chunk)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }).toList();

    // دمج النتائج يدوياً للحفاظ على الأداء
    await for (var snapshots in StreamZip(streams)) {
      List<QueryDocumentSnapshot> allDocs = [];
      for (var snap in snapshots) {
        allDocs.addAll(snap.docs);
      }
      // ترتيب زمني نهائي بعد الدمج
      allDocs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>?;
        final dataB = b.data() as Map<String, dynamic>?;
        Timestamp? ta = dataA?['createdAt'] as Timestamp?;
        Timestamp? tb = dataB?['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      yield allDocs;
    }
  }

  // 5. جلب منشورات مستخدم معين (للملف الشخصي العام)
  Stream<QuerySnapshot> getPostsByUser(String userId, {String? type, bool showPending = false}) {
    Query query = _db.collection('posts').where('authorId', isEqualTo: userId);
    if (type != null) query = query.where('type', isEqualTo: type);
    // ✅ لا نعرض المنشورات المعلقة في الملف الشخصي العام
    if (!showPending) query = query.where('status', isEqualTo: 'approved');
    return query.snapshots();
  }

  // 6. البحث عن الأعمال والمستخدمين
  Future<List<QueryDocumentSnapshot>> searchPosts(String query) async {
    String q = query.toLowerCase();
    final snap = await _db.collection('posts')
        .where('titleLower', isGreaterThanOrEqualTo: q)
        .where('titleLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(30)
        .get();
        
    return snap.docs.where((doc) => doc.data()['status'] == 'approved').toList();
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

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _db.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId]),
      'followingCount': FieldValue.increment(-1)
    });
    await _db.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
      'followersCount': FieldValue.increment(-1)
    });
  }

  Future<void> savePostToCollection(String userId, String postId, String collectionName) async {
    await _db.collection('users').doc(userId).update({
      collectionName: FieldValue.arrayUnion([postId])
    });
  }

  // 7. المتابعة والحفظ (تم الحل: تجاوز قيد الـ 10 باطراد)
  Stream<List<QueryDocumentSnapshot>> getSavedPosts(List<dynamic> postIds) async* {
    if (postIds.isEmpty) {
      yield [];
      return;
    }
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < postIds.length; i += 10) {
      chunks.add(postIds.sublist(i, i + 10 > postIds.length ? postIds.length : i + 10));
    }
    
    List<Stream<QuerySnapshot>> streams = chunks.map((chunk) {
      return _db.collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots();
    }).toList();

    await for (var snapshots in StreamZip(streams)) {
      List<QueryDocumentSnapshot> allDocs = [];
      for (var snap in snapshots) {
        allDocs.addAll(snap.docs);
      }
      yield allDocs;
    }
  }

  // جلب قائمة مستخدمين بواسطة معرفاتهم (تجاوز قيد الـ 10)
  Stream<List<QueryDocumentSnapshot>> getUsersByIds(List<dynamic> userIds) async* {
    if (userIds.isEmpty) {
      yield [];
      return;
    }
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < userIds.length; i += 10) {
      chunks.add(userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10));
    }
    
    List<Stream<QuerySnapshot>> streams = chunks.map((chunk) {
      return _db.collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots();
    }).toList();

    await for (var snapshots in StreamZip(streams)) {
      List<QueryDocumentSnapshot> allDocs = [];
      for (var snap in snapshots) {
        allDocs.addAll(snap.docs);
      }
      yield allDocs;
    }
  }

  // 8. الملف الشخصي
  Future<void> updateAvatar(String userId, {String? base64String, String? url}) async {
    Map<String, dynamic> data = {};
    if (base64String != null) data['avatarBase64'] = base64String;
    if (url != null) data['avatarUrl'] = url;
    await _db.collection('users').doc(userId).update(data);
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

  // زيادة عدد المشاهدات بصمت وذكاء (Unique Views Logic)
  Future<void> incrementPostViews(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> viewedPosts = prefs.getStringList('viewed_posts_v3') ?? [];
      
      // ✅ التحقق: هل شاهد هذا المستخدم هذا المنشور مسبقاً؟
      if (!viewedPosts.contains(postId)) {
        await _db.collection('posts').doc(postId).update({'viewsCount': FieldValue.increment(1)});
        
        // حفظ "بصمة" المنشور لمنع الزيادة المتكررة من نفس الجهاز
        viewedPosts.add(postId);
        await prefs.setStringList('viewed_posts_v3', viewedPosts);
      }
    } catch (_) {}
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
        
        // ✅ إرسال إشعار فقط إذا كان صاحب المنشور بشراً (ليس سيستم أو مجهول)
        if (userId != authorId && authorId.isNotEmpty && authorId != 'artiatech_system') {
          await sendInAppNotification(
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

  // ✅ إخطار المتابعين عند نشر عمل جديد أو تحديثه (Social Pulse)
  Future<void> notifyFollowers({
    required String authorId,
    required String authorName,
    required String postId,
    required String postTitle,
    required String type, // 'new_post' أو 'app_update'
  }) async {
    final followersSnap = await _db.collection('users').doc(authorId).get();
    final List followers = followersSnap.data()?['followers'] ?? [];
    
    if (followers.isEmpty) return;

    final batch = _db.batch();
    for (var followerId in followers.take(100)) { // تحديد بـ 100 لضمان عدم فشل الـ Batch
      final notifRef = _db.collection('users').doc(followerId).collection('notifications').doc();
      batch.set(notifRef, {
        'fromUserId': authorId,
        'fromUserName': authorName,
        'type': type,
        'postId': postId,
        'postTitle': postTitle,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ✅ نداء عام: إنشاء إعلان يراه الجميع في الصفحة الرئيسية
  Future<void> createSystemAnnouncement(String title, String content) async {
    await _db.collection('posts').add({
      'title': title,
      'titleLower': title.toLowerCase(),
      'content': content,
      'type': 'announcement',
      'status': 'approved',
      'authorName': 'Artiatech Studio',
      'authorId': 'system',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _db.collection('users').doc(userId).collection('notifications')
        .orderBy('createdAt', descending: true).limit(30).snapshots();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final unread = await _db.collection('users').doc(userId).collection('notifications')
        .where('isRead', isEqualTo: false).get();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _db.collection('users').doc(userId).collection('notifications').doc(notificationId).update({'isRead': true});
  }
}
