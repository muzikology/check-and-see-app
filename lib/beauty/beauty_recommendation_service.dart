import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'beauty_models.dart';
import 'platform_skin_provider.dart';
import 'skin_analysis_base.dart';

class BeautyRecommendationService {
  BeautyRecommendationService({SkinAnalysisProvider? skinProvider})
      : _skinProvider = skinProvider ?? createPlatformSkinProvider();

  final SkinAnalysisProvider _skinProvider;

  Future<BeautyAnalysisResult> buildBeautyJourney(Uint8List imageBytes) async {
    final profile = await _skinProvider.analyze(imageBytes);
    final fromDb = await _fetchFromFirestore(profile);

    final recommendations = fromDb.isNotEmpty
        ? fromDb
        : _fallbackRecommendations(profile.skinTone, profile.undertone);

    final tutorial = _buildTutorial(recommendations);

    return BeautyAnalysisResult(
      skinTone: profile.skinTone,
      undertone: profile.undertone,
      facialFeatures: profile.facialFeatures,
      recommendations: recommendations,
      tutorialSteps: tutorial,
    );
  }

  Future<List<BeautyProductRecommendation>> _fetchFromFirestore(
    BeautySkinProfile profile,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('beauty_products')
          .limit(40)
          .get();

      if (snapshot.docs.isEmpty) {
        return const <BeautyProductRecommendation>[];
      }

      final products = snapshot.docs
          .map((doc) => _mapDocToRecommendation(doc.id, doc.data()))
          .whereType<BeautyProductRecommendation>()
          .where((r) {
            final toneMatch = r.skinToneTags.isEmpty || r.skinToneTags.contains(profile.skinTone);
            final undertoneMatch =
                r.undertoneTags.isEmpty || r.undertoneTags.contains(profile.undertone);
            return toneMatch && undertoneMatch;
          })
          .toList();

      products.sort((a, b) => a.category.index.compareTo(b.category.index));
      return products.take(8).toList();
    } catch (_) {
      return const <BeautyProductRecommendation>[];
    }
  }

  BeautyProductRecommendation? _mapDocToRecommendation(String id, Map<String, dynamic> data) {
    final categoryRaw = (data['category'] ?? '').toString().trim().toLowerCase();
    final category = switch (categoryRaw) {
      'makeup' => BeautyProductCategory.makeup,
      'lashes' => BeautyProductCategory.lashes,
      'nails' => BeautyProductCategory.nails,
      'skincare' => BeautyProductCategory.skincare,
      _ => null,
    };

    if (category == null) {
      return null;
    }

    return BeautyProductRecommendation(
      id: id,
      name: (data['name'] ?? 'Unnamed beauty product').toString(),
      brand: (data['brand'] ?? 'Unknown brand').toString(),
      category: category,
      finish: (data['finish'] ?? 'natural').toString(),
      matchReason: (data['match_reason'] ?? 'Matches your profile').toString(),
      skinToneTags: _parseSkinToneTags(data['skin_tone_tags']),
      undertoneTags: _parseUndertoneTags(data['undertone_tags']),
      overlayKey: data['overlay_key']?.toString(),
      thumbnailUrl: data['thumbnail_url']?.toString(),
    );
  }

  List<BeautySkinTone> _parseSkinToneTags(dynamic raw) {
    if (raw is! Iterable) return const <BeautySkinTone>[];
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .map((v) => switch (v) {
              'fair' => BeautySkinTone.fair,
              'light' => BeautySkinTone.light,
              'medium' => BeautySkinTone.medium,
              'tan' => BeautySkinTone.tan,
              'deep' => BeautySkinTone.deep,
              _ => null,
            })
        .whereType<BeautySkinTone>()
        .toList();
  }

  List<BeautyUndertone> _parseUndertoneTags(dynamic raw) {
    if (raw is! Iterable) return const <BeautyUndertone>[];
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .map((v) => switch (v) {
              'cool' => BeautyUndertone.cool,
              'neutral' => BeautyUndertone.neutral,
              'warm' => BeautyUndertone.warm,
              _ => null,
            })
        .whereType<BeautyUndertone>()
        .toList();
  }

  List<BeautyProductRecommendation> _fallbackRecommendations(
    BeautySkinTone tone,
    BeautyUndertone undertone,
  ) {
    final undertoneHint = undertone.label.toLowerCase();
    return <BeautyProductRecommendation>[
      BeautyProductRecommendation(
        id: 'mk_01',
        name: 'Second-skin Foundation',
        brand: 'Check&See Studio',
        category: BeautyProductCategory.makeup,
        finish: 'Natural',
        matchReason: 'Balanced coverage for ${tone.label.toLowerCase()} skin with $undertoneHint undertone.',
        skinToneTags: <BeautySkinTone>[tone],
        undertoneTags: <BeautyUndertone>[undertone],
        overlayKey: 'foundation_soft',
      ),
      BeautyProductRecommendation(
        id: 'ls_01',
        name: 'Lift Curl Lashes',
        brand: 'Check&See Studio',
        category: BeautyProductCategory.lashes,
        finish: 'Wispy',
        matchReason: 'Enhances your detected eye shape while keeping a natural lift.',
        overlayKey: 'lashes_wispy',
      ),
      BeautyProductRecommendation(
        id: 'nl_01',
        name: 'Gloss Gel Nails',
        brand: 'Check&See Studio',
        category: BeautyProductCategory.nails,
        finish: 'Glossy',
        matchReason: 'Warm neutral shades complement your tone and daily look.',
        overlayKey: 'nails_gloss_neutral',
      ),
      BeautyProductRecommendation(
        id: 'sk_01',
        name: 'Barrier Repair Serum',
        brand: 'Check&See Studio',
        category: BeautyProductCategory.skincare,
        finish: 'Hydrating',
        matchReason: 'Preps skin for makeup and supports smoother finish.',
      ),
    ];
  }

  List<BeautyTutorialStep> _buildTutorial(List<BeautyProductRecommendation> recs) {
    final hasLashes = recs.any((r) => r.category == BeautyProductCategory.lashes);
    final hasNails = recs.any((r) => r.category == BeautyProductCategory.nails);

    return <BeautyTutorialStep>[
      const BeautyTutorialStep(
        title: 'Prep and hydrate',
        description: 'Cleanse, apply hydrating serum, and wait 60 seconds before makeup.',
        category: BeautyProductCategory.skincare,
      ),
      const BeautyTutorialStep(
        title: 'Build your base',
        description: 'Apply thin foundation layers from center of face outward.',
        category: BeautyProductCategory.makeup,
      ),
      if (hasLashes)
        const BeautyTutorialStep(
          title: 'Apply lashes',
          description: 'Measure lash strip, trim edges, add glue, then set from center outward.',
          category: BeautyProductCategory.lashes,
        ),
      if (hasNails)
        const BeautyTutorialStep(
          title: 'Finish nails',
          description: 'Apply two thin coats, cap the tip, and seal with top coat.',
          category: BeautyProductCategory.nails,
        ),
      const BeautyTutorialStep(
        title: 'Set and review',
        description: 'Set with mist or powder and use AR preview for final adjustments.',
        category: BeautyProductCategory.makeup,
      ),
    ];
  }
}
