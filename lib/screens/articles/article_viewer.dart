import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import '../../widgets/horizontal_section.dart';
import '../../services/firestore_service.dart';

class ArticleViewer extends StatefulWidget {
  final String title;
  final String content;
  final String link;
  final String publisher;
  final dynamic createdAt;

  const ArticleViewer({
    super.key,
    required this.title,
    required this.content,
    this.link = '', 
    required this.publisher,
    required this.createdAt,
  });

  @override
  State<ArticleViewer> createState() => _ArticleViewerState();
}

class _ArticleViewerState extends State<ArticleViewer> {
  late final WebViewController _controller;
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestore = FirestoreService();
  
  bool _useWebView = false;
  bool _isLoading = true;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _showBackToTop = _scrollController.offset > 500);
    });

    if (widget.link.isNotEmpty && widget.link.startsWith('http')) {
      _useWebView = true;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) => setState(() => _isLoading = false),
          ),
        )
        ..loadRequest(Uri.parse(widget.link));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "تاريخ غير متاح";
    try { DateTime dt = timestamp.toDate(); return DateFormat('yyyy/MM/dd').format(dt); } catch (e) { return timestamp.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _useWebView ? _buildWebView() : _buildHtmlView(),
      floatingActionButton: _showBackToTop && !_useWebView ? FloatingActionButton(
        onPressed: () => _scrollController.animateTo(0, duration: const Duration(seconds: 1), curve: Curves.easeInOut),
        backgroundColor: Colors.blueAccent,
        mini: true,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildWebView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload())],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildHtmlView() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
            background: Hero(
              tag: 'post_img_${widget.title}',
              child: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blueAccent, Colors.deepPurple], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: const Icon(Icons.article, size: 100, color: Colors.white24),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(25),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                   const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                   const SizedBox(width: 8),
                   Text(widget.publisher, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                   const Spacer(),
                   Text(_formatDate(widget.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Divider(height: 50),
              HtmlWidget(widget.content, textStyle: const TextStyle(fontSize: 17, height: 1.8)),
              const SizedBox(height: 50),
              const Divider(),
              const SizedBox(height: 30),
              // اقتراحات ذكية (Logic Leap)
              HorizontalSection(
                title: '💡 إبداعات مشابهة قد تهمك',
                streamItems: _firestore.getPosts('article'),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        )
      ],
    );
  }
}
