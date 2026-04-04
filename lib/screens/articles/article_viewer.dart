import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  WebViewController? _controller;
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestore = FirestoreService();

  bool _useWebView = false;
  bool _isLoading = true;
  bool _showBackToTop = false;
  double _loadingProgress = 0;

  /// الدومين الأصلي المسموح به فقط
  String get _allowedHost {
    if (widget.link.isEmpty) return '';
    try {
      return Uri.parse(widget.link).host;
    } catch (_) {
      return '';
    }
  }

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
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            // ── شريط التقدم ──
            onProgress: (progress) {
              setState(() {
                _loadingProgress = progress / 100.0;
                if (progress == 100) _isLoading = false;
              });
            },
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),

            // ── تقييد التنقل للدومين الأصلي فقط ──
            onNavigationRequest: (NavigationRequest request) {
              final targetHost = Uri.tryParse(request.url)?.host ?? '';
              if (targetHost == _allowedHost || request.url == widget.link) {
                return NavigationDecision.navigate;
              }
              // رابط خارجي → منع التنقل وإعلام المستخدم
              _showExternalLinkDialog(request.url);
              return NavigationDecision.prevent;
            },

            onWebResourceError: (error) {
              debugPrint('WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.link));
    }
  }

  void _showExternalLinkDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🔗 رابط خارجي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هذا الرابط يؤدي لموقع خارج التطبيق.\n\n$url',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // نسخ الرابط للحافظة كبديل آمن
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم نسخ الرابط')),
              );
            },
            child: const Text('نسخ الرابط', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "تاريخ غير متاح";
    try {
      if (timestamp is Timestamp) {
        return DateFormat('yyyy/MM/dd').format(timestamp.toDate());
      }
      return timestamp.toString();
    } catch (e) {
      return timestamp.toString();
    }
  }

  // ── زر الرجوع الذكي ──
  Future<bool> _onWillPop() async {
    if (_useWebView && _controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false; // لا تخرج من الشاشة، ارجع صفحة في WebView
    }
    return true; // خروج من الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = _useWebView && _controller != null && await _controller!.canGoBack();
        if (canGoBack) {
          _controller!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        // الأولوية لعرض المحتوى الداخلي النظيف ليبقى التطبيق "محكماً" واحترافياً
        body: (widget.content.isNotEmpty && widget.content.length > 50) 
            ? _buildHtmlView() 
            : (_useWebView ? _buildWebView() : _buildHtmlView()),
        floatingActionButton: _showBackToTop && !_useWebView
            ? FloatingActionButton(
                onPressed: () => _scrollController.animateTo(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                ),
                backgroundColor: Colors.blueAccent,
                mini: true,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildWebView() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color),
          onPressed: () async {
            if (_controller != null && await _controller!.canGoBack()) {
              _controller!.goBack();
            } else {
              if (mounted) Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _allowedHost,
              style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
            onPressed: () => _controller?.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: Colors.white12,
                  color: Colors.blueAccent,
                  minHeight: 3,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          // مؤشر التحميل الأولي فقط
          if (_isLoading && _loadingProgress == 0)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
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
            title: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
              ),
            ),
            background: Hero(
              tag: 'post_img_${widget.title}',
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
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
                  Text(
                    widget.publisher,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 50),
              HtmlWidget(widget.content, textStyle: const TextStyle(fontSize: 17, height: 1.8)),
              const SizedBox(height: 50),
              const Divider(),
              const SizedBox(height: 30),
              HorizontalSection(
                title: '💡 إبداعات مشابهة قد تهمك',
                streamItems: _firestore.getPosts('article'),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}
