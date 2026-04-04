import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D0D12), Color(0xFF1A1A40)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 249, 254, 255),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
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
                    const SizedBox(height: 18),
                    const Text(
                      'أرتياتك ستوديو',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Artiatech Studio',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              title: const Text('من نحن'),
            ),
          ),

          // ── Body ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── فلسفة المنصة ──
                  _SectionTitle('فلسفتنا'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    isDark: isDark,
                    child: const Text(
                      'أرتياتك ستوديو هو استوديو عربي متخصص يجمع بين الفن والتقنية في منصة واحدة. '
                      'هدفنا بناء مجتمع إبداعي عربي حقيقي، حيث يجد كل مبدع—سواء كان رساماً، '
                      'مبرمجاً، كاتب روايات، أو مصمم ألعاب—المكان المناسب لعرض موهبته والتواصل مع جمهوره.',
                      style: TextStyle(fontSize: 14, height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── القيم ──
                  _SectionTitle('قيمنا الأساسية'),
                  const SizedBox(height: 12),
                  _ValueTile(
                    isDark: isDark,
                    emoji: '🎨',
                    title: 'دعم المبدعين',
                    desc:
                        'منصة مفتوحة للفنانين والمصممين والكتّاب لنشر أعمالهم بحرية كاملة.',
                  ),
                  _ValueTile(
                    isDark: isDark,
                    emoji: '💻',
                    title: 'التقنية للجميع',
                    desc:
                        'مشاريع مفتوحة المصدر وحلول تقنية تمكّن الشباب العربي في عصر الذكاء الاصطناعي.',
                  ),
                  _ValueTile(
                    isDark: isDark,
                    emoji: '📖',
                    title: 'القصة والرواية',
                    desc:
                        'بيئة آمنة وداعمة للكتّاب لنشر إبداعاتهم والوصول إلى آلاف القراء.',
                  ),
                  _ValueTile(
                    isDark: isDark,
                    emoji: '🎮',
                    title: 'الألعاب والترفيه',
                    desc:
                        'ألعاب HTML وبرامج أندرويد تُنشر مباشرة من مطوّريها دون وسيط.',
                  ),

                  const SizedBox(height: 32),

                  // ── تواصل معنا ──
                  _SectionTitle('تواصل معنا'),
                  const SizedBox(height: 14),

                  _SocialButton(
                    icon: Icons.camera_alt,
                    label: 'انستاغرام',
                    handle: '@artiatechstudio',
                    color: const Color(0xFFE1306C),
                    url: 'https://www.instagram.com/artiatechstudio',
                    onTap: (url) => _openUrl(context, url),
                  ),
                  _SocialButton(
                    icon: Icons.close, // X (Twitter)
                    label: 'X (تويتر)',
                    handle: '@artiatechstudio',
                    color: const Color(0xFF1DA1F2),
                    url: 'https://x.com/artiatechstudio',
                    onTap: (url) => _openUrl(context, url),
                  ),
                  _SocialButton(
                    icon: Icons.play_circle_fill,
                    label: 'يوتيوب',
                    handle: '@artiatechstudio',
                    color: const Color(0xFFFF0000),
                    url: 'https://www.youtube.com/@artiatechstudio',
                    onTap: (url) => _openUrl(context, url),
                  ),
                  _SocialButton(
                    icon: Icons.facebook,
                    label: 'فيسبوك',
                    handle: 'artiatechstudio',
                    color: const Color(0xFF1877F2),
                    url:
                        'https://www.facebook.com/profile.php?id=61584838507463',
                    onTap: (url) => _openUrl(context, url),
                  ),
                  _SocialButton(
                    icon: Icons.message,
                    label: 'قناة واتساب',
                    handle: 'Artiatech Studio',
                    color: const Color(0xFF25D366),
                    url:
                        'https://whatsapp.com/channel/0029VbBNHwi9mrGjTo79LV3u',
                    onTap: (url) => _openUrl(context, url),
                  ),

                  const SizedBox(height: 40),

                  // ── Footer ──
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'صُنع بكل فخر في أرتياتك ستوديو 🚀',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'جميع الحقوق محفوظة © ${DateTime.now().year} Artiatech Studio',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF2979FF),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _InfoCard({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A30) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12),
      ],
    ),
    child: child,
  );
}

class _ValueTile extends StatelessWidget {
  final String emoji, title, desc;
  final bool isDark;
  const _ValueTile({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A30) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
      ],
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label, handle, url;
  final Color color;
  final Function(String) onTap;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.handle,
    required this.url,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(url),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                handle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: color.withOpacity(0.6),
            size: 14,
          ),
        ],
      ),
    ),
  );
}
