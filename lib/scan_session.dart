import 'dart:typed_data';

import '/beauty/beauty_models.dart';

enum ScanProductType {
  food,
  beauty,
}

extension ScanProductTypeX on ScanProductType {
  String get storageValue => this == ScanProductType.food ? 'food' : 'beauty';

  String get label => this == ScanProductType.food ? 'Food products' : 'Beauty products';

  static ScanProductType fromStorageValue(String value) {
    return value.trim().toLowerCase() == 'beauty'
        ? ScanProductType.beauty
        : ScanProductType.food;
  }
}

class ScanAnalysisResult {
  const ScanAnalysisResult({
    required this.productType,
    required this.productName,
    required this.brandName,
    required this.healthScore,
    required this.ingredients,
    required this.warnings,
    required this.benefits,
    required this.recommendation,
    required this.impactForUser,
    this.persistedByBackend = false,
  });

  final ScanProductType productType;
  final String productName;
  final String brandName;
  final int healthScore;
  final List<String> ingredients;
  final List<String> warnings;
  final List<String> benefits;
  final String recommendation;
  final String impactForUser;
  final bool persistedByBackend;
}

/// Ephemeral scan data shared across scan and insights pages.
class ScanSession {
  static Uint8List? imageBytes;
  static DateTime? scannedAt;
  static ScanAnalysisResult? latestAnalysis;
  static BeautyAnalysisResult? beautyAnalysis;
  static ScanProductType selectedProductType = ScanProductType.food;

  static void setProductType(ScanProductType type) {
    selectedProductType = type;
  }

  static void updateScan(Uint8List bytes) {
    imageBytes = bytes;
    scannedAt = DateTime.now();
    latestAnalysis = null;
    beautyAnalysis = null;
  }

  static void updateAnalysis(Uint8List bytes, ScanAnalysisResult analysis) {
    imageBytes = bytes;
    scannedAt = DateTime.now();
    latestAnalysis = analysis;
    if (analysis.productType != ScanProductType.beauty) {
      beautyAnalysis = null;
    }
  }

  static void updateAnalysisOnly(
    ScanAnalysisResult analysis, {
    Uint8List? bytes,
    DateTime? at,
  }) {
    if (bytes != null) {
      imageBytes = bytes;
    }
    scannedAt = at ?? DateTime.now();
    latestAnalysis = analysis;
    if (analysis.productType != ScanProductType.beauty) {
      beautyAnalysis = null;
    }
  }

  static void setBeautyAnalysis(BeautyAnalysisResult? analysis) {
    beautyAnalysis = analysis;
  }

  static bool get hasScan => imageBytes != null;

  static int get healthScore {
    if (latestAnalysis != null) {
      return latestAnalysis!.healthScore;
    }
    final bytes = imageBytes;
    if (bytes == null || bytes.isEmpty) {
      return 72;
    }
    // Deterministic pseudo-score from image bytes for demo purposes.
    final hash = bytes.take(64).fold<int>(0, (sum, b) => (sum + b) % 1000);
    return 45 + (hash % 51); // 45..95
  }

  static String get productName =>
      (latestAnalysis?.productName.trim().isNotEmpty == true
        ? latestAnalysis!.productName.trim()
        : (latestAnalysis?.brandName.trim().isNotEmpty == true
          ? latestAnalysis!.brandName.trim()
          : 'Unnamed product'));

  static String get brandName =>
      (latestAnalysis?.brandName.trim().isNotEmpty == true
        ? latestAnalysis!.brandName.trim()
        : '');

  static List<String> get ingredients => latestAnalysis?.ingredients ?? const [];

  static List<String> get warnings => latestAnalysis?.warnings ?? const [];

  static List<String> get benefits => latestAnalysis?.benefits ?? const [];

  static String get impactForUser => latestAnalysis?.impactForUser ?? '';

  static String get recommendation {
    if (latestAnalysis != null) {
      return latestAnalysis!.recommendation;
    }
    final score = healthScore;
    if (score >= 80) {
      return 'Great choice. Ingredients look generally safe.';
    }
    if (score >= 60) {
      return 'Moderate profile. Consider portion size and frequency.';
    }
    return 'Lower score detected. Review additives and sugar levels.';
  }

  static ScanProductType get productType =>
      latestAnalysis?.productType ?? selectedProductType;
}
