// Dispatches to the ML Kit implementation on platforms where dart:io is
// available (Android, iOS), and falls back to the heuristic stub on web.
export 'mlkit_skin_analysis_provider_stub.dart'
    if (dart.library.io) 'mlkit_skin_analysis_provider.dart';
