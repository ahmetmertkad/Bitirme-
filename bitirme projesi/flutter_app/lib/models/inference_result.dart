class InferenceResult {
  final String rawLabel;
  final String plantType;
  final String diseaseName;
  final double confidence;

  const InferenceResult({
    required this.rawLabel,
    required this.plantType,
    required this.diseaseName,
    required this.confidence,
  });

  bool get isHealthy => diseaseName.toLowerCase().contains('healthy');

  factory InferenceResult.fromJson(Map<String, dynamic> json) {
    final confidenceValue = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    return InferenceResult(
      rawLabel: (json['label'] ?? '').toString(),
      plantType: (json['plant_type'] ?? '').toString(),
      diseaseName: (json['disease'] ?? '').toString(),
      confidence: confidenceValue,
    );
  }
}
