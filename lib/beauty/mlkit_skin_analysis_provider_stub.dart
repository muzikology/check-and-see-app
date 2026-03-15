// Web / desktop stub — returns the hash-heuristic provider.
// On Android and iOS the real implementation (mlkit_skin_analysis_provider.dart)
// is selected instead via the conditional export in platform_skin_provider.dart.
import 'skin_analysis_base.dart';

export 'skin_analysis_base.dart';

SkinAnalysisProvider createPlatformSkinProvider() =>
    const HashHeuristicSkinAnalysisProvider();
