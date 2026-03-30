import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? number;
  final DateTime createdAt;
  final String? profileImageUrl;
  final int reputationScore;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.number,
    required this.createdAt,
    this.profileImageUrl,
    this.reputationScore = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      number: data['number'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      reputationScore: data['reputationScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'number': number,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'reputationScore': reputationScore,
    };
  }
}
