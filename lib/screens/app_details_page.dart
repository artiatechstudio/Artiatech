import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (url == null || url.isEmpty) return;

    setState(() { _isDownloading = true; _progress = 0; _status = 'جاري التحقق من الأذونات...'; });

    // 1. طلب الأذونات (أندرويد)
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      var installStatus = await Permission.requestInstallPackages.request();
      if (!status.isGranted || !installStatus.isGranted) {
        setState(() { _isDownloading = false; _status = 'يرجى منح الأذونات للتحميل والتثبيت'; });
        // فتح رابط المتصفح كبديل
        launchUrl(Uri.parse(url));
        return;
      }
    }

    try {
      setState(() => _status = 'جاري تحميل ملف الـ APK...');
      final dir = await getExternalStorageDirectory(); // مجلد التنزيلات الخارجي
      final String savePath = "${dir!.path}/${widget.data['title'] ?? 'app'}.apk";

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _progress = count / total;
              _status = "جاري التحميل: ${(_progress * 100).toStringAsFixed(0)}%";
            });
          }
        },
      );

      setState(() => _status = 'اكتمل التحميل! جاري تفعيل التثبيت...');
      
      // 2. تفعيل التثبيت التلقائي (Logic Leap)
      final result = await OpenFile.open(savePath);
      
      if (result.type != ResultType.done) {
        setState(() => _status = "خطأ في فتح الملف: ${result.message}");
        launchUrl(Uri.parse(url)); // fallback
      }

    } catch (e) {
      setState(() => _status = 'فشل التحميل التلقائي، جاري التحميل عبر المتصفح...');
      launchUrl(Uri.parse(url));
    } finally {
      setState(() => _isDownloading = false);
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
              Column(children: [
                LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey[800], color: Colors.greenAccent),
                const SizedBox(height: 10),
                Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])
            else
              ElevatedButton.icon(
                onPressed: _handleDownloadAndInstall,
                icon: const Icon(Icons.install_mobile),
                label: const Text('تثبيت التطبيق الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),

            const SizedBox(height: 40),
            const Text('الوصف والمميزات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(d['content'] ?? 'لا يوجد وصف متاح.', style: const TextStyle(color: Colors.white70, height: 1.6)),
            
            const SizedBox(height: 40),
            _buildTechnicalInfo(d),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> d) {
    return Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(d['thumbnailUrl'] ?? '', width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.android, size: 50))),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(d['authorName'] ?? 'Artiatech Studio', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('الإصدار: ${d['version'] ?? '1.0'}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))),
      ])),
    ]);
  }

  Widget _buildTechnicalInfo(Map<String, dynamic> d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('المعلومات التقنية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      _buildInfoRow('اسم الحزمة', d['packageName'] ?? 'com.artiatech.app'),
      _buildInfoRow('نظام التشغيل', 'Android 5.0+'),
      _buildInfoRow('تاريخ التحديث', (d['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A'),
    ]);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));
  }
}
