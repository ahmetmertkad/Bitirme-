import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/plant_scan_model.dart';
import '../models/community_post_model.dart';
import '../models/comment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // --- Plant Scans ---
  Future<void> addPlantScan(PlantScanModel scan) async {
    await _db.collection('plants').add(scan.toMap());
  }

  Stream<List<PlantScanModel>> getUserPlantScans(String userId) {
    return _db.collection('plants')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PlantScanModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- Community Posts ---
  Future<void> addCommunityPost(CommunityPostModel post) async {
    await _db.collection('community_posts').add(post.toMap());
  }

  Future<void> deleteCommunityPost(String postId) async {
    // Delete the post document
    await _db.collection('community_posts').doc(postId).delete();
    
    // Cleanup associated comments
    final commentsSnapshot = await _db.collection('post_comments').where('postId', isEqualTo: postId).get();
    for (var doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> reportCommunityPost(String postId, String reporterId, String reason) async {
    await _db.collection('reported_posts').add({
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'reportedAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending | reviewed | dismissed
    });
  }

  Stream<List<CommunityPostModel>> getCommunityPosts() {
    return _db.collection('community_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CommunityPostModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _db.collection('community_posts').doc(postId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);
      
      int likesCount = data['likesCount'] ?? 0;
      int dislikesCount = data['dislikesCount'] ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likesCount--;
      } else {
        likedBy.add(userId);
        likesCount++;
        if (dislikedBy.contains(userId)) {
          dislikedBy.remove(userId);
          dislikesCount--;
        }
      }

      transaction.update(docRef, {
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
      });
    });
  }

  Future<void> toggleDislike(String postId, String userId) async {
    final docRef = _db.collection('community_posts').doc(postId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);
      
      int likesCount = data['likesCount'] ?? 0;
      int dislikesCount = data['dislikesCount'] ?? 0;

      if (dislikedBy.contains(userId)) {
        dislikedBy.remove(userId);
        dislikesCount--;
      } else {
        dislikedBy.add(userId);
        dislikesCount++;
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          likesCount--;
        }
      }

      transaction.update(docRef, {
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
        'likesCount': likesCount,
        'dislikesCount': dislikesCount,
      });
    });
  }

  // --- Comments ---
  Future<void> addComment(CommentModel comment) async {
    await _db.collection('post_comments').add(comment.toMap());
  }

  Stream<List<CommentModel>> getPostComments(String postId) {
    return _db.collection('post_comments')
      .where('postId', isEqualTo: postId)
      .snapshots()
      .map((snapshot) {
        final comments = snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return comments;
      });
  }
}
