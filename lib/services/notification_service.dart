import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestore = FirestoreService();

  // 1. تهيئة النظام (Initialization)
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
    
    // إنشاء قناة الإشعارات الصوتية (لأندرويد 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'artiatech_social_v3', 
      'إشعارات أرتياتك الاجتماعية',
      description: 'تنبيهات الإعجابات والمتابعات والمنشورات الجديدة بصوت',
      importance: Importance.max,
      playSound: true,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 2. إظهر إشعار محلي مع صوت وأولوية قصوى (Show Local Notification with Sound)
  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'artiatech_social_v3',
      'إشعارات أرتياتك الاجتماعية',
      channelDescription: 'تنبيهات الإعجابات والمتابعات والمنشورات الجديدة بصوت',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      DateTime.now().millisecond, 
      title, 
      body, 
      platformChannelSpecifics
    );
  }

  // 3. الاستماع للإشعارات الجديدة (Real-time Listening)
  void listenToNotifications(String userId) {
    _firestore.getNotifications(userId).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final timestamp = data['createdAt'] as Timestamp?;
          
          if (timestamp != null && DateTime.now().difference(timestamp.toDate()).inSeconds < 10) {
             _triggerNotification(data);
          }
        }
      }
    });
  }

  void _triggerNotification(Map<String, dynamic> data) {
    String type = data['type'] ?? '';
    String fromUserName = data['fromUserName'] ?? 'مبدع أرتياتك';
    String postTitle = data['postTitle'] ?? '';

    String title = 'تفاعل جديد في أرتياتك! 🌟';
    String body = '';

    if (type == 'like') {
      body = 'أُعجب "$fromUserName" بعملك "$postTitle" ❤️';
    } else if (type == 'follow') {
      body = 'قام "$fromUserName" بمتابعتك الآن! 🚀';
    } else if (type == 'new_post') {
      body = 'إبداع جديد من "$fromUserName": "$postTitle" ✨';
    }

    if (body.isNotEmpty) {
      showLocalNotification(title, body);
    }
  }
}
