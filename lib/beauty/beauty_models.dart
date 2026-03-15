enum BeautySkinTone {
  fair,
  light,
  medium,
  tan,
  deep,
}

enum BeautyUndertone {
  cool,
  neutral,
  warm,
}

enum BeautyProductCategory {
  makeup,
  lashes,
  nails,
  skincare,
}

class BeautyProductRecommendation {
  const BeautyProductRecommendation({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.finish,
    required this.matchReason,
    this.skinToneTags = const <BeautySkinTone>[],
    this.undertoneTags = const <BeautyUndertone>[],
    this.overlayKey,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String brand;
  final BeautyProductCategory category;
  final String finish;
  final String matchReason;
  final List<BeautySkinTone> skinToneTags;
  final List<BeautyUndertone> undertoneTags;
  final String? overlayKey;
  final String? thumbnailUrl;
}

class BeautyTutorialStep {
  const BeautyTutorialStep({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final BeautyProductCategory category;
}

class BeautyAnalysisResult {
  const BeautyAnalysisResult({
    required this.skinTone,
    required this.undertone,
    required this.facialFeatures,
    required this.recommendations,
    required this.tutorialSteps,
  });

  final BeautySkinTone skinTone;
  final BeautyUndertone undertone;
  final Map<String, String> facialFeatures;
  final List<BeautyProductRecommendation> recommendations;
  final List<BeautyTutorialStep> tutorialSteps;
}

extension BeautySkinToneLabel on BeautySkinTone {
  String get label {
    switch (this) {
      case BeautySkinTone.fair:
        return 'Fair';
      case BeautySkinTone.light:
        return 'Light';
      case BeautySkinTone.medium:
        return 'Medium';
      case BeautySkinTone.tan:
        return 'Tan';
      case BeautySkinTone.deep:
        return 'Deep';
    }
  }
}

extension BeautyUndertoneLabel on BeautyUndertone {
  String get label {
    switch (this) {
      case BeautyUndertone.cool:
        return 'Cool';
      case BeautyUndertone.neutral:
        return 'Neutral';
      case BeautyUndertone.warm:
        return 'Warm';
    }
  }
}

extension BeautyCategoryLabel on BeautyProductCategory {
  String get label {
    switch (this) {
      case BeautyProductCategory.makeup:
        return 'Makeup';
      case BeautyProductCategory.lashes:
        return 'Lashes';
      case BeautyProductCategory.nails:
        return 'Nails';
      case BeautyProductCategory.skincare:
        return 'Skincare';
    }
  }
}
