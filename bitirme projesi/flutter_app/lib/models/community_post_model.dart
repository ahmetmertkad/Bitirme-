import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String? postId;
  final String userId;
  final String imageUrl;
  final String description;
  final int likesCount;
  final int dislikesCount;
  final DateTime createdAt;
  final String status;
  final List<String> tags;
  final List<String> likedBy;
  final List<String> dislikedBy;

  CommunityPostModel({
    this.postId,
    required this.userId,
    required this.imageUrl,
    required this.description,
    this.likesCount = 0,
    this.dislikesCount = 0,
    required this.createdAt,
    this.status = 'Open',
    this.tags = const [],
    this.likedBy = const [],
    this.dislikedBy = const [],
  });

  factory CommunityPostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CommunityPostModel(
      postId: documentId,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      dislikesCount: data['dislikesCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Open',
      tags: List<String>.from(data['tags'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      dislikedBy: List<String>.from(data['dislikedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'description': description,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'tags': tags,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
    };
  }
}
