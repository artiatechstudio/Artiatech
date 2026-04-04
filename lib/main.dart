import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/onboarding_screen.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';

// التحكم بخصائص التطبيق في كامل الأرجاء
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> soundNotifier = ValueNotifier(true); // مفعل افتراضياً

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فايربيس (Manual Config to avoid missing files)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAQJ0FnP5sHLgoyNu19JnEJf5-CdOWWVTQ",
        authDomain: "artiatech-studio.firebaseapp.com",
        projectId: "artiatech-studio",
        storageBucket: "artiatech-studio.firebasestorage.app",
        messagingSenderId: "318277778901",
        appId: "1:318277778901:web:ff9c76bcf9cc268549915c",
      ),
    );
  } else {
    await Firebase.initializeApp();
    
    // ✅ تحسين الأداء: تفعيل التخزين المحلي لفايرستور لتقليل استهلاك البيانات
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // تخزين ما يمكن على الجهاز
    );
  }

  await NotificationService.init(); // القفزة الكبرى: تهيئة الإشعارات
  runApp(const ArtiatechApp());
}

class ArtiatechApp extends StatelessWidget {
  const ArtiatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) {
          return MaterialApp(
            title: 'Artiatech Studio',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.blueAccent,
              fontFamily: 'Outfit',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.blueAccent,
              fontFamily: 'Outfit',
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
