import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/scan_session.dart';

class ScanAnalyzer {
  static const String _analyzeFunctionUrl = String.fromEnvironment(
    'SCAN_ANALYZE_FUNCTION_URL',
    defaultValue:
        'https://us-central1-ai-health-scanner-5e3b9.cloudfunctions.net/analyzeProductScan',
  );
  static const bool _useCloudOnWeb = bool.fromEnvironment(
    'SCAN_USE_CLOUD_ON_WEB',
    defaultValue: false,
  );

  static Future<ScanAnalysisResult> analyze({
    required Uint8List imageBytes,
    ProfilesRecord? profile,
  }) async {
    ScanAnalysisResult initial;

    if (kIsWeb && !_useCloudOnWeb) {
      initial = await _fallbackWithLabelName(imageBytes, profile);
      return _enrichFromOnlineCatalog(initial, profile);
    }

    if (!loggedIn || currentJwtToken.trim().isEmpty) {
      initial = await _fallbackWithLabelName(imageBytes, profile);
      return _enrichFromOnlineCatalog(initial, profile);
    }

    try {
        initial = await _analyzeWithCloudFunction(
          imageBytes: imageBytes, profile: profile);
        initial = await _ensureProductNameFromLabel(initial, imageBytes);
      return _enrichFromOnlineCatalog(initial, profile);
    } catch (_) {
      initial = await _fallbackWithLabelName(imageBytes, profile);
      return _enrichFromOnlineCatalog(initial, profile);
    }
  }

  static Future<ScanAnalysisResult> _enrichFromOnlineCatalog(
    ScanAnalysisResult base,
    ProfilesRecord? profile,
  ) async {
    final name = base.productName.trim();
    if (name.isEmpty || name.toLowerCase() == 'unnamed product') {
      return base;
    }

    final fetched = await _fetchCatalogByName(name);
    if (fetched == null) {
      return base;
    }

    final ingredientsFromCatalog = _splitIngredients(
      _asString(
        fetched['ingredients_text_en'] ?? fetched['ingredients_text'],
        fallback: '',
      ),
    );
    final ingredients =
        ingredientsFromCatalog.isNotEmpty ? ingredientsFromCatalog : base.ingredients;

    final sugars = _asDouble(fetched['nutriments']?['sugars_100g']);
    final salt = _asDouble(fetched['nutriments']?['salt_100g']);
    final saturatedFat = _asDouble(fetched['nutriments']?['saturated-fat_100g']);
    final fiber = _asDouble(fetched['nutriments']?['fiber_100g']);
    final protein = _asDouble(fetched['nutriments']?['proteins_100g']);
    final kcal = _asDouble(
      fetched['nutriments']?['energy-kcal_100g'] ??
          fetched['nutriments']?['energy-kcal_value'],
    );

    final warnings = _buildWarningsFromNutrition(
      baseWarnings: base.warnings,
      sugars: sugars,
      salt: salt,
      saturatedFat: saturatedFat,
      ingredients: ingredients,
    );
    final benefits = _buildBenefitsFromNutrition(
      baseBenefits: base.benefits,
      fiber: fiber,
      protein: protein,
      ingredients: ingredients,
    );

    final catalogProductName = _normalizeProductName(
      _asString(fetched['product_name'], fallback: ''),
      _asString(fetched['brands'], fallback: ''),
    );
    final productName = catalogProductName.isNotEmpty ? catalogProductName : base.productName;
    final brandName = _normalizeBrandName(
      _asString(fetched['brands'], fallback: base.brandName),
    );

    final score = _deriveHealthScore(
      currentScore: base.healthScore,
      sugars: sugars,
      salt: salt,
      saturatedFat: saturatedFat,
      fiber: fiber,
      protein: protein,
      kcal: kcal,
    );

    final recommendation = _buildRecommendationFromNutrition(
      score: score,
      sugars: sugars,
      salt: salt,
      saturatedFat: saturatedFat,
      fiber: fiber,
      protein: protein,
      kcal: kcal,
      fallback: base.recommendation,
    );

    final impactForUser = _buildImpactForProfile(
      profile: profile,
      ingredients: ingredients,
      sugars: sugars,
      salt: salt,
      fallback: base.impactForUser,
    );

    return ScanAnalysisResult(
      productName: productName,
      brandName: brandName,
      healthScore: score,
      ingredients: ingredients,
      warnings: warnings,
      benefits: benefits,
      recommendation: recommendation,
      impactForUser: impactForUser,
      persistedByBackend: base.persistedByBackend,
    );
  }

