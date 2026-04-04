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
    // تغليف الأفاتار في حاوية لإضافة الظل والحدود الفاخرة
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildAvatarBody(),
    );
  }

  Widget _buildAvatarBody() {
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
          child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildErrorAvatar(),
      );
    }

    // 2. حالة الإيموجي أو Base64
    if (base64String != null && base64String!.isNotEmpty) {
      if (base64String!.length > 100) {
        try {
          final bytes = base64Decode(base64String!);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {}
      }

      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
        child: Text(
          base64String!,
          style: TextStyle(fontSize: radius * 0.8),
          textAlign: TextAlign.center,
        ),
      );
    }

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
