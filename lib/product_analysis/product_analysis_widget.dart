import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/beauty/ar_overlay_service.dart';
import '/beauty/beauty_models.dart';
import '/beauty/beauty_try_on_widget.dart';
import '/scan_session.dart';
import 'dart:convert';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'product_analysis_model.dart';
export 'product_analysis_model.dart';

/// Create a product analysis ResultsPage results screen for an AI health
/// scanning app.
///
/// Purpose:
/// Show the analysis results after a user scans a product.
///
/// Design style:
/// Modern mobile health dashboard.
///
/// Layout:
///
/// Top section:
/// Product image
/// Product name
/// Brand name
///
/// Main section:
/// Health score card
///
/// Large circular score indicator
/// Score from 1 to 100
///
/// Score colors:
/// Green = healthy
/// Yellow = moderate
/// Red = unhealthy
///
/// Below score:
/// Three sections
///
/// Warnings
/// Display warning icons with text
///
/// Benefits
/// Display checkmark icons with benefits
///
/// Ingredients
/// List key ingredients detected
///
/// Bottom section:
/// Recommendation card
///
/// Example:
/// "Moderate sugar content. Safe in small portions."
///
/// Buttons at bottom:
///
/// Save Scan
/// Scan Another Product
///
/// Design notes:
/// Rounded cards
/// Large typography
/// Soft shadows
/// Minimal design
class ProductAnalysisWidget extends StatefulWidget {
  const ProductAnalysisWidget({super.key});

  static String routeName = 'ProductAnalysis';
  static String routePath = 'productAnalysis';

  @override
  State<ProductAnalysisWidget> createState() => _ProductAnalysisWidgetState();
}

class _ProductAnalysisWidgetState extends State<ProductAnalysisWidget> {
  late ProductAnalysisModel _model;
  final ArOverlayProvider _arOverlayProvider = const BanubaOverlayProvider();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  int get _score => ScanSession.healthScore;
  double get _scorePercent => (_score / 100).clamp(0.0, 1.0);
  bool get _hasLiveScan => ScanSession.hasScan;

  Color get _scoreColor {
    if (_score >= 80) return Color(0xFF16A34A);
    if (_score >= 60) return Color(0xFFE8A838);
    return Color(0xFFDC2626);
  }

  String get _scoreLabel {
    if (_score >= 80) return 'Healthy - Great choice';
    if (_score >= 60) return 'Moderate - Consume in moderation';
    return 'Low - Use sparingly';
  }

  List<String> get _warnings => ScanSession.warnings.take(3).toList();
  List<String> get _benefits => ScanSession.benefits.take(3).toList();
  List<String> get _ingredients => ScanSession.ingredients.take(6).toList();
  BeautyAnalysisResult? get _beauty => ScanSession.beautyAnalysis;
  bool get _showBeautyInsights =>
      ScanSession.productType == ScanProductType.beauty && _beauty != null;

  String _shareSummary() {
    final brand = ScanSession.brandName.trim();
    final warningSummary = _warnings.isNotEmpty
        ? _warnings.join('; ')
        : 'No major warnings detected';
    final benefitSummary = _benefits.isNotEmpty
        ? _benefits.join('; ')
        : 'No specific benefits detected';
    final ingredientSummary = _ingredients.isNotEmpty
        ? _ingredients.join(', ')
        : 'No ingredient details captured';

    return [
      'Check and See - Scan Summary',
      'Product: ${ScanSession.productName}',
      if (brand.isNotEmpty) 'Brand: $brand',
      'Health score: $_score/100',
      'Warnings: $warningSummary',
      'Benefits: $benefitSummary',
      'Key ingredients: $ingredientSummary',
      'Recommendation: ${ScanSession.recommendation.trim().isNotEmpty ? ScanSession.recommendation.trim() : _scoreLabel}',
    ].join('\n');
  }

