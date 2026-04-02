import 'package:flutter/material.dart';

class ChapterReaderPage extends StatefulWidget {
  final String novelTitle;
  final String chapterTitle;
  final String content;

  const ChapterReaderPage({
    super.key,
    required this.novelTitle,
    required this.chapterTitle,
    required this.content,
  });

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.novelTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.chapterTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.text_increase), onPressed: () => setState(() => _fontSize += 2)),
          IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => setState(() => _fontSize -= 2)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.content,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: _fontSize, height: 1.8, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_back), label: const Text('الفصل السابق')),
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_forward), label: const Text('الفصل التالي')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
