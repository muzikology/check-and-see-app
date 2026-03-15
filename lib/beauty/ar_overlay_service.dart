import 'beauty_models.dart';
import 'banuba_config.dart';

class ArTryOnSession {
  const ArTryOnSession({
    required this.provider,
    required this.launchToken,
    required this.overlayKeys,
    this.arCloudToken,
  });

  final String provider;
  final String launchToken;
  final List<String> overlayKeys;
  final String? arCloudToken;
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

    if (!BanubaConfig.hasClientToken) {
      throw StateError('Banuba client token is missing.');
    }

    return ArTryOnSession(
      provider: 'banuba',
      launchToken: BanubaConfig.clientToken,
      overlayKeys: overlays,
      arCloudToken: BanubaConfig.arCloudToken,
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
