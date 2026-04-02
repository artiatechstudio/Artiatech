import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';

class ManageChaptersPage extends StatefulWidget {
  final String novelId;
  final String novelTitle;

  const ManageChaptersPage({
    super.key,
    required this.novelId,
    required this.novelTitle,
  });

  @override
  State<ManageChaptersPage> createState() => _ManageChaptersPageState();
}

class _ManageChaptersPageState extends State<ManageChaptersPage> {
  final FirestoreService _firestore = FirestoreService();
  final _chapterTitleController = TextEditingController();
  final _chapterContentController = TextEditingController();
  final _numberController = TextEditingController();
  bool _isLoading = false;

  void _handleAddChapter() async {
    if (_chapterTitleController.text.isEmpty || _chapterContentController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      
      // Logic Leap: النشر الفوري للفصل للموثوقين
      await _firestore.addChapter(
        widget.novelId,
        int.parse(_numberController.text.isNotEmpty ? _numberController.text : '1'),
        _chapterTitleController.text,
        _chapterContentController.text,
        isTrusted: userProvider.isAdmin || userProvider.isTrusted,
      );

      String msg = (userProvider.isAdmin || userProvider.isTrusted) 
        ? 'تهانينا! تم النشر الفوري لهذا الفصل! 🎉' 
        : 'تم تقديم الفصل بنجاح بانتظار المراجعة! ⏳';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      _chapterTitleController.clear();
      _chapterContentController.clear();
      Navigator.pop(context); // العودة بعد الإضافة
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة فصول ${widget.novelTitle}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'رقم الفصل', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _chapterTitleController, decoration: const InputDecoration(labelText: 'عنوان الفصل', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Expanded(
              child: TextField(
                controller: _chapterContentController,
                maxLines: 20,
                decoration: const InputDecoration(labelText: 'محتوى الفصل (نص قصة الرواية)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _handleAddChapter,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('إضافة هذا الفصل للرواية الآن', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
