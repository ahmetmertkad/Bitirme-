import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  static const String _imgBbApiKey = 'e7fc0f82290a9e83a1a8a591ab330cb8';

  // Upload image to ImgBB and return the direct URL
  Future<String?> uploadImage(File imageFile, String folderName, String userId) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload'));
      request.fields['key'] = _imgBbApiKey;
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['data']['url'];
      } else {
        debugPrint('Error uploading to ImgBB: ${response.statusCode}');
        throw Exception('Failed to upload image. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading to ImgBB: $e');
      rethrow;
    }
  }

  // Delete image (ImgBB API doesn't support direct deletion without additional auth/tokens for guest uploads)
  // We'll leave this empty or mock it, as Firebase Storage deletion is no longer applicable.
  Future<void> deleteImage(String fileUrl) async {
    debugPrint('Note: Image deletion is an enterprise ImgBB feature or requires user tokens. Skipping.');
  }
}
