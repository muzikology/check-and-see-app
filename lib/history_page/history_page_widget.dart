import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/beauty/beauty_recommendation_service.dart';
import '/scan_session.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'history_page_model.dart';
export 'history_page_model.dart';

/// Create a modern mobile app screen for viewing scan history.
///
/// App purpose:
/// Display past product scans with dates and health scores.
///
/// Design style:
/// Modern
/// Minimal
/// Premium
/// Inspired by Apple Health
///
/// Layout:
///
/// Top App Bar
/// Title: Scan History
///
/// Main section:
/// List of past scans
/// Each item shows:
/// - Product name
/// - Scan date
/// - Health score badge
/// - Thumbnail image
///
/// Empty state:
/// Icon and text: "No scans yet"
/// Subtitle: "Start scanning products to see your history"
///
/// Colors:
/// Primary: Deep green #1B5E20
/// Background: #F5F7F5
///
/// Use rounded cards and soft shadows.
class HistoryPageWidget extends StatefulWidget {
  const HistoryPageWidget({super.key});

  static String routeName = 'HistoryPage';
  static String routePath = 'historyPage';

  @override
  State<HistoryPageWidget> createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<HistoryPageWidget> {
  late HistoryPageModel _model;
  final BeautyRecommendationService _beautyRecommendationService =
      BeautyRecommendationService();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> _parseIngredients(String value) => value
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool _isPlaceholderName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'scanned product' ||
        normalized == 'unknown product' ||
        normalized == 'product';
  }

  String _productLabel(ScansRecord scan) {
    final product = scan.productName.trim();
    final brand = scan.brandName.trim();
    if (!_isPlaceholderName(product)) {
      return product;
    }
    if (brand.isNotEmpty && !_isPlaceholderName(brand)) {
      return brand;
    }
    return 'Latest scanned item';
  }

  String _brandLabel(ScansRecord scan) {
    final brand = scan.brandName.trim();
    if (brand.isEmpty || _isPlaceholderName(brand) || brand.toLowerCase() == 'auto-detected') {
      return '';
    }
    return brand;
  }

  String _defaultRecommendationForScore(int score) {
    if (score >= 80) {
      return 'Great choice. Ingredients look generally safe.';
    }
    if (score >= 60) {
      return 'Moderate profile. Consider portion size and frequency.';
    }
    return 'Lower score detected. Review additives and sugar levels.';
  }

