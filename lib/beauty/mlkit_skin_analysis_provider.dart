// Mobile (Android / iOS) skin-analysis provider backed by ML Kit Face Detection.
// This file is only compiled on platforms where dart:io is available.
// On web the stub (mlkit_skin_analysis_provider_stub.dart) is used instead.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import 'beauty_models.dart';
import 'skin_analysis_base.dart';

export 'skin_analysis_base.dart';

/// Production provider that uses ML Kit face detection to determine:
/// * Skin tone — via ITA (Individual Typology Angle) from sampled forehead pixels
/// * Undertone — from RGB channel balance of sampled skin region
/// * Face shape — from face-oval contour dimensions
/// * Eye shape — from eye-contour aspect ratio
/// * Lip shape — from lip-contour height balance
///
/// Falls back to [HashHeuristicSkinAnalysisProvider] when no face is detected
/// or when running on a platform where ML Kit is unavailable at runtime.
class MlKitSkinAnalysisProvider implements SkinAnalysisProvider {
  static final _fallback = const HashHeuristicSkinAnalysisProvider();

  @override
  Future<BeautySkinProfile> analyze(Uint8List imageBytes) async {
    try {
      return await _analyzeWithMlKit(imageBytes);
    } catch (_) {
      return _fallback.analyze(imageBytes);
    }
  }

