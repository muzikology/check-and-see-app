import 'dart:typed_data';

import 'beauty_models.dart';

/// Abstract provider that returns a [BeautySkinProfile] from raw image bytes.
/// Implementations: [HashHeuristicSkinAnalysisProvider] (all platforms),
/// [MlKitSkinAnalysisProvider] (Android / iOS — see mlkit_skin_analysis_provider.dart).
abstract class SkinAnalysisProvider {
  Future<BeautySkinProfile> analyze(Uint8List imageBytes);
}

/// Skin profile returned by any [SkinAnalysisProvider].
class BeautySkinProfile {
  const BeautySkinProfile({
    required this.skinTone,
    required this.undertone,
    required this.facialFeatures,
  });

  final BeautySkinTone skinTone;
  final BeautyUndertone undertone;

  /// Keys: faceShape, eyeStyle, lipShape.  Values: human-readable labels.
  final Map<String, String> facialFeatures;
}

/// Deterministic heuristic provider — works on every platform including web.
/// Derives a reproducible seed from the first 96 bytes of the image data so
/// results are consistent for the same image without requiring any native SDK.
class HashHeuristicSkinAnalysisProvider implements SkinAnalysisProvider {
  const HashHeuristicSkinAnalysisProvider();

  @override
  Future<BeautySkinProfile> analyze(Uint8List imageBytes) async {
    final seed = imageBytes
        .take(96)
        .fold<int>(17, (acc, b) => (acc * 31 + b) & 0x7fffffff);

    final tone = BeautySkinTone.values[seed % BeautySkinTone.values.length];
    final undertone =
        BeautyUndertone.values[(seed ~/ 7) % BeautyUndertone.values.length];

    return BeautySkinProfile(
      skinTone: tone,
      undertone: undertone,
      facialFeatures: {
        'faceShape': ['Oval', 'Round', 'Heart', 'Square'][(seed ~/ 11) % 4],
        'eyeStyle': ['Almond', 'Round', 'Hooded', 'Monolid'][(seed ~/ 13) % 4],
        'lipShape': [
          'Full',
          'Balanced',
          'Top-heavy',
          'Bottom-heavy',
        ][(seed ~/ 17) % 4],
      },
    );
  }
}