  static Future<ScanAnalysisResult> _ensureProductNameFromLabel(
    ScanAnalysisResult base,
    Uint8List imageBytes,
  ) async {
    final existingName = base.productName.trim();
    if (existingName.isNotEmpty && existingName.toLowerCase() != 'unnamed product') {
      return base;
    }
    final extracted = await _extractProductFromLabel(imageBytes);
    if (extracted == null) {
      return base;
    }
    final productName = _normalizeProductName(
      _asString(extracted['productName'], fallback: ''),
      _asString(extracted['brandName'], fallback: base.brandName),
    );
    final brandName = _normalizeBrandName(
      _asString(extracted['brandName'], fallback: base.brandName),
    );
    if (productName.isEmpty && brandName.isEmpty) {
      return base;
    }
    return ScanAnalysisResult(
      productName: productName.isNotEmpty ? productName : base.productName,
      brandName: brandName,
      healthScore: base.healthScore,
      ingredients: base.ingredients,
      warnings: base.warnings,
      benefits: base.benefits,
      recommendation: base.recommendation,
      impactForUser: base.impactForUser,
      persistedByBackend: base.persistedByBackend,
    );
  }

  static Future<Map<String, dynamic>?> _fetchCatalogByName(String productName) async {
    try {
      final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
        'search_terms': productName,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '1',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'];
      if (products is List && products.isNotEmpty && products.first is Map) {
        return Map<String, dynamic>.from(products.first as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static List<String> _splitIngredients(String value) {
    return value
        .split(RegExp(r',|;'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(12)
        .toList();
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static List<String> _buildWarningsFromNutrition({
    required List<String> baseWarnings,
    required double? sugars,
    required double? salt,
    required double? saturatedFat,
    required List<String> ingredients,
  }) {
    final warnings = <String>[];
    if (sugars != null && sugars >= 15) {
      warnings.add('High sugar (${sugars.toStringAsFixed(1)}g/100g)');
    }
    if (salt != null && salt >= 1.5) {
      warnings.add('High salt (${salt.toStringAsFixed(2)}g/100g)');
    }
    if (saturatedFat != null && saturatedFat >= 5) {
      warnings.add('High saturated fat (${saturatedFat.toStringAsFixed(1)}g/100g)');
    }
    final source = ingredients.join(' ').toLowerCase();
    if (source.contains('palm oil')) {
      warnings.add('Contains palm oil');
    }
    if (source.contains('flavour') || source.contains('flavor')) {
      warnings.add('Contains flavor additives');
    }
    if (warnings.isEmpty) {
      warnings.addAll(baseWarnings);
    }
    return warnings.take(3).toList();
  }

  static List<String> _buildBenefitsFromNutrition({
    required List<String> baseBenefits,
    required double? fiber,
    required double? protein,
    required List<String> ingredients,
  }) {
    final benefits = <String>[];
    if (fiber != null && fiber >= 3) {
      benefits.add('Good fiber (${fiber.toStringAsFixed(1)}g/100g)');
    }
    if (protein != null && protein >= 8) {
      benefits.add('Useful protein (${protein.toStringAsFixed(1)}g/100g)');
    }
    final source = ingredients.join(' ').toLowerCase();
    if (source.contains('oat') || source.contains('whole grain')) {
      benefits.add('Contains whole-grain ingredients');
    }
    if (benefits.isEmpty) {
      benefits.addAll(baseBenefits);
    }
    return benefits.take(3).toList();
  }

  static int _deriveHealthScore({
    required int currentScore,
    required double? sugars,
    required double? salt,
    required double? saturatedFat,
    required double? fiber,
    required double? protein,
    required double? kcal,
  }) {
    var score = currentScore;
    if (sugars != null) {
      score -= (sugars / 2).round();
    }
    if (salt != null) {
      score -= (salt * 8).round();
    }
    if (saturatedFat != null) {
      score -= (saturatedFat * 2).round();
    }
    if (fiber != null) {
      score += (fiber * 1.2).round();
    }
    if (protein != null) {
      score += (protein / 3).round();
    }
    if (kcal != null && kcal > 450) {
      score -= 6;
    }
    return score.clamp(1, 100);
  }

  static String _buildRecommendationFromNutrition({
    required int score,
    required double? sugars,
    required double? salt,
    required double? saturatedFat,
    required double? fiber,
    required double? protein,
    required double? kcal,
    required String fallback,
  }) {
    final details = <String>[];
    if (sugars != null) details.add('sugar ${sugars.toStringAsFixed(1)}g');
    if (salt != null) details.add('salt ${salt.toStringAsFixed(2)}g');
    if (saturatedFat != null) {
      details.add('sat fat ${saturatedFat.toStringAsFixed(1)}g');
    }
    if (fiber != null) details.add('fiber ${fiber.toStringAsFixed(1)}g');
    if (protein != null) details.add('protein ${protein.toStringAsFixed(1)}g');
    if (kcal != null) details.add('${kcal.toStringAsFixed(0)} kcal/100g');

    final base = score >= 80
        ? 'Good profile for regular use in balanced portions.'
        : score >= 60
            ? 'Moderate profile; keep portions controlled and not too frequent.'
            : 'Lower profile; limit frequency and pair with less processed foods.';

    if (details.isEmpty) {
      return fallback;
    }
    return '$base Nutrition: ${details.join(', ')}.';
  }

  static String _buildImpactForProfile({
    required ProfilesRecord? profile,
    required List<String> ingredients,
    required double? sugars,
    required double? salt,
    required String fallback,
  }) {
    final diet = _asString(profile?.dietType, fallback: '').toLowerCase();
    final goal = _asString(profile?.weightGoal, fallback: '').toLowerCase();
    final allergies = _asString(profile?.allergies, fallback: '').toLowerCase();
    final source = ingredients.join(' ').toLowerCase();
    final notes = <String>[];

    if (goal.contains('weight') && sugars != null && sugars >= 12) {
      notes.add('Sugar level may slow weight-goal progress');
    }
    if (diet.contains('low sodium') && salt != null && salt >= 1.2) {
      notes.add('Salt appears high for low-sodium preference');
    }
    if (allergies.isNotEmpty) {
      final tokens = allergies.split(RegExp(r',|;')).map((e) => e.trim());
      for (final token in tokens) {
        if (token.isNotEmpty && source.contains(token.toLowerCase())) {
          notes.add('Contains possible allergen match: $token');
          break;
        }
      }
    }

    if (notes.isEmpty) {
      return fallback;
    }
    return notes.join('. ');
  }

  static Future<ScanAnalysisResult> _fallbackWithLabelName(
    Uint8List bytes,
    ProfilesRecord? profile,
  ) async {
    final extracted = await _extractProductFromLabel(bytes);
    return _fallback(
      bytes,
      profile,
      extractedProductName: extracted?['productName'],
      extractedBrandName: extracted?['brandName'],
    );
  }

  static Future<ScanAnalysisResult> _analyzeWithCloudFunction({
    required Uint8List imageBytes,
    ProfilesRecord? profile,
  }) async {
    final imageDataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    final response = await http.post(
      Uri.parse(_analyzeFunctionUrl),
      headers: {
        'Authorization': 'Bearer ${currentJwtToken.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'imageDataUrl': imageDataUrl,
        'profile': {
          'weightGoal': profile?.weightGoal ?? 'General Health',
          'dietType': profile?.dietType ?? 'Regular',
          'allergies': profile?.allergies ?? 'None specified',
          'skinType': profile?.skinType ?? 'Unknown',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Backend analyze request failed: ${response.statusCode} ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final parsed = (payload['analysis'] as Map<String, dynamic>?) ?? payload;
    final score = _asInt(parsed['healthScore'], fallback: 70).clamp(1, 100);

    return ScanAnalysisResult(
      productName: _normalizeProductName(
        _asString(parsed['productName'], fallback: ''),
        _asString(parsed['brandName'], fallback: ''),
      ),
      brandName: _normalizeBrandName(_asString(parsed['brandName'], fallback: '')),
      healthScore: score,
      ingredients: _asStringList(parsed['ingredients'], fallback: const []),
      warnings: _asStringList(parsed['warnings'], fallback: const []),
      benefits: _asStringList(parsed['benefits'], fallback: const []),
      recommendation: _asString(parsed['recommendation'],
          fallback: 'Consume in moderation and check ingredient details.'),
      impactForUser: _asString(parsed['impactForUser'], fallback: ''),
      persistedByBackend: true,
    );
  }

  static ScanAnalysisResult _fallback(
    Uint8List bytes,
    ProfilesRecord? profile, {
    String? extractedProductName,
    String? extractedBrandName,
  }) {
    final sampleCount = math.min(512, bytes.length);
    final step = math.max(1, bytes.length ~/ math.max(1, sampleCount));
    var hash = 2166136261;
    for (var i = 0; i < bytes.length; i += step) {
      hash ^= bytes[i];
      hash = (hash * 16777619) & 0x7fffffff;
    }
    hash ^= bytes.length;
    hash = (hash * 16777619) & 0x7fffffff;
    final score = 35 + (hash % 61);
    final goal = profile?.weightGoal.isNotEmpty == true
        ? profile!.weightGoal
        : 'General Health';
    final skinType = profile?.skinType.isNotEmpty == true
        ? profile!.skinType
        : 'Unknown';

    return ScanAnalysisResult(
      productName:
        (extractedProductName?.trim().isNotEmpty ?? false)
          ? extractedProductName!.trim()
            : '',
      brandName: (extractedBrandName?.trim().isNotEmpty ?? false)
        ? extractedBrandName!.trim()
          : '',
      healthScore: score,
      ingredients: const [],
      warnings: const [],
      benefits: const [],
      recommendation: score >= 75
          ? 'Good fit for occasional use. Keep portions moderate.'
          : 'Use occasionally and pair with whole-food options.',
      impactForUser:
          'Based on your goal "$goal" and skin type "$skinType", prioritize lower sugar and cleaner additives.',
    );
  }

  static Future<Map<String, String>?> _extractProductFromLabel(
    Uint8List imageBytes,
  ) async {
    // OpenAI calls are intentionally server-side only via Cloud Functions.
    return null;
  }

  static Future<Map<String, String>?> extractProductAndBrandFromDataUrl(
    String imageDataUrl,
  ) async {
    if (!imageDataUrl.startsWith('data:image/')) {
      return null;
    }
    final commaIndex = imageDataUrl.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= imageDataUrl.length - 1) {
      return null;
    }
    try {
      final bytes = base64Decode(imageDataUrl.substring(commaIndex + 1));
      return _extractProductFromLabel(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _asString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String _normalizeProductName(String value, String brandName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return brandName.trim();
    }
    final lower = normalized.toLowerCase();
    if (lower == 'scanned product' ||
        lower == 'unknown product' ||
        lower == 'product') {
      return brandName.trim();
    }
    return normalized;
  }

  static String _normalizeBrandName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }
    final lower = normalized.toLowerCase();
    if (lower == 'unknown brand' || lower == 'auto-detected') {
      return '';
    }
    return normalized;
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static List<String> _asStringList(dynamic value,
      {required List<String> fallback}) {
    if (value is List) {
      final list = value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) {
        return list;
      }
    }
    return fallback;
  }
}
