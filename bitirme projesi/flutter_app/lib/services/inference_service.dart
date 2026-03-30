import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/inference_result.dart';

class InferenceService {
  static const String _apiUrlFromEnv = String.fromEnvironment(
    'MODEL_API_URL',
    defaultValue: '',
  );

  String get _baseUrl {
    if (_apiUrlFromEnv.isNotEmpty) {
      return _apiUrlFromEnv;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  Future<InferenceResult> predictFromImage(String imagePath) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'Tahmin servisi hatası (${streamedResponse.statusCode}): $responseBody',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(responseBody) as Map<String, dynamic>;
    return InferenceResult.fromJson(json);
  }
}
