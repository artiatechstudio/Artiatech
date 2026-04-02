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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => setState(() => _isLoading = false)),
      );
    _loadGame();
  }

  void _loadGame() {
    if (widget.htmlContent.startsWith('http')) {
      _controller.loadRequest(Uri.parse(widget.htmlContent));
    } else {
      String frame = widget.htmlContent.contains('<iframe') 
        ? widget.htmlContent 
        : '<iframe src="$widget.htmlContent" width="100%" height="100%"></iframe>';
      
      _controller.loadHtmlString("""
        <!DOCTYPE html><html>
        <head><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>
        body { margin:0; padding:0; background:black; height:100vh; display:flex; justify-content:center; align-items:center; overflow:hidden; }
        iframe { border:none; width:100vw; height:100vh; }
        </style></head>
        <body>$frame</body></html>
      """);
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "تاريخ غير متاح";
    try { return DateFormat('yyyy/MM/dd').format(ts.toDate()); } catch (e) { return ts.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isPlaying ? _buildGameScreen() : _buildWelcomeScreen(),
    );
  }

  Widget _buildGameScreen() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        Positioned(
          top: 40, right: 20,
          child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => setState(() => _isPlaying = false)),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
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
                Text(widget.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text('بواسطة: ${widget.publisher}', style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.description, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
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