  Future<Uint8List?> _loadScanImageBytes(ScansRecord scan) async {
    final raw = scan.productImage.trim();
    if (raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('data:image/')) {
      final comma = raw.indexOf(',');
      if (comma > 0 && comma < raw.length - 1) {
        try {
          return base64Decode(raw.substring(comma + 1));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    try {
      final uri = Uri.tryParse(raw);
      if (uri == null) return null;
      final data = await NetworkAssetBundle(uri).load(raw);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteScanImage(ScansRecord scan) async {
    if (scan.productImage.trim().isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete image?'),
        content: const Text('The scan entry will stay, but its image will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await scan.reference.update({'product_image': ''});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed from history item.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openScanInAnalysis(ScansRecord scan) async {
    final score = (int.tryParse(scan.healthScore.trim()) ?? 70).clamp(1, 100);
    final analysis = ScanAnalysisResult(
      productType: ScanProductTypeX.fromStorageValue(scan.productType),
      productName: _productLabel(scan),
      brandName: _brandLabel(scan),
      healthScore: score,
      ingredients: _parseIngredients(scan.ingredients),
        warnings: scan.warnings.take(3).toList(),
        benefits: scan.benefits.take(3).toList(),
      recommendation: scan.recommendation.trim().isNotEmpty
          ? scan.recommendation.trim()
          : _defaultRecommendationForScore(score),
      impactForUser: scan.impactForUser,
    );

    final imageBytes = await _loadScanImageBytes(scan);

    ScanSession.updateAnalysisOnly(
      analysis,
      bytes: imageBytes,
      at: scan.scanDate ?? scan.createdTime,
    );

    if (analysis.productType == ScanProductType.beauty && imageBytes != null) {
      try {
        final beautyResult =
            await _beautyRecommendationService.buildBeautyJourney(imageBytes);
        ScanSession.setBeautyAnalysis(beautyResult);
      } catch (_) {
        ScanSession.setBeautyAnalysis(null);
      }
    } else {
      ScanSession.setBeautyAnalysis(null);
    }

    if (!mounted) {
      return;
    }
    context.pushNamed(ProductAnalysisWidget.routeName);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFF5F0E6),
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F0E6),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF3B2F2F),
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Scan History',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Times New Roman MT',
                  color: Color(0xFF3B2F2F),
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<ScansRecord>>(
            stream: queryScansRecord(
              queryBuilder: (q) => q.where('user_id', isEqualTo: currentUserUid),
              limit: 200,
            ),
            builder: (context, snapshot) {
              final scans = [...(snapshot.data ?? const <ScansRecord>[])]
                ..sort((a, b) =>
                    (b.scanDate ?? b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0))
                        .compareTo(
                            a.scanDate ?? a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0)));
              final currentAnalysis = ScanSession.latestAnalysis;
              final latestPersisted = scans.isNotEmpty ? scans.first : null;
              var includeCurrentAnalysis = currentAnalysis != null;
              if (includeCurrentAnalysis && latestPersisted != null) {
                final sameName = _productLabel(latestPersisted).toLowerCase() ==
                    currentAnalysis!.productName.trim().toLowerCase();
                final persistedAt = latestPersisted.scanDate ?? latestPersisted.createdTime;
                final currentAt = ScanSession.scannedAt;
                final nearSameTime = persistedAt != null &&
                    currentAt != null &&
                    (persistedAt.difference(currentAt).inSeconds).abs() <= 20;
                if (sameName && nearSameTime) {
                  includeCurrentAnalysis = false;
                }
              }
              final hasAnyHistory = scans.isNotEmpty || includeCurrentAnalysis;

              Widget buildImage(ScansRecord scan) {
                if (scan.productImage.startsWith('data:image/')) {
                  final comma = scan.productImage.indexOf(',');
                  if (comma > 0 && comma < scan.productImage.length - 1) {
                    try {
                      final bytes = base64Decode(scan.productImage.substring(comma + 1));
                      return Image.memory(bytes,
                          width: 52.0, height: 52.0, fit: BoxFit.cover);
                    } catch (_) {}
                  }
                }

                if (scan.productImage.isNotEmpty) {
                  return Image.network(
                    scan.productImage,
                    width: 52.0,
                    height: 52.0,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image_outlined, color: Color(0xFF8B6A52)),
                  );
                }

                return Icon(Icons.inventory_2_rounded, color: Color(0xFF8B6A52));
              }

              return Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(0.0, 2.0),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                    child: !hasAnyHistory
                        ? Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: Color(0xFF5C4033),
                                size: 80.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Text(
                                  'No scans yet',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Times New Roman MT',
                                        color: Color(0xFF5C4033),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 8.0, 0.0, 0.0),
                                child: Text(
                                  'Start scanning products to see your history',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF8B6A52),
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    context.pushNamed(ProductScanningWidget.routeName);
                                  },
                                  text: 'Scan a Product',
                                  options: FFButtonOptions(
                                    width: 200.0,
                                    height: 50.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: Color(0xFF5C4033),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Times New Roman MT',
                                          color: Color(0xFFEDE3D1),
                                          letterSpacing: 0.0,
                                        ),
                                    elevation: 3.0,
                                    borderSide: BorderSide(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                          itemCount: scans.length + (includeCurrentAnalysis ? 1 : 0),
                            separatorBuilder: (_, __) => Divider(
                              height: 1.0,
                              color: Color(0xFFE5CDAF),
                            ),
                            itemBuilder: (context, index) {
                              if (includeCurrentAnalysis && index == 0) {
                                final analysis = currentAnalysis;
                                final score = analysis.healthScore;
                                final scoreBg = score >= 80
                                    ? Color(0xFFF5EAD7)
                                    : score >= 60
                                        ? Color(0xFFF7F0EB)
                                        : Color(0xFFFCECEF);
                                final scoreColor = score >= 80
                                    ? Color(0xFF5C4033)
                                    : score >= 60
                                        ? Color(0xFFB78466)
                                        : Color(0xFFC24664);
                                final firstIngredient =
                                  analysis.ingredients.isNotEmpty
                                    ? analysis.ingredients.first
                                        : 'No ingredients found';
                                final productSubtitle =
                                  '${analysis.brandName} · Current scan';

                                return Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 8.0, 0.0, 8.0),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      context.pushNamed(ProductAnalysisWidget.routeName);
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52.0,
                                          height: 52.0,
                                          decoration: BoxDecoration(
                                            color: scoreBg,
                                            borderRadius: BorderRadius.circular(14.0),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14.0),
                                            child: ScanSession.imageBytes != null
                                                ? Image.memory(
                                                    ScanSession.imageBytes!,
                                                    width: 52.0,
                                                    height: 52.0,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Icon(
                                                    Icons.inventory_2_rounded,
                                                    color: Color(0xFF8B6A52),
                                                  ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                12.0, 0.0, 12.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  analysis.productName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: FlutterFlowTheme.of(context)
                                                      .titleSmall,
                                                ),
                                                Text(
                                                  productSubtitle,
                                                  style: FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color: Color(0xFF8B6A52),
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                                Text(
                                                  firstIngredient,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color: scoreColor,
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            color: scoreBg,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Text(
                                            score.toString(),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: scoreColor,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                                final scan =
                                  scans[index - (includeCurrentAnalysis ? 1 : 0)];
                              final score = int.tryParse(scan.healthScore.trim()) ?? 0;
                              final scoreBg = score >= 80
                                  ? Color(0xFFF5EAD7)
                                  : score >= 60
                                      ? Color(0xFFF7F0EB)
                                      : Color(0xFFFCECEF);
                              final scoreColor = score >= 80
                                  ? Color(0xFF5C4033)
                                  : score >= 60
                                      ? Color(0xFFB78466)
                                      : Color(0xFFC24664);
                              final firstIngredient = scan.ingredients
                                  .split(',')
                                  .map((e) => e.trim())
                                  .firstWhere((e) => e.isNotEmpty,
                                      orElse: () => 'No ingredients found');
                              final when = scan.scanDate ??
                                  scan.createdTime ??
                                  getCurrentTimestamp;
                                final productTitle = _productLabel(scan);
                                final productSubtitle = _brandLabel(scan).isNotEmpty
                                  ? "${_brandLabel(scan)} · ${dateTimeFormat('yMMMd', when)}"
                                  : dateTimeFormat('yMMMd', when);

                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 8.0, 0.0, 8.0),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async => _openScanInAnalysis(scan),
                                  child: Row(
                                  children: [
                                    Container(
                                      width: 52.0,
                                      height: 52.0,
                                      decoration: BoxDecoration(
                                        color: scoreBg,
                                        borderRadius: BorderRadius.circular(14.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14.0),
                                        child: buildImage(scan),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 0.0, 12.0, 0.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(context)
                                                  .titleSmall,
                                            ),
                                            Text(
                                              productSubtitle,
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: 'Poppins',
                                                    color: Color(0xFF8B6A52),
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                            Text(
                                              firstIngredient,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: 'Poppins',
                                                    color: scoreColor,
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (scan.productImage.trim().isNotEmpty)
                                      IconButton(
                                        onPressed: () async {
                                          await _deleteScanImage(scan);
                                        },
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFF8B6A52),
                                          size: 20.0,
                                        ),
                                        tooltip: 'Delete image',
                                      ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 6.0),
                                      decoration: BoxDecoration(
                                        color: scoreBg,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        score.toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Poppins',
                                              color: scoreColor,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
