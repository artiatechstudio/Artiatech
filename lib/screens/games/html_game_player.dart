import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

class HtmlGamePlayer extends StatefulWidget {
  final String title;
  final String htmlContent;
  final String description;
  final String publisher;
  final dynamic createdAt;

  const HtmlGamePlayer({
    super.key, 
    required this.title, 
    required this.htmlContent,
    required this.description,
    required this.publisher,
    required this.createdAt,
  });

  @override
  State<HtmlGamePlayer> createState() => _HtmlGamePlayerState();
}

class _HtmlGamePlayerState extends State<HtmlGamePlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isPlaying = false;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() {
            _loadingProgress = p / 100.0;
            if (p == 100) _isLoading = false;
          }),
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      );
    _loadGame();
  }

  /// يحدد طريقة التحميل بناءً على نوع المحتوى:
  /// 1. رابط http  → loadRequest مباشرة (مصدر بلوجر أو رابط مدخَل)
  /// 2. محتوى يحوي <iframe> → نلفّه داخل صفحة HTML بسيطة
  /// 3. محتوى HTML كامل → نمرره كـ loadHtmlString مباشرة
  void _loadGame() {
    final src = widget.htmlContent.trim();

    // ── حالة 1: رابط مباشر (بلوجر أو Scratch أو أي URL) ──
    if (src.startsWith('http://') || src.startsWith('https://')) {
      final iframeTag = '<iframe src="$src" allowfullscreen></iframe>';
      _controller.loadHtmlString(_wrapInPage(iframeTag));
      return;
    }

    // ── حالة 2: كود iframe فقط (بدون <html>) ──
    if (src.contains('<iframe') && !src.contains('<html')) {
      _controller.loadHtmlString(_wrapInPage(src));
      return;
    }

    // ── حالة 3: HTML كامل (من بلوجر أو مدخَل يدوياً) ──
    // نُزيل منه كل شيء ونبقي فقط أول iframe إن وُجد
    final iframeMatch = RegExp(
      r'<iframe[^>]*>.*?<\/iframe>|<iframe[^>]*/?>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(src);
    
    if (iframeMatch != null) {
      String iframeTag = iframeMatch.group(0)!;
      // نعدل الـ iframe لضمان الملائمة
      iframeTag = iframeTag.replaceAll(RegExp(r'width="[^"]*"'), 'width="100%"');
      iframeTag = iframeTag.replaceAll(RegExp(r'height="[^"]*"'), 'height="100%"');
      _controller.loadHtmlString(_wrapInPage(iframeTag));
    } else {
      // إذا لم نجد iframe، نمرر المحتوى كما هو (كحالة احتياطية)
      _controller.loadHtmlString(src);
    }
  }

  String _wrapInPage(String iframe) => """
<!DOCTYPE html>
<html>
<head>
  <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body { 
      width:100%; height:100%; 
      background:#000; 
      display: flex;
      align-items: center;
      justify-content: center;
      overflow:hidden; 
    }
    .game-container {
      width: 95vw;
      height: 90vh;
      max-width: 1200px;
      position: relative;
      background: #111;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 0 50px rgba(0,0,0,0.8);
      border: 2px solid #333;
    }
    iframe { 
      border:none; 
      width:100% !important; 
      height:100% !important; 
      display:block; 
    }
  </style>
</head>
<body>
  <div class='game-container'>$iframe</div>
</body>
</html>
""";


  String _formatDate(dynamic ts) {
    if (ts == null) return "تاريخ غير متاح";
    try { return DateFormat('yyyy/MM/dd').format(ts.toDate()); } catch (e) { return ts.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPlaying ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: _isPlaying ? _buildGameScreen() : _buildWelcomeScreen(),
    );
  }

  Widget _buildGameScreen() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          _controller.goBack();
        } else {
          setState(() => _isPlaying = false);
        }
      },
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // ── شريط التقدم ──
          if (_isLoading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress : null,
                backgroundColor: Colors.white12,
                color: Colors.blueAccent,
                minHeight: 3,
              ),
            ),
          // ── زر الإغلاق ──
          Positioned(
            top: 40, right: 16,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => setState(() => _isPlaying = false),
                tooltip: 'إغلاق اللعبة',
              ),
            ),
          ),
          // مؤشر التحميل الأولي
          if (_isLoading && _loadingProgress == 0)
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'post_img_${widget.title}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                   const Icon(Icons.videogame_asset_outlined, size: 100, color: Colors.blueAccent),
                   const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter)))
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                const SizedBox(height: 10),
                Text('بواسطة: ${widget.publisher}', style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.description, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 16, height: 1.6)),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isPlaying = true),
                  icon: const Icon(Icons.play_arrow_rounded, size: 30),
                  label: const Text('تشغيل اللعبة الآن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 15,
                  ),
                ),
                const SizedBox(height: 30),
                Center(child: Text('تاريخ الإصدار متاح بالداخل • ${_formatDate(widget.createdAt)}', style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 100),
              ],
            ),
          ),
        )
      ],
    );
  }
}
