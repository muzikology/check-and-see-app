import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/scan_analyzer.dart';
import '/scan_session.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'main_page_model.dart';
export 'main_page_model.dart';

/// Create a modern mobile app screen for an AI product scanner app.
///
/// The app allows users to scan food, skincare, and beauty products using
/// their phone camera and receive personalized health insights.
///
/// Design requirements:
/// - Modern minimal interface
/// - Inspired by Apple Health and MyFitnessPal
/// - Rounded cards
/// - Soft shadows
/// - Clean typography
///
/// The screen should contain:
///
/// Header greeting
/// Large scan button
/// Recent scans list
/// Health score indicators
///
/// Navigation tabs:
/// Home
/// Scan
/// Insights
/// History
/// Profile
///
/// Primary color:
/// Deep green (#1B5E20)
///
/// The design should look premium and modern.
class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

  static String routeName = 'MainPage';
  static String routePath = 'mainPage';

  @override
  State<MainPageWidget> createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  late MainPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController _searchController;
  String _searchQuery = '';
  final Set<String> _nameRepairInFlight = <String>{};
  final Set<String> _nameRepairCompleted = <String>{};
  bool _isRepairSweepRunning = false;

  String get _displayName {
    final fromDoc = currentUserDocument?.displayName;
    if (fromDoc != null && fromDoc.trim().isNotEmpty) {
      return fromDoc.trim();
    }
    if (currentUserDisplayName.trim().isNotEmpty) {
      return currentUserDisplayName.trim();
    }
    if (currentUserEmail.trim().isNotEmpty) {
      return currentUserEmail.trim().split('@').first;
    }
    return 'Guest';
  }

  String get _avatarUrl {
    final fromDoc = currentUserDocument?.photoUrl;
    if (fromDoc != null && fromDoc.trim().isNotEmpty) {
      return fromDoc.trim();
    }
    return currentUserPhoto.trim();
  }

  bool _isDataImageUrl(String value) => value.startsWith('data:image/');

  Uint8List? _decodeDataImage(String value) {
    if (!_isDataImageUrl(value)) {
      return null;
    }
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1 || commaIndex == value.length - 1) {
      return null;
    }
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  String get _initials {
    final parts = _displayName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildAvatarBadge(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 52.0,
          height: 52.0,
          decoration: BoxDecoration(
            color: Color(0xFFEDE3D1),
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(52.0),
            child: _avatarUrl.isNotEmpty
                ? (_isDataImageUrl(_avatarUrl)
                    ? ((_decodeDataImage(_avatarUrl) != null)
                        ? Image.memory(
                            _decodeDataImage(_avatarUrl)!,
                            width: 52.0,
                            height: 52.0,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              _initials,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: TextStyle(
                                      fontFamily: 'Times New Roman MT',
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF3B2F2F),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ))
                    : Image.network(
                        _avatarUrl,
                        width: 52.0,
                        height: 52.0,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _initials,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: TextStyle(
                                    fontFamily: 'Times New Roman MT',
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF3B2F2F),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                      ))
                : Center(
                    child: Text(
                      _initials,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: TextStyle(
                              fontFamily: 'Times New Roman MT',
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: Color(0xFF3B2F2F),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 0.0,
          left: 0.0,
          child: Container(
            width: 14.0,
            height: 14.0,
            decoration: BoxDecoration(
              color: Color(0xFF92C85C),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFFF5F0E6),
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  void _scheduleLabelRepairs(List<ScansRecord> scans) {
    if (_isRepairSweepRunning) {
      return;
    }

    final candidates = scans.where((scan) {
      return _isPlaceholderName(scan.productName) &&
          scan.productImage.startsWith('data:image/') &&
          !_nameRepairCompleted.contains(scan.reference.id);
    }).toList();

    if (candidates.isEmpty) {
      return;
    }

    _isRepairSweepRunning = true;
    _runRepairSweep(candidates).whenComplete(() {
      _isRepairSweepRunning = false;
    });
  }

  Future<void> _runRepairSweep(List<ScansRecord> scans) async {
    const maxBatchSize = 30;
    const maxConcurrent = 3;
    final queue = scans.take(maxBatchSize).toList();

    for (var i = 0; i < queue.length; i += maxConcurrent) {
      final chunk = queue.skip(i).take(maxConcurrent).toList();
      await Future.wait(chunk.map((scan) async {
        final id = scan.reference.id;
        if (_nameRepairInFlight.contains(id)) {
          return;
        }
        _nameRepairInFlight.add(id);
        try {
          await _repairLabelName(scan);
        } finally {
          _nameRepairInFlight.remove(id);
          _nameRepairCompleted.add(id);
        }
      }));
    }
  }

  Future<void> _repairLabelName(ScansRecord scan) async {
    try {
      final extracted = await ScanAnalyzer.extractProductAndBrandFromDataUrl(
        scan.productImage,
      );
      if (extracted == null) {
        return;
      }
      final productName = (extracted['productName'] ?? '').trim();
      final brandName = (extracted['brandName'] ?? '').trim();
      if (productName.isEmpty && brandName.isEmpty) {
        return;
      }
      await scan.reference.update({
        'product_name': productName,
        'brand_name': brandName,
      });
    } catch (_) {
      // Keep UI responsive; failed repairs can retry later.
    }
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

    ScanSession.updateAnalysisOnly(
      analysis,
      bytes: _decodeDataImage(scan.productImage),
      at: scan.scanDate ?? scan.createdTime,
    );

    if (!mounted) {
      return;
    }
    context.pushNamed(ProductAnalysisWidget.routeName);
  }

  Future<void> _deleteScanRecord(ScansRecord scan) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete product?'),
            content: const Text(
              'This will remove the scan from your history and main page list.',
            ),
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
        ) ??
        false;

    if (!confirm) {
      return;
    }

    await scan.reference.delete();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainPageModel());
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<ScansRecord>>(
            stream: queryScansRecord(
              queryBuilder: (q) => q.where('user_id', isEqualTo: currentUserUid),
              limit: 120,
            ),
            builder: (context, snapshot) {
              final scans = [...(snapshot.data ?? const <ScansRecord>[])]
                ..sort((a, b) =>
                    (b.scanDate ?? b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0))
                        .compareTo(
                            a.scanDate ?? a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0)));

              int parseScore(ScansRecord scan) =>
                  int.tryParse(scan.healthScore.trim()) ?? 0;

              final avgScore = scans.isEmpty
                  ? 0
                  : (scans.map(parseScore).reduce((a, b) => a + b) / scans.length)
                      .round();
              final alertCount = scans.where((s) => parseScore(s) < 60).length;
              final latestScan = scans.isNotEmpty ? scans.first : null;
                final isBeautyFocus =
                  (latestScan?.productType.toLowerCase().trim() ?? '') ==
                    'beauty';
              final query = _searchQuery.trim().toLowerCase();
              final visibleScans = scans
                  .where((scan) {
                    if (query.isEmpty) {
                      return true;
                    }
                    final haystack = [
                      scan.productName,
                      scan.brandName,
                      scan.ingredients,
                    ].join(' ').toLowerCase();
                    return haystack.contains(query);
                  })
                  .toList();
                  _scheduleLabelRepairs(scans);

              return Container(
                color: Color(0xFFF5F0E6),
                child: SingleChildScrollView(
                    child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                    padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 10.0, 20.0, 22.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            alignment: AlignmentDirectional(0.18, 0.0),
                            image: AssetImage(
                              'assets/images/background_image2.png',
                            ),
                          ),
                          gradient: LinearGradient(
                            colors: [Color(0x55F5EBDD), Color(0xC8C5A485)],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(-1.0, 0.0),
                            end: AlignmentDirectional(1.0, 0.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 28.0,
                              color: Color(0x2A78604F),
                              offset: Offset(
                                0.0,
                                8.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(18.0, 26.0, 18.0, 18.0),
                          child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: SizedBox(
                              width: 200.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBeautyFocus
                                        ? 'Beauty Companion'
                                        : 'Scan a Product',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8B6A52),
                                          fontSize: 13.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    isBeautyFocus
                                        ? 'Skin + Ingredient\nAssistant'
                                        : 'Know What\'s\nInside',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .override(
                                          font: TextStyle(
                                            fontFamily: 'Times New Roman MT',
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineLarge
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3B2F2F),
                                          fontSize: 26.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                          lineHeight: 1.25,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: SizedBox(
                              width: 200.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x66F7EEE1),
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: const Color(0x88E5CDAF),
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isBeautyFocus
                                              ? 'Daily routine\nprogress'
                                              : 'Weekly nutrition\nconsistency',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                font: TextStyle(
                                                  fontFamily:
                                                      'Perandory SemiCondensed',
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                                color: const Color(0xFF5C4033),
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 72.0,
                                        child: LinearProgressIndicator(
                                          value: isBeautyFocus ? 0.72 : 0.63,
                                          minHeight: 7.0,
                                          backgroundColor:
                                              const Color(0xFFE9DCC8),
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFC8A97E),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              context.pushNamed(ProductScanningWidget.routeName);
                            },
                            borderRadius: BorderRadius.circular(20.0),
                            child: Container(
                              width: double.infinity,
                              height: 138.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0x66F7EBDD), Color(0x4DD8BEA0)],
                                  stops: [0.0, 1.0],
                                  begin: AlignmentDirectional(-1.0, -1.0),
                                  end: AlignmentDirectional(1.0, 1.0),
                                ),
                                border: Border.all(
                                  color: Color(0x66E5CDAF),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 72.0,
                                          height: 72.0,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF1D8BC),
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 24.0,
                                                color: Color(0x44B78466),
                                                offset: Offset(
                                                  0.0,
                                                  6.0,
                                                ),
                                              )
                                            ],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.qr_code_scanner_rounded,
                                              color: Color(0xFFF9F2E8),
                                              size: 34.0,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 10.0, 0.0, 0.0),
                                          child: Text(
                                            'Tap to Scan',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: TextStyle(
                                                    fontFamily:
                                                        'Sloop Script Pro',
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF6C4F3B),
                                                  fontSize: 14.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xB3F7EBDD),
                              borderRadius: BorderRadius.circular(18.0),
                              border: Border.all(
                                color: Color(0x66D9B894),
                                width: 1.0,
                              ),
                            ),
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 8.0, 10.0, 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fastfood_outlined,
                                      color: Color(0xFFB97742),
                                      size: 20.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Food',
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
                                              color: Color(0xFFB97742),
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: Color(0x55B97742),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.spa_outlined,
                                      color: Color(0xFFB97742),
                                      size: 20.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Skincare',
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
                                              color: Color(0xFFB97742),
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: Color(0x55B97742),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.face_retouching_natural,
                                      color: Color(0xFFB97742),
                                      size: 20.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Beauty',
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
                                              color: Color(0xFFB97742),
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ],
                            ),
                          ),
                        ].divide(SizedBox(height: 20.0)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -14.0,
                        right: -6.0,
                        child: _buildAvatarBadge(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Health Overview',
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
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                      ),
                      Text(
                        'This week',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: Color(0xFF8B6A52),
                              fontSize: 13.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Expanded(
                      child: Container(
                        width: 100.0,
                        height: 116.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFEDE3D1),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12.0,
                              color: Color(0x14000000),
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5EAD7),
                                  shape: BoxShape.circle,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.favorite_border_rounded,
                                    color: Color(0xFF5C4033),
                                    size: 20.0,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 6.0, 0.0, 0.0),
                                child: Text(
                                  avgScore.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: TextStyle(fontFamily: 'Times New Roman MT',
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF5C4033),
                                        fontSize: 22.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Text(
                                'Avg Score',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 100.0,
                        height: 116.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFEDE3D1),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12.0,
                              color: Color(0x14000000),
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF7F0EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.bar_chart_rounded,
                                    color: Color(0xFFB78466),
                                    size: 20.0,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 6.0, 0.0, 0.0),
                                child: Text(
                                  scans.length.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: TextStyle(fontFamily: 'Times New Roman MT',
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFFB78466),
                                        fontSize: 22.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Text(
                                'Scanned',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 100.0,
                        height: 116.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFEDE3D1),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12.0,
                              color: Color(0x14000000),
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5EAD7),
                                  shape: BoxShape.circle,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFC8A97E),
                                    size: 20.0,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 6.0, 0.0, 0.0),
                                child: Text(
                                  alertCount.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: TextStyle(fontFamily: 'Times New Roman MT',
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFFC8A97E),
                                        fontSize: 22.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Text(
                                'Alerts',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ].divide(SizedBox(width: 12.0)),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scanned Products',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: TextStyle(fontFamily: 'Times New Roman MT',
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF3B2F2F),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                      ),
                      Text(
                        '${visibleScans.length} total',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: Color(0xFF5C4033),
                              fontSize: 13.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE3D1),
                    border: Border.all(color: Color(0xFFEFF3F8), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        color: Color(0x0F0F172A),
                        offset: Offset(
                          0.0,
                          4.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              6.0, 0.0, 6.0, 8.0),
                          child: TextFormField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by product name',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9E7E6A),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: Color(0xFF9E7E6A),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Color(0xFFFCF8F2),
                              contentPadding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 10.0, 12.0, 10.0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE5CDAF),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF5C4033),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                        if (visibleScans.isEmpty)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                12.0, 18.0, 12.0, 18.0),
                            child: Text(
                              scans.isEmpty
                                  ? 'No scans yet. Start scanning to see your latest products.'
                                  : 'No product matches your search.',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context).bodySmall,
                            ),
                          )
                        else
                          SizedBox(
                            height: 320.0,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              itemCount: visibleScans.length,
                              itemBuilder: (context, index) {
                                final scan = visibleScans[index];
                                final score = int.tryParse(scan.healthScore.trim()) ?? 0;
                              final scoreColor = score >= 80
                                  ? Color(0xFF5C4033)
                                  : score >= 60
                                      ? Color(0xFFB78466)
                                      : Color(0xFFC24664);
                              final scoreBg = score >= 80
                                  ? Color(0xFFF5EAD7)
                                  : score >= 60
                                      ? Color(0xFFF7F0EB)
                                      : Color(0xFFFCECEF);
                              final firstIngredient = scan.ingredients
                                  .split(',')
                                  .map((e) => e.trim())
                                  .firstWhere((e) => e.isNotEmpty,
                                      orElse: () => 'No ingredients found');
                              final scanDate =
                                  scan.scanDate ?? scan.createdTime ?? getCurrentTimestamp;
                                final productTitle = _productLabel(scan);
                                final productSubtitle = _brandLabel(scan).isNotEmpty
                                  ? '${_brandLabel(scan)} · ${dateTimeFormat("yMMMd", scanDate)}'
                                  : dateTimeFormat("yMMMd", scanDate);

                              Widget imageWidget;
                              if (scan.productImage.startsWith('data:image/')) {
                                final bytes = _decodeDataImage(scan.productImage);
                                imageWidget = bytes != null
                                    ? Image.memory(
                                        bytes,
                                        width: 52.0,
                                        height: 52.0,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.image_not_supported_rounded,
                                        color: Color(0xFF9E7E6A));
                              } else if (scan.productImage.isNotEmpty) {
                                imageWidget = Image.network(
                                  scan.productImage,
                                  width: 52.0,
                                  height: 52.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.image_outlined,
                                          color: Color(0xFF9E7E6A)),
                                );
                              } else {
                                imageWidget = Icon(Icons.inventory_2_rounded,
                                    color: Color(0xFF9E7E6A));
                              }

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async => _openScanInAnalysis(scan),
                                child: Container(
                                  margin: EdgeInsetsDirectional.fromSTEB(
                                      4.0, 4.0, 4.0, 8.0),
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 10.0, 12.0, 10.0),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFCF8F2),
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: Color(0xFFE5CDAF),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 56.0,
                                              height: 56.0,
                                              decoration: BoxDecoration(
                                                color: scoreBg,
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                                child: imageWidget,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productTitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .override(
                                                          font: TextStyle(
                                                          fontFamily:
                                                            'Times New Roman MT',
                                                          fontWeight:
                                                            FontWeight
                                                              .w700,
                                                          fontStyle:
                                                            FlutterFlowTheme.of(context)
                                                              .titleSmall
                                                              .fontStyle,
                                                          ),
                                                          color: Color(0xFF3B2F2F),
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                0.0,
                                                                2.0,
                                                                0.0,
                                                                0.0),
                                                    child: Text(
                                                      productSubtitle,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                            font: GoogleFonts
                                                              .poppins(
                                                              fontWeight:
                                                                FontWeight
                                                                  .w500,
                                                            ),
                                                                color: Color(
                                                                    0xFF8B6A52),
                                                                fontSize: 12.0,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                0.0,
                                                                5.0,
                                                                0.0,
                                                                0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Icon(
                                                          Icons.brightness_1,
                                                          color: scoreColor,
                                                          size: 9.0,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            firstIngredient,
                                                            maxLines: 1,
                                                            overflow: TextOverflow
                                                                .ellipsis,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodySmall
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                    .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                  color:
                                                                      scoreColor,
                                                                  fontSize:
                                                                      11.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 6.0)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 12.0)),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 48.0,
                                            height: 32.0,
                                            decoration: BoxDecoration(
                                              color: scoreBg,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Align(
                                              alignment:
                                                  AlignmentDirectional(0.0, 0.0),
                                              child: Text(
                                                score.toString(),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                      color: scoreColor,
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 6.0, 0.0, 0.0),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: Color(0xFF8B6A52),
                                              size: 20.0,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color: Color(0xFF8B6A52),
                                              size: 18.0,
                                            ),
                                            onSelected: (value) async {
                                              if (value == 'view') {
                                                await _openScanInAnalysis(scan);
                                                return;
                                              }
                                              if (value == 'delete') {
                                                await _deleteScanRecord(scan);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem<String>(
                                                value: 'view',
                                                child: Text('View analysis'),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text('Delete product'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Insights',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: TextStyle(fontFamily: 'Times New Roman MT',
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF3B2F2F),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFEDE3D1),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12.0,
                          color: Color(0x14000000),
                          offset: Offset(
                            0.0,
                            4.0,
                          ),
                        )
                      ],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: latestScan == null
                          ? Text(
                              'No insights yet. Scan a product to get personalized analysis.',
                              style: FlutterFlowTheme.of(context).bodySmall,
                            )
                          : InkWell(
                              onTap: () async => _openScanInAnalysis(latestScan),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 48.0,
                                    height: 48.0,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF5EAD7),
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_rounded,
                                      color: Color(0xFF5C4033),
                                      size: 24.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            _productLabel(latestScan),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall,
                                        ),
                                        Text(
                                          latestScan.recommendation.trim().isNotEmpty
                                              ? latestScan.recommendation.trim()
                                              : _defaultRecommendationForScore(
                                                  parseScore(latestScan),
                                                ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                                                color: Color(0xFF9E7E6A),
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ].divide(SizedBox(height: 4.0)),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF9E7E6A),
                                    size: 22.0,
                                  ),
                                ].divide(SizedBox(width: 12.0)),
                              ),
                            ),
                    ),
                  ),
                ),
              ]
                  .addToStart(SizedBox(height: 8.0))
                  .addToEnd(SizedBox(height: 100.0)),
                ),
              ),
            );
            },
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
                  onTap: () async {},
                  borderRadius: BorderRadius.circular(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F0EB),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(Icons.home_rounded,
                          color: Color(0xFFB78466), size: 22.0),
                      ),
                      Text(
                        'Home',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFFB78466),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
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
                    context.pushNamed(
                      loggedIn
                          ? UserProfileWidget.routeName
                          : AuthPageWidget.routeName,
                    );
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