  Future<BeautySkinProfile> _analyzeWithMlKit(Uint8List imageBytes) async {
    final detector = FaceDetector(
      options: const FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    List<Face> faces;
    try {
      // ML Kit requires a file path or metadata-tagged bytes; write to tmp file.
      final dir = await getTemporaryDirectory();
      final tmp = File(
        '${dir.path}/beauty_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tmp.writeAsBytes(imageBytes);
      try {
        final inputImage = InputImage.fromFilePath(tmp.path);
        faces = await detector.processImage(inputImage);
      } finally {
        await tmp.delete().catchError((_) {});
      }
    } finally {
      await detector.close();
    }

    if (faces.isEmpty) {
      return _fallback.analyze(imageBytes);
    }

    final face = faces.first;

    // Decode image for forehead/cheek pixel sampling.
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageBytes, completer.complete);
    final image = await completer.future;

    final skinColor = await _sampleSkinColor(image, face.boundingBox);
    final skinTone = _classifySkinTone(skinColor);
    final undertone = _classifyUndertone(skinColor);

    return BeautySkinProfile(
      skinTone: skinTone,
      undertone: undertone,
      facialFeatures: {
        'faceShape': _classifyFaceShape(face),
        'eyeStyle': _classifyEyeShape(face),
        'lipShape': _classifyLipShape(face),
      },
    );
  }

  // ── Pixel sampling ────────────────────────────────────────────────────────

  Future<({int r, int g, int b})> _sampleSkinColor(
    ui.Image image,
    Rect faceBounds,
  ) async {
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return (r: 200, g: 170, b: 140);

    // Forehead region: centre 60% width, top 5–25% of face height.
    final x0 = (faceBounds.left + faceBounds.width * 0.2)
        .clamp(0.0, (image.width - 1).toDouble())
        .toInt();
    final y0 = (faceBounds.top + faceBounds.height * 0.05)
        .clamp(0.0, (image.height - 1).toDouble())
        .toInt();
    final x1 = (faceBounds.left + faceBounds.width * 0.8)
        .clamp(0.0, (image.width - 1).toDouble())
        .toInt();
    final y1 = (faceBounds.top + faceBounds.height * 0.25)
        .clamp(0.0, (image.height - 1).toDouble())
        .toInt();

    int sumR = 0, sumG = 0, sumB = 0, count = 0;
    const step = 4; // sample every 4th pixel to keep it fast
    for (var y = y0; y <= y1; y += step) {
      for (var x = x0; x <= x1; x += step) {
        final offset = (y * image.width + x) * 4;
        if (offset + 2 < byteData.lengthInBytes) {
          sumR += byteData.getUint8(offset);
          sumG += byteData.getUint8(offset + 1);
          sumB += byteData.getUint8(offset + 2);
          count++;
        }
      }
    }

    if (count == 0) return (r: 200, g: 170, b: 140);
    return (r: sumR ~/ count, g: sumG ~/ count, b: sumB ~/ count);
  }

  // ── Skin tone (ITA angle) ─────────────────────────────────────────────────

  BeautySkinTone _classifySkinTone(({int r, int g, int b}) rgb) {
    // sRGB → linear light
    final rLin = _srgbToLinear(rgb.r);
    final gLin = _srgbToLinear(rgb.g);
    final bLin = _srgbToLinear(rgb.b);

    // CIE XYZ (D65 sRGB primaries, ITU-R BT.709)
    final Y = 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
    final Z = 0.0193 * rLin + 0.1192 * gLin + 0.9505 * bLin;

    // CIE L*
    final lStar =
        Y <= 0.008856 ? 903.3 * Y : 116.0 * math.pow(Y, 1.0 / 3.0) - 16.0;

    // CIE b* (yellow-blue axis; positive = warm/yellow)
    final bStar = 200.0 * (_labF(Y) - _labF(Z / 1.0890));

    // ITA (Individual Typology Angle) — Chardon et al.
    final ita = math.atan2(lStar - 50.0, bStar) * (180.0 / math.pi);

    if (ita > 55) return BeautySkinTone.fair;
    if (ita > 41) return BeautySkinTone.light;
    if (ita > 28) return BeautySkinTone.medium;
    if (ita > 10) return BeautySkinTone.tan;
    return BeautySkinTone.deep;
  }

  static double _srgbToLinear(int channel) {
    final c = channel / 255.0;
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _labF(double t) {
    return t > 0.008856
        ? math.pow(t, 1.0 / 3.0).toDouble()
        : (903.3 * t + 16.0) / 116.0;
  }

  // ── Undertone (warm / neutral / cool) ────────────────────────────────────

  BeautyUndertone _classifyUndertone(({int r, int g, int b}) rgb) {
    // Warm skin: red >> blue; cool skin: blue ≈ red or blue > red.
    final warmIndex = rgb.r - rgb.b;
    if (warmIndex > 20) return BeautyUndertone.warm;
    if (warmIndex < -10) return BeautyUndertone.cool;
    return BeautyUndertone.neutral;
  }

  // ── Face shape (from oval contour) ───────────────────────────────────────

  String _classifyFaceShape(Face face) {
    final contour = face.contours[FaceContourType.face];
    if (contour == null || contour.points.isEmpty) return 'Oval';

    final pts = contour.points;
    final xs = pts.map((p) => p.x).toList()..sort();
    final ys = pts.map((p) => p.y).toList()..sort();

    final width = (xs.last - xs.first).toDouble();
    final height = (ys.last - ys.first).toDouble();
    if (height == 0) return 'Oval';
    final ratio = width / height;

    // Jaw = bottom 25 % of face height
    final jawYThreshold = ys.first + height * 0.75;
    final jawXs = pts
        .where((p) => p.y > jawYThreshold)
        .map((p) => p.x)
        .toList()
      ..sort();
    final jawWidth =
        jawXs.isEmpty ? width * 0.65 : (jawXs.last - jawXs.first).toDouble();

    // Forehead = top 25 % of face height
    final foreheadYThreshold = ys.first + height * 0.25;
    final foreheadXs = pts
        .where((p) => p.y < foreheadYThreshold)
        .map((p) => p.x)
        .toList()
      ..sort();
    final foreheadWidth = foreheadXs.isEmpty
        ? width * 0.75
        : (foreheadXs.last - foreheadXs.first).toDouble();

    final jawForeheadRatio =
        foreheadWidth == 0 ? 1.0 : jawWidth / foreheadWidth;

    if (ratio >= 0.90 && jawForeheadRatio > 0.85) return 'Square';
    if (ratio >= 0.82) return 'Round';
    if (jawForeheadRatio < 0.65) return 'Heart';
    return 'Oval';
  }

  // ── Eye shape (from left-eye contour aspect ratio) ────────────────────────

  String _classifyEyeShape(Face face) {
    final contour = face.contours[FaceContourType.leftEye];
    if (contour == null || contour.points.isEmpty) return 'Almond';

    final pts = contour.points;
    final xs = pts.map((p) => p.x).toList()..sort();
    final ys = pts.map((p) => p.y).toList()..sort();

    final eyeWidth = (xs.last - xs.first).toDouble();
    final eyeHeight = (ys.last - ys.first).toDouble();
    if (eyeWidth == 0) return 'Almond';

    final ear = eyeHeight / eyeWidth; // eye aspect ratio
    if (ear < 0.22) return 'Monolid';
    if (ear < 0.32) return 'Hooded';
    if (ear < 0.45) return 'Almond';
    return 'Round';
  }

  // ── Lip shape (from lip-contour height balance) ───────────────────────────

  String _classifyLipShape(Face face) {
    final upperTop = face.contours[FaceContourType.upperLipTop];
    final lowerBottom = face.contours[FaceContourType.lowerLipBottom];
    if (upperTop == null || lowerBottom == null) return 'Balanced';

    final upperPts = upperTop.points;
    final lowerPts = lowerBottom.points;
    if (upperPts.isEmpty || lowerPts.isEmpty) return 'Balanced';

    final upperYs = upperPts.map((p) => p.y).toList()..sort();
    final lowerYs = lowerPts.map((p) => p.y).toList()..sort();

    final totalLipHeight = (lowerYs.last - upperYs.first).toDouble();
    if (totalLipHeight < 5) return 'Balanced';

    final upperLipHeight = (upperYs.last - upperYs.first).toDouble();
    final lowerLipHeight = (lowerYs.last - lowerYs.first).toDouble();
    if (lowerLipHeight == 0) return 'Balanced';

    if (totalLipHeight > 40) return 'Full';
    final ratio = upperLipHeight / lowerLipHeight;
    if (ratio < 0.6) return 'Bottom-heavy';
    if (ratio > 1.4) return 'Top-heavy';
    return 'Balanced';
  }
}

SkinAnalysisProvider createPlatformSkinProvider() =>
    MlKitSkinAnalysisProvider();
