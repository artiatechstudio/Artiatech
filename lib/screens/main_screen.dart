import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'arts_page.dart';
import 'tech_page.dart';
import 'articles_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'submit_work_screen.dart';
import 'notifications_page.dart';
import '../services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = [
    const HomePage(),
    const ArtsPage(),
    const TechPage(),
    const ArticlesPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // بدء الاستماع للإشعارات لحظة الدخول (Spark Synergy)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationService.listenToNotifications(user.uid);
    }
  }

  @override
  void dispose() {
    _notificationService.cancelNotifications(); // ✅ إلغاء الاستماع فوراً عند التبديل لمنع الانهيار
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 4 ? null : AppBar(
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                SizedBox(width: 15),
                Icon(Icons.search, size: 18, color: Colors.grey),
                SizedBox(width: 10),
                Text('البحث في أرتياتك...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())), icon: const Icon(Icons.notifications_none_outlined, color: Colors.blueAccent)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitWorkScreen())), icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent)),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 25),
        height: 65,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26).withOpacity(0.95) : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
            _buildNavItem(1, Icons.play_circle_fill_rounded, 'يوتيوب'),
            _buildNavItem(2, Icons.memory_rounded, 'تقنية'),
            _buildNavItem(3, Icons.article_rounded, 'مقالات'),
            _buildNavItem(4, Icons.person_rounded, 'أنت'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 24),
          ),
          if (isSelected) 
            Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
