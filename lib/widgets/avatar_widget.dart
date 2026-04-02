import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWidget extends StatelessWidget {
  final String? base64String;
  final String? url;
  final String userId;
  final double radius;

  const AvatarWidget({
    super.key, 
    this.base64String, 
    this.url,
    required this.userId, 
    this.radius = 60
  });

  @override
  Widget build(BuildContext context) {
    // 1. حالة رابط الصورة (URL)
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildErrorAvatar(),
      );
    }

    // 2. حالة الإيموجي أو Base64
    if (base64String != null && base64String!.isNotEmpty) {
      // إذا كان الطول بسيطاً (إيموجي)
      if (base64String!.length < 10) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
          child: Text(base64String!, style: TextStyle(fontSize: radius * 0.8)),
        );
      }

      // إذا كان نصاً طويلاً (Base64)
      try {
        final bytes = base64Decode(base64String!);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        return _buildErrorAvatar();
      }
    }

    // 3. الحالة الافتراضية (لا توجد صورة مريحة)
    return _buildErrorAvatar();
  }

  Widget _buildErrorAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Icon(Icons.person, size: radius, color: Colors.white54),
    );
  }
}
