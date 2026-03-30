import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/community_post_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'create_post_screen.dart';
import 'full_screen_image_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  
  bool _isFabVisible = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Community',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, 
            letterSpacing: 1,
            fontSize: 24,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<CommunityPostModel>>(
          stream: _db.getCommunityPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                  bottom: 120,
                ),
                itemCount: 3, // Show 3 skeleton cards while loading
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: _buildShimmerSkeleton(context),
                  );
                },
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No community posts yet.\nBe the first to share!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data!;

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                bottom: 120, // Extra space to ensure bottom-most cards clear the glassmorphism
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildPostCard(post, context),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 40.0), // Safely push it above the glassmorphic navigation bar!
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible ? 1 : 0,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add),
              label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPostModel post, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            FutureBuilder<UserModel?>(
              future: _db.getUser(post.userId),
              builder: (context, snapshot) {
                final author = snapshot.data;
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      if (isLoading)
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          child: const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                          )
                        )
                      else
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          backgroundImage: author?.profileImageUrl != null ? NetworkImage(author!.profileImageUrl!) : null,
                          child: author?.profileImageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoading ? 'Loading...' : (author?.name.isNotEmpty ?? false ? author!.name : 'Plant Enthusiast'), 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            Text(
                              _formatDate(post.createdAt),
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeletePost(post);
                          } else if (value == 'report') {
                            _confirmReportPost(post);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final currentUserId = AuthService().currentUser?.uid;
                          return [
                            if (currentUserId == post.userId)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete Post', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                              )
                            else
                              const PopupMenuItem<String>(
                                value: 'report',
                                child: Text('Report Post'),
                              ),
                          ];
                        },
                      )
                    ],
                  ),
                );
              }
            ),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                post.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 8),

            // Image
            if (post.imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageScreen(
                        imageUrl: post.imageUrl,
                        heroTag: 'post_image_${post.postId}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'post_image_${post.postId}',
                  child: Image.network(
                    post.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            
            // Actions
            Builder(
              builder: (context) {
                final currentUserId = AuthService().currentUser?.uid;
                final bool isLiked = currentUserId != null && post.likedBy.contains(currentUserId);
                final bool isDisliked = currentUserId != null && post.dislikedBy.contains(currentUserId);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: isLiked ? AppColors.primary : Colors.grey[600],
                        label: '${post.likesCount}',
                        onTap: () {
                          if (post.postId != null && currentUserId != null) {
                            _db.toggleLike(post.postId!, currentUserId);
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                        color: isDisliked ? Colors.redAccent : Colors.grey[600],
                        label: '${post.dislikesCount}',
                        onTap: () {
                          if (post.postId != null && currentUserId != null) {
                            _db.toggleDislike(post.postId!, currentUserId);
                          }
                        },
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Reply',
                        onTap: () {
                          if (post.postId != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Padding(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                child: CommentsBottomSheet(postId: post.postId!),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color ?? Colors.grey[700], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? Colors.grey[800]! : Colors.white;
    
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: skeletonColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(CommunityPostModel post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              if (post.postId != null) {
                try {
                  await _db.deleteCommunityPost(post.postId!);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmReportPost(CommunityPostModel post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Report Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to report this post to the administrators for review?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              final currentUserId = AuthService().currentUser?.uid;
              if (post.postId != null && currentUserId != null) {
                try {
                  await _db.reportCommunityPost(post.postId!, currentUserId, "Inappropriate Content");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post reported to administrators.')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to report post')));
                }
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
