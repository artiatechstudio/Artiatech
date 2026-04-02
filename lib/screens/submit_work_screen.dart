import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'novels/manage_chapters_page.dart';
import '../providers/user_provider.dart';

class SubmitWorkScreen extends StatefulWidget {
  const SubmitWorkScreen({super.key});

  @override
  State<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'article';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();

  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _downloadUrlController = TextEditingController();

  bool _isLoading = false;

  final Map<String, String> _types = {
    'article': 'مقالة / عمل فني',
    'art': 'فني حصري (Arts)',
    'tech': 'مشروع تقني',
    'game_html': 'لعبة HTML / سكراتش',
    'app_apk': 'تطبيق أندرويد (APK)',
    'novel': 'رواية (نظام الفصول)',
  };

  void _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _thumbnailController.text = base64Encode(bytes));
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Logic Leap: النشر المباشر للموثوقين
      bool skipApproval = userProvider.isAdmin || userProvider.isTrusted;
      String status = skipApproval ? 'approved' : 'pending';

      Map<String, dynamic> data = {
        'title': _titleController.text,
        'titleLower': _titleController.text.toLowerCase(),
        'description': _descriptionController.text,
        'content': _contentController.text,
        'thumbnailUrl': _thumbnailController.text,
        'type': _selectedType,
        'authorName': userProvider.profileData?['username'] ?? 'مبدع أرتياتك',
        'authorId': user.uid,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0, 'viewsCount': 0,
      };

      if (_selectedType == 'app_apk') {
        data.addAll({'packageName': _packageNameController.text, 'version': _versionController.text, 'downloadUrl': _downloadUrlController.text});
      }

      final docRef = await FirebaseFirestore.instance.collection('posts').add(data);

      if (mounted) {
         if (_selectedType == 'novel') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManageChaptersPage(novelId: docRef.id, novelTitle: _titleController.text)));
         } else {
            _sendWhatsAppNotification(context, _titleController.text, status);
            Navigator.pop(context);
         }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('نشر إبداع جديد')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'نوع العمل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان العمل', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'وصف العمل (سيظهر في المعاينة)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            if (_selectedType != 'novel' && _selectedType != 'app_apk')
              TextField(controller: _contentController, maxLines: 5, decoration: const InputDecoration(labelText: 'محتوى العمل أو الرابط', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: TextField(controller: _thumbnailController, decoration: const InputDecoration(labelText: 'صورة الغلاف (Base64)', border: OutlineInputBorder()), readOnly: true)),
              IconButton(onPressed: _pickThumbnail, icon: const Icon(Icons.image_search, size: 40, color: Colors.blueAccent)),
            ]),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _handleSubmit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('تأكيد وتقديم العمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
