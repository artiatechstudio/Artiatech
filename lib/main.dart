import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  // تهيئة فايربيس (منع الخطأ المكرر ودعم كامل المنصات)
  if (Firebase.apps.isEmpty) {
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
      try {
        await Firebase.initializeApp(); // يعتمد على google-services.json في الأندرويد
      } catch (e) {
        // في الويندوز أو إذا فشل التحميل التلقائي
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
      }
    }
  }

  // ✅ تحسين الأداء: تفعيل التخزين المحلي لفايرستور لتقليل استهلاك البيانات
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {} 


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
              fontFamily: 'Cairo', // ✅ أفضل للخطوط العربية
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.blueAccent,
              fontFamily: 'Cairo',
            ),
            locale: const Locale('ar'), // ✅ تفعيل الوضع العربي (RTL) إجبارياً
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
