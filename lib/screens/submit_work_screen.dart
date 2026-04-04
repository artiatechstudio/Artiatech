import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'novels/manage_chapters_page.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'auth/login_screen.dart';

class SubmitWorkScreen extends StatefulWidget {
  const SubmitWorkScreen({super.key});

  @override
  State<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'article';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();

  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _downloadUrlController = TextEditingController();

  bool _isLoading = false;

  String _convertToDirectLink(String url) {
    if (url.contains('drive.google.com')) {
      final regExp = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        return 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
      }
    } else if (url.contains('dropbox.com')) {
       return url.replaceAll('?dl=0', '?dl=1');
    }
    return url;
  }

  Map<String, String> _getTypes(bool isAdmin) {
    var map = {
      'article': 'مقالة / عمل فني',
      'art': 'فني حصري (Arts)',
      'tech': 'مشروع تقني',
      'game_html': 'لعبة HTML / سكراتش',
      'app_apk': 'تطبيق أندرويد (APK)',
      'novel': 'رواية (نظام الفصول)',
    };
    if (isAdmin) map['announcement'] = 'إعلان / تعميم (أدمن فقط)';
    return map;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool skipApproval = userProvider.isAdmin || userProvider.isTrusted;
      String status = skipApproval ? 'approved' : 'pending';

      Map<String, dynamic> data = {
        'title': _titleController.text,
        'titleLower': _titleController.text.toLowerCase(),
        'description': _descriptionController.text,
        'content': _selectedType == 'app_apk' ? '' : _convertToDirectLink(_contentController.text), // ✅ تحويل روابط الألعاب
        'thumbnailUrl': _thumbnailController.text,
        'type': _selectedType,
        'authorName': userProvider.profileData?['username'] ?? 'مبدع أرتياتك',
        'authorId': user.uid,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedType == 'app_apk') {
        data.addAll({
          'packageName': _packageNameController.text, 
          'version': _versionController.text, 
          'downloadUrl': _convertToDirectLink(_downloadUrlController.text) // ✅ تحويل روابط التطبيقات
        });

        final existingApps = await FirebaseFirestore.instance.collection('posts')
            .where('type', isEqualTo: 'app_apk')
            // .where('authorId', isEqualTo: user.uid) // إزالة هذا القيد مؤقتاً لتسهيل الاختبار أو إذا كان الأدمن يريد تحديث تطبيق غيره
            .where('packageName', isEqualTo: _packageNameController.text)
            .limit(1)
            .get();

        if (existingApps.docs.isNotEmpty) {
          final docId = existingApps.docs.first.id;
          final docData = existingApps.docs.first.data();
          
          // ✅ منع التكرار الصارم: إذا كان اسم الحزمة موجوداً، إما بنحدّثه أو نرفض النشر
          if (docData['authorId'] == user.uid || userProvider.isAdmin) {
             await FirebaseFirestore.instance.collection('posts').doc(docId).update(data);
             
             final fs = FirestoreService();
             await fs.notifyFollowers(authorId: user.uid, authorName: data['authorName'], postId: docId, postTitle: _titleController.text, type: 'app_update');
             
             if (userProvider.isAdmin) {
                await fs.createSystemAnnouncement('تحديث تطبيق: ${_titleController.text}', 'يتوفر إصدار جديد رقم (${_versionController.text})! 🚀');
             }

             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث تطبيقك الحالي بنجاح! ✅')));
               Navigator.pop(context);
             }
             return; // خروج لضمان عدم التكرار
          } else {
             // ❌ إذا كان اسم الحزمة محجوزاً لشخص آخر
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.redAccent, content: Text('خطأ: اسم الحزمة هذا محجوز لتطبيق آخر! يرجى التواصل مع الإدارة. ⚠️')));
             }
             setState(() => _isLoading = false);
             return; // منع النشر نهائياً
          }
        }
      }

      final docRef = await FirebaseFirestore.instance.collection('posts').add(data);
      
      // إخطار المتابعين بالعمل الجديد
      await FirestoreService().notifyFollowers(authorId: user.uid, authorName: data['authorName'], postId: docRef.id, postTitle: _titleController.text, type: 'new_post');

      // إرسال إشعار الواتساب للإدمن أولاً لضمان عدم إهمال أي عمل
      _sendWhatsAppNotification(context, _titleController.text, status);

      if (mounted) {
         if (_selectedType == 'novel') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageChaptersPage(novelId: docRef.id, novelTitle: _titleController.text)));
         } else {
            Navigator.pop(context);
         }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendWhatsAppNotification(BuildContext context, String title, String status) async {
    if (status == 'approved') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تهانينا! تم النشر الفوري لكونك مبدعاً موثوقاً! 🎉')));
       return;
    }
    const phone = "+218929196425";
    final msg = "طلب نشر جديد: $title\nالرجاء المراجعة والموافقة.";
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildLoggedOutView(context);

    final userProvider = context.watch<UserProvider>();
    final types = _getTypes(userProvider.isAdmin);
    if (!types.containsKey(_selectedType)) _selectedType = 'article';

    return Scaffold(
      appBar: AppBar(title: const Text('نشر إبداع جديد')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'نوع العمل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController, 
              validator: (v) => v!.isEmpty ? 'يرجى إدخال العنوان' : null,
              decoration: const InputDecoration(labelText: 'عنوان العمل', border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController, 
              validator: (v) => v!.isEmpty ? 'يرجى إدخال وصف مختصر' : null,
              decoration: const InputDecoration(labelText: 'وصف العمل (سيظهر في المعاينة)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            
            // محتوى العمل أو الرابط
            if (_selectedType != 'novel' && _selectedType != 'app_apk')
              TextFormField(
                controller: _contentController, 
                maxLines: 5, 
                validator: (v) => v!.isEmpty ? 'يرجى إدخال المحتوى أو الرابط' : null,
                decoration: const InputDecoration(labelText: 'محتوى العمل أو الرابط', border: OutlineInputBorder())
              ),
              
            // طلب بيانات التطبيق إذا اختار المستخدم APK
            if (_selectedType == 'app_apk') ...[
              const SizedBox(height: 15),
              TextFormField(
                controller: _packageNameController, 
                validator: (v) => (v!.isEmpty && _selectedType == 'app_apk') ? 'مطلوب للتطبيقات' : null,
                decoration: const InputDecoration(labelText: 'اسم الحزمة (مثال: com.artiatech.app)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _versionController, 
                validator: (v) => (v!.isEmpty && _selectedType == 'app_apk') ? 'مطلوب للتطبيقات' : null,
                decoration: const InputDecoration(labelText: 'رقم الإصدار (مثال: 1.0.0)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _downloadUrlController, 
                validator: (v) => (v!.isEmpty && _selectedType == 'app_apk') ? 'مطلوب للتطبيقات' : null,
                decoration: const InputDecoration(labelText: 'رابط التحميل المباشر (APK URL)', border: OutlineInputBorder())
              ),
            ],

            const SizedBox(height: 30),
            
            // إرشادات رفع الصورة كرابط بدلاً من رفعها (عن طريق Storage المعطل)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 تنويه هام بخصوص الصور:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  SizedBox(height: 5),
                  Text('يرجى لصق "رابط مباشر" لصورة العمل (ينتهي بـ .png أو .jpg).', style: TextStyle(fontSize: 12)),
                  Text('إذا لم يكن لديك رابط، يمكنك رفع صورتك على مواقع مثل (Imgur.com) أو (Postimages.org) ونسخ "الرابط المباشر" الخاص بها ثم لصقه هنا.', style: TextStyle(fontSize: 12, height: 1.5)),
                ]
              )
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _thumbnailController, 
              validator: (v) => v!.isEmpty ? 'يرجى وضع رابط الصورة' : null,
              decoration: const InputDecoration(
                labelText: 'رابط صورة الغلاف (URL)', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              )
            ),

            const SizedBox(height: 40),
            ElevatedButton(onPressed: _handleSubmit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('تأكيد وتقديم العمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشر إبداع جديد')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('يرجى تسجيل الدخول لتتمكن من نشر أعمالك'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('تسجيل الدخول الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
