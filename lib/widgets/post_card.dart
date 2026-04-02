import 'package:flutter/material.dart';
import 'dart:convert';

class PostCard extends StatelessWidget {
  final String title;
  final String publisher;
  final String imageUrl;
  final int likes;
  final VoidCallback onDownload;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.title,
    required this.publisher,
    required this.imageUrl,
    required this.likes,
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
        margin: const EdgeInsets.only(left: 15, bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
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
                      child: _buildImage(imageUrl),
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

  Widget _buildImage(String url) {
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return Image.memory(base64.decode(base64String), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.error));
    } else {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white)),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
        },
      );
    }
  }
}