  Future<void> _handleShare() async {
    final text = _shareSummary();
    await Share.share(text, subject: 'Check and See - Scan Summary');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share sheet opened.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _warningContext() {
    if (ScanSession.recommendation.trim().isNotEmpty) {
      return ScanSession.recommendation.trim();
    }
    return 'Detected from scanned label and nutrition profile.';
  }

  String _benefitContext() {
    if (ScanSession.impactForUser.trim().isNotEmpty) {
      return ScanSession.impactForUser.trim();
    }
    return 'Potential benefit based on ingredient and nutrient signals.';
  }

  Future<void> _startArTryOn() async {
    final beauty = _beauty;
    if (beauty == null) {
      return;
    }

    ArTryOnSession session;
    try {
      session = await _arOverlayProvider.createSession(
        recommendations: beauty.recommendations,
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${error.message} Run with --dart-define=BANUBA_CLIENT_TOKEN=... --dart-define=BANUBA_AR_CLOUD_TOKEN=...',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeautyTryOnWidget(
          analysis: beauty,
          session: session,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductAnalysisModel());
    _hydrateLatestScan();
  }

  Uint8List? _decodeDataImage(String value) {
    if (!value.startsWith('data:image/')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1 || commaIndex == value.length - 1) return null;
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  List<String> _defaultWarningsForScore(int score) => score < 60
      ? const [
          'Higher sugar load',
          'Processed ingredient profile',
          'May not fit frequent consumption'
        ]
      : const [
          'Moderate sodium level',
          'Contains added flavoring',
          'Watch serving size'
        ];

  List<String> _defaultBenefits() => const [
        'Includes grain-based ingredients',
        'Provides quick energy',
        'Can fit occasional balanced diet'
      ];

  bool _isPlaceholderName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'scanned product' ||
        normalized == 'unknown product' ||
        normalized == 'product';
  }

  Future<void> _hydrateLatestScan() async {
    if (ScanSession.latestAnalysis != null) {
      return;
    }
    if (!loggedIn || currentUserUid.isEmpty) return;

    try {
      final scans = await queryScansRecordOnce(
        queryBuilder: (q) => q.where('user_id', isEqualTo: currentUserUid),
      );
      if (scans.isEmpty) return;

      final sorted = [...scans]
        ..sort((a, b) {
          final aDate = a.scanDate ?? a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.scanDate ?? b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      final latest = sorted.first;
      final latestDate = latest.scanDate ?? latest.createdTime;
      if (ScanSession.scannedAt != null &&
          latestDate != null &&
          ScanSession.scannedAt!.isAfter(latestDate)) {
        return;
      }

      final score = int.tryParse(latest.healthScore.trim()) ?? 70;
      final productName = !_isPlaceholderName(latest.productName)
          ? latest.productName.trim()
          : (!_isPlaceholderName(latest.brandName)
              ? latest.brandName.trim()
              : 'Latest scanned item');
      final brandName = !_isPlaceholderName(latest.brandName) &&
              latest.brandName.trim().toLowerCase() != 'auto-detected'
          ? latest.brandName.trim()
          : '';
      final analysis = ScanAnalysisResult(
        productType: ScanProductTypeX.fromStorageValue(latest.productType),
        productName: productName,
        brandName: brandName,
        healthScore: score.clamp(1, 100),
        ingredients: latest.ingredients
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        warnings: latest.warnings.isNotEmpty
            ? latest.warnings.take(3).toList()
            : _defaultWarningsForScore(score),
        benefits:
            latest.benefits.isNotEmpty ? latest.benefits.take(3).toList() : _defaultBenefits(),
        recommendation: latest.recommendation.trim().isNotEmpty
            ? latest.recommendation.trim()
            : (score >= 75
                ? 'Good fit for occasional use. Keep portions moderate.'
                : 'Use occasionally and pair with whole-food options.'),
        impactForUser: latest.impactForUser,
      );

      ScanSession.updateAnalysisOnly(
        analysis,
        bytes: _decodeDataImage(latest.productImage),
        at: latestDate,
      );

      if (mounted) {
        safeSetState(() {});
      }
    } catch (_) {
      // Keep existing in-memory analysis if hydration fails.
    }
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
          leading: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
            child: FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 22.0,
              borderWidth: 0.0,
              buttonSize: 44.0,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF3B2F2F),
                size: 24.0,
              ),
              onPressed: () async {
                context.safePop();
              },
            ),
          ),
          title: Text(
            'Scan Results',
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: TextStyle(fontFamily: 'Times New Roman MT',
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: Color(0xFF3B2F2F),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 22.0,
                borderWidth: 0.0,
                buttonSize: 44.0,
                icon: Icon(
                  Icons.share_outlined,
                  color: Color(0xFF3B2F2F),
                  size: 24.0,
                ),
                onPressed: () async {
                  await _handleShare();
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 10.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 26.0,
                        color: Color(0x120A1220),
                        offset: Offset(
                          0.0,
                          12.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(26.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            width: 80.0,
                            height: 80.0,
                            decoration: BoxDecoration(
                              color: Color(0xFFE8DDD4),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: _hasLiveScan
                                  ? Image.memory(
                                      ScanSession.imageBytes!,
                                      width: 80.0,
                                      height: 80.0,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      'https://images.unsplash.com/photo-1630314902992-b32bb58d0dc6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NzI3MjY4OTF8&ixlib=rb-4.1.0&q=80&w=1080',
                                      width: 80.0,
                                      height: 80.0,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ScanSession.productName,
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      font: TextStyle(fontFamily: 'Times New Roman MT',
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3B2F2F),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                              ),
                              Text(
                                ScanSession.brandName,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF8B6A52),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Container(
                                height: 26.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5EAD7),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10.0, 0.0, 10.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFFC8A97E),
                                        size: 12.0,
                                      ),
                                      Text(
                                        'Verified Scan',
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFFC8A97E),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ].divide(SizedBox(width: 4.0)),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                        ),
                      ].divide(SizedBox(width: 16.0)),
                    ),
                  ),
                ),
              ),
              if (ScanSession.impactForUser.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFEDE3D1),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            color: Color(0xFF8B6A52),
                            size: 20.0,
                          ),
                          Expanded(
                            child: Text(
                              ScanSession.impactForUser,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF3B2F2F),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ].divide(SizedBox(width: 10.0)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        color: Color(0x14000000),
                        offset: Offset(
                          0.0,
                          4.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Health Score',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: TextStyle(fontFamily: 'Times New Roman MT',
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF8B6A52),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Stack(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            children: [
                              CircularPercentIndicator(
                                percent: _scorePercent,
                                radius: 80.0,
                                lineWidth: 14.0,
                                animation: true,
                                animateFromLastPercent: true,
                                progressColor: _scoreColor,
                                backgroundColor: Color(0xFFF5F0E6),
                                startAngle: 270.0,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _score.toString(),
                                    style: FlutterFlowTheme.of(context)
                                        .displaySmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w800,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .displaySmall
                                                    .fontStyle,
                                          ),
                                          color: _scoreColor,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w800,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .displaySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    '/ 100',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32.0,
                          decoration: BoxDecoration(
                            color: _score >= 80
                                ? Color(0xFFF5EAD7)
                                : _score >= 60
                                    ? Color(0xFFFEF9C3)
                                    : Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _score >= 80
                                      ? Color(0xFF5C4033)
                                      : _score >= 60
                                          ? Color(0xFFCA8A04)
                                          : Color(0xFF991B1B),
                                  size: 16.0,
                                ),
                                Text(
                                  _scoreLabel,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        color: _score >= 80
                                          ? Color(0xFF5C4033)
                                          : _score >= 60
                                            ? Color(0xFFCA8A04)
                                            : Color(0xFF991B1B),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 6.0)),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 8.0)),
                    ),
                  ),
                ),
              ),
              if (_showBeautyInsights)
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFEDE3D1),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16.0,
                          color: Color(0x14000000),
                          offset: Offset(
                            0.0,
                            4.0,
                          ),
                        )
                      ],
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beauty Match',
                            style:
                                FlutterFlowTheme.of(context).titleMedium.override(
                                      font: TextStyle(
                                        fontFamily: 'Times New Roman MT',
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3B2F2F),
                                      letterSpacing: 0.0,
                                    ),
                          ),
                          Text(
                            'Skin tone: ${_beauty!.skinTone.label}  •  Undertone: ${_beauty!.undertone.label}',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF8B6A52),
                                  letterSpacing: 0.0,
                                ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _beauty!.facialFeatures.entries
                                .map(
                                  (entry) => Container(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 6.0, 10.0, 6.0),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF5EAD7),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF5C4033),
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          Column(
                            children: _beauty!.recommendations.take(4).map((r) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFCF8F2),
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(
                                    color: Color(0xFFE5CDAF),
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.category.label}: ${r.name}',
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: TextStyle(
                                                fontFamily: 'Times New Roman MT',
                                                fontWeight: FontWeight.w700,
                                                fontStyle: FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                              ),
                                              color: Color(0xFF3B2F2F),
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      Text(
                                        '${r.brand} • ${r.finish}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                fontStyle: FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                              ),
                                              color: Color(0xFF8B6A52),
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      Text(
                                        r.matchReason,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.normal,
                                                fontStyle: FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                              ),
                                              color: Color(0xFF5C4033),
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 4.0)),
                                  ),
                                ),
                              );
                            }).toList().divide(SizedBox(height: 10.0)),
                          ),
                          FFButtonWidget(
                            onPressed: () async {
                              await _startArTryOn();
                            },
                            text: 'Try On with AR',
                            icon: Icon(
                              Icons.face_retouching_natural,
                              size: 18.0,
                            ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 46.0,
                              color: Color(0xFFB78466),
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: TextStyle(
                                      fontFamily: 'Perandory SemiCondensed',
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                  ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          Text(
                            'How to apply this look',
                            style: FlutterFlowTheme.of(context).titleSmall.override(
                                  font: TextStyle(
                                    fontFamily: 'Times New Roman MT',
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF3B2F2F),
                                  letterSpacing: 0.0,
                                ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _beauty!.tutorialSteps
                                .take(5)
                                .toList()
                                .asMap()
                                .entries
                                .map(
                              (entry) {
                                final index = entry.key + 1;
                                final step = entry.value;
                                return Text(
                                  '$index. ${step.title} - ${step.description}',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.normal,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .fontStyle,
                                        ),
                                        color: Color(0xFF5C4033),
                                        letterSpacing: 0.0,
                                      ),
                                );
                              },
                            ).toList().divide(SizedBox(height: 6.0)),
                          ),
                        ].divide(SizedBox(height: 12.0)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        color: Color(0x14000000),
                        offset: Offset(
                          0.0,
                          4.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF1F2),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 16.0,
                                ),
                              ),
                            ),
                            Text(
                              'Warnings',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: TextStyle(fontFamily: 'Times New Roman MT',
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF3B2F2F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFE9DCC8),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF1F2),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _warnings.isNotEmpty
                                        ? _warnings[0]
                                        : 'Scan warning',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _warningContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF7ED),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFF97316),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _warnings.length > 1
                                        ? _warnings[1]
                                        : 'Flavor additive warning',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _warningContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF7ED),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Color(0xFFF97316),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _warnings.length > 2
                                        ? _warnings[2]
                                        : 'Calorie density warning',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _warningContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        color: Color(0x14000000),
                        offset: Offset(
                          0.0,
                          4.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5EAD7),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFFC8A97E),
                                  size: 16.0,
                                ),
                              ),
                            ),
                            Text(
                              'Benefits',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: TextStyle(fontFamily: 'Times New Roman MT',
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF3B2F2F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFE9DCC8),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5EAD7),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFFC8A97E),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _benefits.isNotEmpty
                                        ? _benefits[0]
                                        : 'Potential benefit',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _benefitContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5EAD7),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFFC8A97E),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _benefits.length > 1
                                        ? _benefits[1]
                                        : 'Ingredient quality signal',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _benefitContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5EAD7),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFFC8A97E),
                                  size: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _benefits.length > 2
                                        ? _benefits[2]
                                        : 'Balanced intake support',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: TextStyle(fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    _benefitContext(),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        color: Color(0x14000000),
                        offset: Offset(
                          0.0,
                          4.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFE8DDD4),
                                shape: BoxShape.circle,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Icon(
                                  Icons.science_outlined,
                                  color: Color(0xFF4F46E5),
                                  size: 16.0,
                                ),
                              ),
                            ),
                            Text(
                              'Key Ingredients',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: TextStyle(fontFamily: 'Times New Roman MT',
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF3B2F2F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFE9DCC8),
                          ),
                        ),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          direction: Axis.horizontal,
                          runAlignment: WrapAlignment.start,
                          verticalDirection: VerticalDirection.down,
                          clipBehavior: Clip.none,
                          children: (_ingredients.isNotEmpty
                                  ? _ingredients
                                  : const ['No ingredients available'])
                              .asMap()
                              .entries
                              .map((entry) {
                            final palette = [
                              const Color(0xFFE8DDD4),
                              const Color(0xFFF5EAD7),
                              const Color(0xFFFFF1F2),
                              const Color(0xFFFFF7ED),
                            ];
                            final textPalette = [
                              const Color(0xFF4F46E5),
                              const Color(0xFF16A34A),
                              const Color(0xFFEF4444),
                              const Color(0xFFF97316),
                            ];
                            final index = entry.key;
                            final ingredient = entry.value;
                            return Container(
                              decoration: BoxDecoration(
                                color: palette[index % palette.length],
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 6.0, 12.0, 6.0),
                                child: Text(
                                  ingredient,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        color: textPalette[index % textPalette.length],
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FFButtonWidget(
                      onPressed: () async {
                        context.pushNamed(HealthInsightDashboardWidget.routeName);
                      },
                      text: 'View Health Insights',
                      icon: Icon(
                        Icons.insights_rounded,
                        size: 20.0,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconColor: Colors.white,
                        color: Color(0xFF5C4033),
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Times New Roman MT',
                              color: Color(0xFFEDE3D1),
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                        elevation: 0.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 0.0,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                        context.pushNamed(ProductScanningWidget.routeName);
                      },
                      text: 'Scan Another Product',
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 20.0,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconColor: Color(0xFF5C4033),
                        color: Color(0xFFF7F0EB),
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Times New Roman MT',
                              color: Color(0xFF5C4033),
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                        elevation: 0.0,
                        borderSide: BorderSide(
                          color: Color(0xFF5C4033),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ].divide(SizedBox(height: 12.0)),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
            ]
                .addToStart(SizedBox(height: 16.0))
                .addToEnd(SizedBox(height: 32.0)),
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 14.0),
          decoration: BoxDecoration(
            color: Color(0xFFEDE3D1),
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24.0,
                color: Color(0x180F172A),
                offset: Offset(0.0, 8.0),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14.0, 10.0, 14.0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () async {
                    context.pushNamed(MainPageWidget.routeName);
                  },
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_rounded,
                          color: Color(0xFF667085), size: 22.0),
                      Text(
                        'Home',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    context.pushNamed(ProductScanningWidget.routeName);
                  },
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          color: Color(0xFF667085), size: 22.0),
                      Text(
                        'Scan',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    context.pushNamed(HealthInsightDashboardWidget.routeName);
                  },
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insights_rounded,
                          color: Color(0xFF667085), size: 22.0),
                      Text(
                        'Insights',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    context.pushNamed(HistoryPageWidget.routeName);
                  },
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          color: Color(0xFF667085), size: 22.0),
                      Text(
                        'History',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    context.pushNamed(UserProfileWidget.routeName);
                  },
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded,
                          color: Color(0xFF667085), size: 22.0),
                      Text(
                        'Profile',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
