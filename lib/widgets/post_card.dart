import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatelessWidget {
  final String title;
  final String publisher;
  final String imageUrl;
  final int likes;
  final int views;
  final VoidCallback onDownload;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.title,
    required this.publisher,
    required this.imageUrl,
    required this.likes,
    required this.views,
    required this.onDownload,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(left: 15, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          border: isDark ? Border.all(color: Colors.white10, width: 0.5) : Border.all(color: Colors.blueAccent.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.blueAccent.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // قسم الصورة مع Hero
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'post_img_${title}_${DateTime.now().millisecond}', // Tag فريد
                      child: _buildImage(context, imageUrl),
                    ),
                    // تدرج لوني لجعل النص واضحاً
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // زر الحفظ (Download/Save)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: onDownload,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.bookmark_border, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // قسم المعلومات
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              publisher,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(likes.toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(width: 8),
                              const Icon(Icons.visibility, size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(views.toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String url) {
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return Image.memory(
        base64.decode(base64String), 
        fit: BoxFit.cover, 
        errorBuilder: (_, __, ___) => const Icon(Icons.error)
      );
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          child: Icon(Icons.broken_image, color: Theme.of(context).disabledColor),
        ),
      );
    }
  }
}
