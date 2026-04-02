import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _checkTermsConsent();
  }

  void _checkTermsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool('terms_accepted') ?? false;

    if (!accepted) {
      if (!mounted) return;
      _showConsentDialog();
    } else {
      _navigateToOnboarding();
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن تخطيه
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ميثاق استخدام أرتياتك', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'باستخدامك لهذا التطبيق، أنت تشهد بموافقتك على سياسة الخصوصية وشروط الاستخدام وحقوق النشر. نحن نحمي حقوق المبدعين الرقمية، وأي محاولة للقرصنة أو الإساءة تعرضك للمساءلة القانونية.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => SystemNavigator.pop(), // إغلاق التطبيق عند الرفض
                  child: const Text('رفض وإغلاق', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('terms_accepted', true);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _navigateToOnboarding();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: const Text('موافق، استمرار'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _navigateToOnboarding() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        )
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset('splash.png', width: 200, errorBuilder: (_,__,___) => const Icon(Icons.rocket_launch, size: 100, color: Colors.blueAccent)),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'مرحباً بك في عالم الإبداع',
      'desc': 'أرتياتك ستوديو هو ملتقى المبدعين حيث يلتقي الفن بالتقنية في منصة واحدة.',
      'icon': '🎨',
    },
    {
      'title': 'استعرض وجرب الأفضل',
      'desc': 'اكتشف أحدث الألعاب والمقالات والمشاريع التقنية المستوردة مباشرة من مدوناتنا.',
      'icon': '🚀',
    },
    {
      'title': 'كن جزءاً من المجتمع',
      'desc': 'تابع المبدعين، احفظ أعمالك المفضلة، وانشر بصمتك الخاصة في أرتياتك.',
      'icon': '🌟',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _onboardingData.length,
            itemBuilder: (context, idx) => _buildPage(idx),
          ),
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(children: List.generate(_onboardingData.length, (i) => _buildIndicator(i))),
                 _currentPage == _onboardingData.length - 1 
                  ? ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen())),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text('ابدأ التجربة الآن'),
                    )
                  : IconButton(onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease), icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(int idx) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Color(0xFFF0F2F5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_onboardingData[idx]['icon']!, style: const TextStyle(fontSize: 100)),
          const SizedBox(height: 50),
          Text(_onboardingData[idx]['title']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 20),
          Text(_onboardingData[idx]['desc']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildIndicator(int i) {
    return Container(
      width: _currentPage == i ? 25 : 8,
      height: 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(color: _currentPage == i ? Colors.blueAccent : Colors.grey[300], borderRadius: BorderRadius.circular(5)),
    );
  }
}
