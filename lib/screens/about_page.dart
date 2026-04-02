import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('من نحن')),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const Center(child: Icon(Icons.rocket_launch, size: 80, color: Colors.blueAccent)),
          const SizedBox(height: 30),
          const Text(
            'أرتياتك ستوديو',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            'استوديو عربي صغير ومبدع يهدف لرفع جودة المحتوى الرقمي في الوطن العربي. نحن نعمل على خلق تجارب جديدة ومميزة في عالم الألعاب، البرمجة، والنشر الرقمي.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 30),
          _buildMissionPoint('🎨 دعم المبدعين', 'نحن منصة تفتح أبوابها لكل من يرغب في مشاركة فنه وتصميمه مع العالم.'),
          _buildMissionPoint('💻 التقنية للجميع', 'نقدم حلولاً تقنية ومشاريع مفتوحة المصدر لتمكين الشباب العربي في هذا المجال.'),
          _buildMissionPoint('📖 قصص وروكيات', 'نوفر بيئة آمنة للكتاب والروائيين لنشر إبداعاتهم والوصول لآلاف القراء.'),
          const SizedBox(height: 60),
          const Center(child: Text('صُنع بكل فخر في أرتياتك 😍', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMissionPoint(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
