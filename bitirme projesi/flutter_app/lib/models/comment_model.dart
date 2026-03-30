import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String? commentId;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final bool isAcceptedAnswer;

  CommentModel({
    this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.isAcceptedAnswer = false,
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CommentModel(
      commentId: documentId,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAcceptedAnswer: data['isAcceptedAnswer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAcceptedAnswer': isAcceptedAnswer,
    };
  }
}
