import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دليل الاستخدام')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('مرحباً بك في عالم أرتياتك! إليك كيف تستخدم التطبيق بأقصى فاعلية:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 30),
          _buildItem('🎨 قسم الإبداع', 'ستجد هنا أرقى الرسوم، التصاميم، والفنون الرقمية التي يرفعها المبدعون.'),
          _buildItem('💻 قسم التقنية', 'شاركنا شغفك بالبرمجة والمشاريع التقنية، واستعرض أحدث التطورات في هذا المجال.'),
          _buildItem('📲 متجر التطبيقات', 'يمكنك استعراض وتحميل تطبيقات وألعاب APK المميزة والموثوقة من متجرنا الخاص.'),
          _buildItem('📖 المقالات والروايات', 'اقرأ محتوىً ثرياً من مدوناتنا الرسمية أو من إبداع الكتاب الآخرين.'),
          _buildItem('🤝 المتابعة والتفاعل', 'تابع مبدعيك المفضلين لتظهر أعمالهم فوراً في صفحتك الرئيسية بقسم "تتابعهم".'),
          _buildItem('📤 نشر عملك', 'اضغط على زر (+) في الأعلى للتواصل مع الإدارة عبر واتساب لنشر عملك الإبداعي رسمياً.'),
          _buildItem('💖 المعرض والمكتبة', 'استخدم زر الحفظ في أي عمل لإضافته لمعرضك المفضل أو مكتبتك الشخصية للرجوع إليه لاحقاً.'),
          const SizedBox(height: 50),
          const Center(child: Text('تحتاج لمساعدة إضافية؟ تواصل معنا عبر واتساب!', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(5)),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey)),
        ],
      ),
    );
  }
}
