import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/onboarding_screen.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';

// التحكم بثيم التطبيق في كامل الأرجاء
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فايربيس (Manual Config to avoid missing files)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA6u6pxUGlx9n8ksKFoJ_ycC_BmBjjKHaA",
        authDomain: "carengocount.firebaseapp.com",
        databaseURL: "https://carengocount-default-rtdb.firebaseio.com",
        projectId: "carengocount",
        storageBucket: "carengocount.firebasestorage.app",
        messagingSenderId: "770281294675",
        appId: "1:770281294675:web:b48df5992f23a2da5cefa6",
        measurementId: "G-LT1MR4JP5E",
      ),
    );
  } else {
    await Firebase.initializeApp();
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
