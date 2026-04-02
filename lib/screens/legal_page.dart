import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الوثائق القانونية')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildCard(context, '🔒 سياسة الخصوصية', 'نحن في أرتياتك نلتزم بحماية بياناتك الشخصية وفقاً لمعايير جوجل العالمية. نحن لا نشارك بيانات تسجيل الدخول أو البريد الإلكتروني مع أي طرف ثالث. تُستخدم البيانات فقط لتحسين تجربتك وتقديم محتوى مخصص لك.'),
          const SizedBox(height: 20),
          _buildCard(context, '⚖️ شروط الاستخدام', 'يُمنع منعاً باتاً نشر محتوى مسروق، مسيء، أو ينتهك القيم العامة. تحتفظ إدارة أرتياتك بالحق في حذف أي حساب ينتهك هذه القوانين دون سابق إنذار لحماية أمن وسلامة المجتمع الرقمي العربي.'),
          const SizedBox(height: 20),
          _buildCard(context, '📜 حقوق الملكية الفكرية', 'نحن في أرتياتك نؤمن بحق المبدع الأصيل. تماماً كما في "يوتيوب" و"واتباد"، تبقى جميع حقوق النشر والملكية الفكرية للأعمال المنشورة "محفوظة للناشر نفسه". المنصة هي وسيط عرض واستضافة فقط، ولا تملك أي حق في التصرف بالعمل دون إذن صاحبه.'),
          const SizedBox(height: 30),
          const Center(child: Text('آخر تحديث: أبريل 2026', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 15),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
