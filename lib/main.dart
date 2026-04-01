import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ArtiatechApp());
}

class ArtiatechApp extends StatelessWidget {
  const ArtiatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artiatech Studio',
      debugShowCheckedModeBanner: false,
      // تأكيد دعم اللغة العربية من اليمين لليسار
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      // التصميم الداكن الفخم الأساسي
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF2A5F),
          surface: Color(0xFF1A1C29),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0E15),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1C29),
          selectedItemColor: Color(0xFF00E5FF),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: GoogleFonts.cairoTextTheme(const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(),
        )).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ArtsPage(),
    const TechPage(),
    const ArticlesPage(),
    const ProfilePage(),
  ];

  void _showPublishBottomSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'عمل فني';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'طلب نشر جديد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'بإرسالك لهذا الطلب، أنت توافق على شروط استوديو أرتياتك.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: <String>['عمل فني', 'عمل تقني', 'مقالة / رواية'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                selectedType = val!;
              },
              decoration: const InputDecoration(labelText: 'نوع العمل'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان العمل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'وصف العمل / رابط التحميل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final String title = titleController.text;
                final String desc = descriptionController.text;
                final String phone = '0929196425';
                final String message = 'أهلاً أرتياتك، أرغب في نشر عمل جديد:\n\n'
                    '*النوع:* $selectedType\n'
                    '*العنوان:* $title\n'
                    '*الوصف:* $desc';

                final Uri whatsappUrl = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
                
                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(whatsappUrl);
                  if (mounted) Navigator.pop(context);
                } else {
                  // Fallback for web or if whatsapp is not installed
                  final Uri webUrl = Uri.parse('https://wa.me/$phone/?text=${Uri.encodeComponent(message)}');
                  await launchUrl(webUrl);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('إرسال الطلب عبر واتساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.palette_rounded), label: 'الفنون'),
          BottomNavigationBarItem(icon: Icon(Icons.memory_rounded), label: 'التكنولوجيا'),
          BottomNavigationBarItem(icon: Icon(Icons.article_rounded), label: 'المقالات'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'أنت'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showPublishBottomSheet,
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'انشر',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artiatech Studio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن ألعاب، روايات، أو فنانين...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // جلب البيانات من بلوجر مستقبلاً
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // شريط متحرك للإعلانات (Carousel Simulator)
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary.withOpacity(0.2), Theme.of(context).colorScheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_rounded, size: 50, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 10),
                        const Text(
                          'إعلان هام: مسابقة أرتياتك السنوية!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('اضغط للتفاصيل', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('أحدث الأعمال', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                TextButton(onPressed: () {}, child: const Text('عرض الكل')),
              ],
            ),
            const SizedBox(height: 12),
            // قائمة افتراضية للعرض (YouTube Style Layout)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: NetworkImage('https://via.placeholder.com/400x225'), // ستستبدل بصورة من بلوجر
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage('https://via.placeholder.com/50'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'عنوان العمل الفني أو التقني المذهل رقم ${index + 1}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'اسم الناشر • 1.2 ألف مشاهدة • منذ يومين',
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, size: 20)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class ArtsPage extends StatelessWidget {
  const ArtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعرض الفني'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (v) {},
              decoration: InputDecoration(
                hintText: 'ابحث في الفنون...',
                prefixIcon: const Icon(Icons.palette_outlined),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network('https://via.placeholder.com/200', fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('عمل فني ${index + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('بواسطة الفنان', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TechPage extends StatelessWidget {
  const TechPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإبداع التقني'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في التقنية والألعاب...',
                prefixIcon: const Icon(Icons.code_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(index % 2 == 0 ? Icons.sports_esports_outlined : Icons.html_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
              title: Text(index % 2 == 0 ? 'لعبة مذهلة' : 'برنامج HTML مفيد'),
              subtitle: const Text('مشروع SB3 مدمج وتفاعلي'),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('العب الآن'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الروايات والمقالات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن روايات أو قصص...',
                prefixIcon: const Icon(Icons.chrome_reader_mode_outlined),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network('https://via.placeholder.com/80x120', width: 80, height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رواية: رحلة إلى المجهول ${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('بواسطة: كاتب أرتياتك', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.white38),
                          const SizedBox(width: 4),
                          const Text('1.5k', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.star_outline_rounded, size: 16, color: Colors.white38),
                          const SizedBox(width: 4),
                          const Text('120', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('أنت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final username = userData?['username'] ?? 'مستخدم أرتياتك';
          final role = userData?['role'] ?? 'reader';
          final memberId = userData?['memberId'] ?? '0000';
          final isAdmin = role == 'admin';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'عضو رقم #$memberId',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAdmin ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAdmin ? 'مسؤول' : (role == 'publisher' ? 'ناشر' : 'قارئ'),
                            style: TextStyle(
                              color: isAdmin ? Colors.amber : Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('المتابعون', userData?['followersCount']?.toString() ?? '0'),
                  _buildStatColumn('تتابع', userData?['followingCount']?.toString() ?? '0'),
                  _buildStatColumn('أعمالك', '0'),
                ],
              ),
              const SizedBox(height: 40),
              const Text('مكتبتي الخاصة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildProfileOption(context, Icons.file_download_outlined, 'الأعمال المحملة (بلا إنترنت)', () {}),
              _buildProfileOption(context, Icons.favorite_border_rounded, 'قائمة المفضلة', () {}),
              _buildProfileOption(context, Icons.history_rounded, 'تاريخ المشاهدة', () {}),
              if (isAdmin) ...[
                const SizedBox(height: 32),
                const Text('الإدارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 16),
                _buildProfileOption(context, Icons.admin_panel_settings_outlined, 'لوحة التحكم المركزية', () {}, isSpecial: true),
                _buildProfileOption(context, Icons.mark_as_unread_outlined, 'طلبات النشر المعلقة', () {}, isSpecial: true),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isSpecial = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSpecial ? Colors.amber : Colors.white70),
      title: Text(title, style: TextStyle(color: isSpecial ? Colors.amber : Colors.white)),
      trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white24),
      onTap: onTap,
    );
  }
}
