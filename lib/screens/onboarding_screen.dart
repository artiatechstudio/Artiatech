import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main_screen.dart';

// ─────────────────────────────────────────────
// 1. شاشة البداية (Splash)
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), _checkConsent);
  }

  Future<void> _checkConsent() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('terms_accepted') ?? false;
    if (!accepted) {
      _showConsentDialog();
    } else {
      _goNext();
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'ميثاق استخدام أرتياتك',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'باستخدامك لهذا التطبيق فأنت توافق على سياسة الخصوصية وشروط الاستخدام.\n\n'
          'نحن نحمي حقوق المبدعين الرقمية، وأي انتهاك يعرّضك للمساءلة القانونية.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('رفض وإغلاق'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('terms_accepted', true);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _goNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('موافق، استمرار'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => const OnboardingScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Image.asset('splash.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. شاشة الـ Onboarding (PageView — 3 شاشات كاملة)
// ─────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  void _next() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _current = i),
            children: [
              _Page1Welcome(onNext: _next),
              _Page2About(onNext: _next),
              _Page3Legal(onNext: _next),
            ],
          ),
          // مؤشر الصفحات في الأعلى
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 6),
                    width: _current == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// الشاشة الأولى: البداية (Welcome)
// ─────────────────────────────────────────────
class _Page1Welcome extends StatelessWidget {
  final VoidCallback onNext;
  const _Page1Welcome({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D20), Color(0xFF1A2050)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة كبيرة متوهجة
              const SizedBox(height: 30),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 241, 253, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        242,
                        246,
                        249,
                      ).withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset(
                  'icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'انطلق مع',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Artiatech Studio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'منصة عربية تجمع الفن، التقنية، الألعاب، والادبيات. '
                'استعرض أعمال المبدعين، هدفنا الارتقاء بالمحتوى الرقمي العربي.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 60),

              // مميزات سريعة
              _FeatureRow(emoji: '🎨', text: 'فنون بصرية وتصاميم حصرية'),
              const SizedBox(height: 14),
              _FeatureRow(emoji: '🎮', text: 'ألعاب HTML وتطبيقات أندرويد'),
              const SizedBox(height: 14),
              _FeatureRow(emoji: '📖', text: 'روايات وقصص من مبدعين عرب'),
              const SizedBox(height: 14),
              _FeatureRow(emoji: '💻', text: 'مشاريع تقنية وبرمجية مفتوحة'),

              const SizedBox(height: 60),

              // زر ابدأ
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ابدأ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji, text;
  const _FeatureRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 14),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// الشاشة الثالثة: الوثائق القانونية
// ─────────────────────────────────────────────
class _Page3Legal extends StatelessWidget {
  final VoidCallback onNext;
  const _Page3Legal({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0030), Color(0xFF2E0050)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // رأس الصفحة
            const Text('📜', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              'الوثائق القانونية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اقرأ شروطنا قبل الاستمرار',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // البنود بقابلية التمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _LegalCard(
                      color: const Color(0xFF2979FF),
                      emoji: '🔒',
                      title: 'سياسة الخصوصية',
                      content:
                          'نجمع فقط البيانات الضرورية لتشغيل الخدمة (البريد الإلكتروني، اسم المستخدم). '
                          'لا نبيع بياناتك ولا نشاركها مع أطراف تجارية. '
                          'بياناتك مشفّرة ومحمية بمعايير Google Cloud الأمنية .',
                    ),
                    const SizedBox(height: 16),
                    _LegalCard(
                      color: const Color(0xFF6C63FF),
                      emoji: '⚖️',
                      title: 'شروط الاستخدام',
                      content:
                          'يُحظر نشر محتوى مسروق أو مسيء أو ينتهك القيم العامة. '
                          'تحتفظ إدارة أرتياتك بحق حذف أي حساب ينتهك الشروط. '
                          'يُمنع استخدام التطبيق لأغراض ضارة أو غير قانونية.',
                    ),
                    const SizedBox(height: 16),
                    _LegalCard(
                      color: Colors.amber,
                      emoji: '✍️',
                      title: 'حقوق النشر',
                      content:
                          'حقوق النشر محفوظة للمبدع صاحب العمل حصراً. '
                          'المنصة وسيط عرض فقط ولا تملك أي حق في استغلال العمل. '
                          'يمكن لصاحب العمل حذفه في أي وقت.',
                    ),
                    const SizedBox(height: 16),
                    _LegalCard(
                      color: Colors.teal,
                      emoji: '👶',
                      title: 'حماية الأطفال',
                      content:
                          'لا ينبغي للأشخاص دون الثالثة عشر (13) الاستخدام بدون إشراف ولي الأمر. '
                          'نلتزم بمبادئ لحماية خصوصية الأطفال (COPPA).',
                    ),
                    const SizedBox(height: 40),

                    // زر ابدأ
                    GestureDetector(
                      onTap: onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ابدأ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  final Color color;
  final String emoji, title, content;
  const _LegalCard({
    required this.color,
    required this.emoji,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// الشاشة الثانية: من نحن
// ─────────────────────────────────────────────
class _Page2About extends StatelessWidget {
  final VoidCallback onNext;
  const _Page2About({required this.onNext});

  void _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001A20), Color(0xFF003040)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // رأس الصفحة
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'من نحن',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'أرتياتك ستوديو — استوديو عربي مبدع يجمع الفن والتقنية في منصة واحدة، '
                'ويهدف لبناء مجتمع إبداعي حقيقي للشباب العربي.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // روابط التواصل قابلة للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'تابعنا على منصات التواصل',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _SocialTile(
                      faIcon: FontAwesomeIcons.instagram,
                      platform: 'انستاغرام',
                      handle: '@artiatechstudio',
                      color: const Color(0xFFE1306C),
                      url: 'https://www.instagram.com/artiatechstudio',
                      onTap: _open,
                    ),
                    _SocialTile(
                      faIcon: FontAwesomeIcons.xTwitter,
                      platform: 'X (تويتر)',
                      handle: '@artiatechstudio',
                      color: const Color(0xFF1A8CD8),
                      url: 'https://x.com/artiatechstudio',
                      onTap: _open,
                    ),
                    _SocialTile(
                      faIcon: FontAwesomeIcons.youtube,
                      platform: 'يوتيوب',
                      handle: '@artiatechstudio',
                      color: const Color(0xFFFF0000),
                      url: 'https://www.youtube.com/@artiatechstudio',
                      onTap: _open,
                    ),
                    _SocialTile(
                      faIcon: FontAwesomeIcons.facebookF,
                      platform: 'فيسبوك',
                      handle: 'artiatechstudio',
                      color: const Color(0xFF1877F2),
                      url:
                          'https://www.facebook.com/profile.php?id=61584838507463',
                      onTap: _open,
                    ),
                    _SocialTile(
                      faIcon: FontAwesomeIcons.whatsapp,
                      platform: 'قناة واتساب',
                      handle: 'Artiatech Studio',
                      color: const Color(0xFF25D366),
                      url:
                          'https://whatsapp.com/channel/0029VbBNHwi9mrGjTo79LV3u',
                      onTap: _open,
                    ),

                    const SizedBox(height: 40),

                    // زر ابدأ
                    GestureDetector(
                      onTap: onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ابدأ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final IconData faIcon;
  final String platform, handle, url;
  final Color color;
  final Function(String) onTap;

  const _SocialTile({
    required this.faIcon,
    required this.platform,
    required this.handle,
    required this.url,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // الأيقونة الرسمية للمنصة
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: FaIcon(faIcon, color: color, size: 22)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  handle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.7),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
