import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  bool _isAdmin = false;
  bool _isTrusted = false;
  List<dynamic> _followingIds = [];
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  bool get isAdmin => _isAdmin;
  bool get isTrusted => _isTrusted || _isAdmin; // المطور دائماً موثوق
  List<dynamic> get followingIds => _followingIds;
  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    // محاولة استعادة البيانات المخزنة مسبقاً للسرعة القصوى لجعل التطبيق يبدو حيوياً
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('user_profile_cache');
    if (cachedData != null) {
      _profileData = json.decode(cachedData);
      _isAdmin = prefs.getBool('is_admin') ?? false;
      _isTrusted = prefs.getBool('is_trusted') ?? false;
      _followingIds = _profileData?['following'] ?? [];
      _isLoading = false;
      notifyListeners();
    }

    _auth.authStateChanges().listen((user) async {
       if (user != null) {
         // ✅ التحقق من أن الكاش ينتمي للمستخدم الحالي، وإلا نقوم بمسحه فوراً
         final prefs = await SharedPreferences.getInstance();
         final cachedUid = prefs.getString('cached_uid');
         if (cachedUid != user.uid) {
           await _resetForSwitch(); // مسح البيانات القديمة فوراً
         }
         await refreshUserContext();
       } else {
         _reset();
       }
    });
  }

  Future<void> _resetForSwitch() async {
    _profileData = null;
    _isAdmin = false;
    _isTrusted = false;
    _followingIds = [];
    notifyListeners();
  }

  Future<void> refreshUserContext() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _profileData = doc.data();
        _isAdmin = _profileData?['role'] == 'admin';
        _isTrusted = _profileData?['isTrusted'] ?? false;
        _followingIds = _profileData?['following'] ?? [];
        
        // حفظ محلي ذكي مع ربطه بمعرف المستخدم (UID) لضمان الخصوصية
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_uid', user.uid); // ✅ حفظ الـ UID لغرض التحقق القادم
        await prefs.setBool('is_admin', _isAdmin);
        await prefs.setBool('is_trusted', _isTrusted);
        await prefs.setString('user_profile_cache', json.encode(_profileData));
      }
    } catch (e) {
      debugPrint('Error syncing user context: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _reset() {
    _isAdmin = false;
    _isTrusted = false; // ✅ مهم: إعادة تعيين عند تسجيل الخروج
    _followingIds = [];
    _profileData = null;
    _isLoading = false;
    notifyListeners();
  }

  // منطق المتابعة السريع وحفظ الموارد
  Future<void> followUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_followingIds.contains(targetUserId)) return;

    _followingIds.add(targetUserId);
    notifyListeners(); // تحديث فوري للواجهة لخدمة المستخدم

    // التحديث في السحاب يتم في الخلفية
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'following': FieldValue.arrayUnion([targetUserId]),
      'followingCount': FieldValue.increment(1)
    });
    await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([user.uid]),
      'followersCount': FieldValue.increment(1)
    });
  }
}
