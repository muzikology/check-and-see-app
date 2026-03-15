import 'beauty_models.dart';

class ArTryOnSession {
  const ArTryOnSession({
    required this.provider,
    required this.launchToken,
    required this.overlayKeys,
  });

  final String provider;
  final String launchToken;
  final List<String> overlayKeys;
}

abstract class ArOverlayProvider {
  Future<ArTryOnSession> createSession({
    required List<BeautyProductRecommendation> recommendations,
  });
}

class BanubaOverlayProvider implements ArOverlayProvider {
  const BanubaOverlayProvider();

  @override
  Future<ArTryOnSession> createSession({
    required List<BeautyProductRecommendation> recommendations,
  }) async {
    final overlays = recommendations
        .map((r) => r.overlayKey)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .toList();

    // Replace this token with your backend-generated Banuba session token.
    return ArTryOnSession(
      provider: 'banuba',
      launchToken: 'BANUBA_SESSION_TOKEN_PLACEHOLDER',
      overlayKeys: overlays,
    );
  }
}

class ModiFaceOverlayProvider implements ArOverlayProvider {
  const ModiFaceOverlayProvider();

  @override
  Future<ArTryOnSession> createSession({
    required List<BeautyProductRecommendation> recommendations,
  }) async {
    final overlays = recommendations
        .map((r) => r.overlayKey)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .toList();

    // Replace this token with your backend-generated ModiFace session token.
    return ArTryOnSession(
      provider: 'modiface',
      launchToken: 'MODIFACE_SESSION_TOKEN_PLACEHOLDER',
      overlayKeys: overlays,
    );
  }
}
