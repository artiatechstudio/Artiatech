import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AppDetailsPage extends StatefulWidget {
  final String appId;
  final Map<String, dynamic> data;

  const AppDetailsPage({super.key, required this.appId, required this.data});

  @override
  State<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends State<AppDetailsPage> {
  bool _isDownloading = false;
  double _progress = 0;
  String _status = '';

  Future<void> _handleDownloadAndInstall() async {
    final url = widget.data['downloadUrl'];
    if (url == null || url.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، رابط التحميل غير متاح حالياً! ⚠️')));
       return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري فتح الرابط في المتصفح الخارجي للتحميل... 📥')));
    
    // ✅ إجبار فتح الرابط في المتصفح الخارجي لضمان استقرار التحميل والتثبيت
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في فتح الرابط: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Scaffold(
      appBar: AppBar(title: Text(d['title'] ?? 'تفاصيل التطبيق')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(d),
            const SizedBox(height: 30),

            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Theme.of(context).dividerColor,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _handleDownloadAndInstall,
                icon: const Icon(Icons.install_mobile),
                label: const Text(
                  'تثبيت التطبيق الآن',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

            const SizedBox(height: 40),
            const Text(
              'الوصف والمميزات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              d['description'] ?? 'لا يوجد وصف متاح حالياً لهذا التطبيق.', // ✅ ربط الحقل الصحيح (الوصف) بدلاً من (المحتوى)
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.6),
            ),

            const SizedBox(height: 40),
            _buildTechnicalInfo(d),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> d) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            d['thumbnailUrl'] ?? '',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.android, size: 50),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d['title'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                d['authorName'] ?? 'Artiatech Studio',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الإصدار: ${d['version'] ?? '1.0'}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(Map<String, dynamic> d) {
    final Timestamp? created = d['createdAt'] as Timestamp?;
    final Timestamp? updated = d['updatedAt'] as Timestamp?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المعلومات التقنية',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        // ✅ تم إخفاء اسم الحزمة بناءً على طلب المبدع لضمان السرية والجمالية
        // _buildInfoRow('اسم الحزمة', d['packageName'] ?? 'com.artiatech.app'), 
        _buildInfoRow('نظام التشغيل', 'Android 5.0+'),
        _buildInfoRow('رقم الإصدار', d['version'] ?? '1.0'),
        _buildInfoRow(
          'تاريخ النشر الأول',
          created?.toDate().toString().split(' ')[0] ?? 'N/A',
        ),
        if (updated != null && updated.seconds > (created?.seconds ?? 0))
          _buildInfoRow(
            'آخر تحديث',
            updated.toDate().toString().split(' ')[0],
            isHighlight: true,
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isHighlight ? Colors.greenAccent : null
            )
          ),
        ],
      ),
    );
  }
}
