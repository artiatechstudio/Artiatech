import 'package:cloud_firestore/cloud_firestore.dart';

class NovelModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String authorName;
  final bool isCompleted;
  final DateTime createdAt;

  NovelModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.authorName,
    required this.isCompleted,
    required this.createdAt,
  });

  factory NovelModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return NovelModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      authorName: data['authorName'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ChapterModel {
  final String id;
  final int number;
  final String title;
  final String content;

  ChapterModel({required this.id, required this.number, required this.title, required this.content});

  factory ChapterModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ChapterModel(
      id: doc.id,
      number: data['number'] ?? 0,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
    );
  }
}
