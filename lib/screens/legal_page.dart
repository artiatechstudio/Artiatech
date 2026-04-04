import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الوثائق القانونية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ─── سياسة الخصوصية ───────────────
          _LegalSection(
            isDark: isDark,
            emoji: '🔒',
            title: 'سياسة الخصوصية',
            color: Colors.blueAccent,
            items: [
              _LegalItem(
                'جمع البيانات',
                'نجمع المعلومات الضرورية فقط لتشغيل الخدمة، بما يشمل: عنوان البريد الإلكتروني '
                    'لتسجيل الدخول، اسم المستخدم، والمحتوى الذي تنشره طوعاً. '
                    'لا نجمع أي بيانات حساسة دون موافقتك الصريحة.',
              ),
              _LegalItem(
                'استخدام البيانات',
                'تُستخدم بياناتك حصراً لتشغيل الخدمة وتحسين تجربتك. '
                    'نحن لا نبيع بياناتك ولا نشاركها مع أي طرف تجاري ثالث. '
                    'نستخدم Firebase من Google لتخزين البيانات بمعايير أمان.',
              ),
              _LegalItem(
                'ملفات الكوكيز والتتبع',
                'قد يستخدم التطبيق تقنيات تخزين محلي (SharedPreferences) لحفظ تفضيلاتك '
                    'كاللغة والثيم. لا يتم إرسال هذه البيانات لخوادم خارجية.',
              ),
              _LegalItem(
                'أمان البيانات',
                'نلتزم بمعايير Google Cloud Security لحماية بياناتك. '
                    'يتم تشفير كل الاتصالات بين التطبيق وقاعدة البيانات عبر HTTPS/TLS. '
                    'لا يمكن لأي موظف الوصول لكلمة مرورك إذ يتم تشفيرها من قِبَل Firebase Auth.',
              ),
              _LegalItem(
                'حقوق المستخدم',
                'يحق لك في أي وقت: الاطلاع على بياناتك، تعديلها، أو طلب حذفها كلياً '
                    'عبر التواصل معنا على واتساب أو البريد الإلكتروني.',
              ),
              _LegalItem(
                'المستخدمون القاصرون',
                'لا ينبغي للأشخاص دون الثالثة عشرة (13) استخدام هذا التطبيق دون إشراف '
                    'ولي الأمر. نحن نلتزم بمبادئ سياسة جوجل لحماية خصوصية الأطفال (COPPA).',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ─── شروط الاستخدام ───────────────
          _LegalSection(
            isDark: isDark,
            emoji: '⚖️',
            title: 'شروط الاستخدام',
            color: const Color(0xFF6C63FF),
            items: [
              _LegalItem(
                'القبول بالشروط',
                'باستخدامك لتطبيق أرتياتك ستوديو، فأنت توافق على هذه الشروط والأحكام. '
                    'إن كنت لا توافق على أي بند، يجب عليك التوقف عن استخدام التطبيق فوراً.',
              ),
              _LegalItem(
                'السلوك المسموح به',
                'يُسمح بنشر المحتوى الأصيل (أعمال فنية، تقنية، روايات، ألعاب) بشرط أن تمتلك '
                    'حقوق نشره. يُسمح بالتعليق والتفاعل الإيجابي بين أعضاء المجتمع.',
              ),
              _LegalItem(
                'المحتوى المحظور',
                'يُحظر منعاً باتاً نشر أي من التالي:\n'
                    '• المحتوى المُقرصَن أو المنسوخ دون إذن\n'
                    '• المحتوى المسيء، العنصري، أو الجنسي\n'
                    '• معلومات كاذبة أو مضللة\n'
                    '• البرمجيات الخبيثة أو الملفات الضارة\n'
                    '• انتهاك خصوصية الآخرين',
              ),
              _LegalItem(
                'حذف الحسابات',
                'تحتفظ إدارة أرتياتك بالحق الكامل في تعليق أو حذف أي حساب ينتهك هذه الشروط، '
                    'دون التزام بإشعار مسبق، وذلك حفاظاً على سلامة المجتمع الرقمي.',
              ),
              _LegalItem(
                'تعديل الشروط',
                'يحق لنا تعديل هذه الشروط في أي وقت. في حال حدوث تغييرات جوهرية، '
                    'سنقوم بإشعار المستخدمين عبر إشعار داخل التطبيق.',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ─── حقوق الملكية الفكرية ───────────
          _LegalSection(
            isDark: isDark,
            emoji: '📜',
            title: 'حقوق الملكية الفكرية',
            color: Colors.amber,
            items: [
              _LegalItem(
                'ملكية المحتوى',
                ' تبقى جميع حقوق النشر '
                    'والملكية الفكرية للأعمال المنشورة محفوظة للناشر نفسه حصراً. '
                    'منصة أرتياتك هي وسيط عرض واستضافة فقط، ولا تملك أي حق في التصرف '
                    'بالعمل أو الاستفادة منه تجارياً دون إذن صاحبه الصريح.',
              ),
              _LegalItem(
                'الترخيص الممنوح للمنصة',
                'بنشر عملك، تمنح أرتياتك ترخيصاً غير حصري لعرض المحتوى وتوصيله للمستخدمين '
                    'داخل التطبيق فقط. يمكنك سحب هذا الترخيص في أي وقت بحذف المحتوى.',
              ),
              _LegalItem(
                'الإبلاغ عن انتهاكات',
                'إذا رأيت محتوى ينتهك حقوقك الفكرية، تواصل معنا فوراً عبر واتساب '
                    'أو من خلال قسم "الإبلاغ عن مشكلة" في الملف الشخصي. '
                    'سنتخذ الإجراء اللازم خلال 48 ساعة.',
              ),
              _LegalItem(
                'الأعمال المبنية على أدوات أخرى',
                'إذا استخدمت أدوات كـ Scratch أو محركات ألعاب مفتوحة المصدر، '
                    'يجب الإشارة إليها في وصف العمل، مع الالتزام بشروط ترخيصها الأصلية.',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ─── تحديد المسؤولية ───────────────
          _LegalSection(
            isDark: isDark,
            emoji: '🛡️',
            title: 'تحديد المسؤولية',
            color: Colors.redAccent,
            items: [
              _LegalItem(
                'إخلاء المسؤولية',
                'تقدَّم خدمات أرتياتك "كما هي" دون أي ضمانات صريحة أو ضمنية. '
                    'لا تتحمل المنصة المسؤولية عن أي أضرار مباشرة أو غير مباشرة ناتجة عن '
                    'استخدام الخدمة أو المحتوى المنشور من قِبَل المستخدمين.',
              ),
              _LegalItem(
                'تعطل الخدمة',
                'قد تنقطع الخدمة أحياناً بسبب صيانة مجدولة أو ظروف غير متوقعة. '
                    'نسعى دائماً لضمان أعلى معدل توفر، لكننا لا نضمن توفر الخدمة 100% من الوقت.',
              ),
            ],
          ),

          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text(
                  'هذه الشروط مبنية على مبادئ جوجل للمنصات الرقمية',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر تحديث: أبريل 2026',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────

class _LegalItem {
  final String title, content;
  const _LegalItem(this.title, this.content);
}

class _LegalSection extends StatelessWidget {
  final String emoji, title;
  final Color color;
  final List<_LegalItem> items;
  final bool isDark;

  const _LegalSection({
    required this.emoji,
    required this.title,
    required this.color,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // بنود القسم
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A30) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            item.content,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.65,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 18, endIndent: 18),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
