import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _auth.authStateChanges().listen((user) async {
       if (user != null) {
         await refreshUserContext();
       } else {
         _reset();
       }
    });
  }

  Future<void> refreshUserContext() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _profileData = doc.data();
        _isAdmin = _profileData?['role'] == 'admin' || 
                   (_profileData?['username'] ?? '').toString().toLowerCase() == 'artiatech';
        _isTrusted = _profileData?['isTrusted'] ?? false;
        _followingIds = _profileData?['following'] ?? [];
        
        // حفظ محلي للأداء العالي (Spark optimization)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin', _isAdmin);
        await prefs.setBool('is_trusted', _isTrusted);
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
    await _db.collection('users').doc(user.uid).update({'following': FieldValue.arrayUnion([targetUserId])});
    await _db.collection('users').doc(targetUserId).update({'followers': FieldValue.arrayUnion([user.uid])});
  }
}
