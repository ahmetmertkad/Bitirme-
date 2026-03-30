import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/community_post_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingUser = true;
  UserModel? _currentUserData;

  final FirestoreService _db = FirestoreService();
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _db.getUser(user.uid);
      if (mounted) {
        setState(() {
          _currentUserData = userData;
          _isLoadingUser = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = (await _storage.uploadImage(_selectedImage!, 'community_posts', user.uid)) ?? '';
      }

      final post = CommunityPostModel(
        userId: user.uid,
        imageUrl: imageUrl,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _db.addCommunityPost(post);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Post', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0), 
              child: SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
              )
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Row
            if (_isLoadingUser)
              const Row(
                children: [
                   SizedBox(
                     width: 40,
                     height: 40,
                     child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                   ),
                   SizedBox(width: 12),
                   Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )
            else if (_currentUserData != null)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    backgroundImage: _currentUserData!.profileImageUrl != null
                        ? NetworkImage(_currentUserData!.profileImageUrl!)
                        : null,
                    radius: 20,
                    child: _currentUserData!.profileImageUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(_currentUserData!.name.isNotEmpty ? _currentUserData!.name : 'Plant Enthusiast', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            const SizedBox(height: 24),
            
            // Text Input
            TextField(
              controller: _descriptionController,
              maxLines: null,
              minLines: 4,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind? Share tips, ask questions, or show off your plants...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            
            // Image Picker Area
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_selectedImage!, height: 300, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      type: MaterialType.circle,
                      color: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => setState(() => _selectedImage = null),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid), // Using solid border instead of dotted for simplicity unless dotted_border package is available
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.primaryLight),
                      const SizedBox(height: 8),
                      const Text('Add a photo', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600))
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
