import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'health_insight_dashboard_model.dart';
export 'health_insight_dashboard_model.dart';

/// Create a health insights dashboard screen for a product scanning app.
///
/// Purpose:
/// Show trends based on user's scanned products.
///
/// Design style:
/// Modern analytics dashboard.
///
/// Layout:
///
/// Top section:
/// Greeting message
/// Text: Your Health Insights
///
/// Below greeting:
/// Three statistic cards
///
/// Healthy products scanned
/// Moderate products scanned
/// Unhealthy products scanned
///
/// Next section:
/// Weekly health score chart.
///
/// Chart type:
/// Bar chart.
///
/// Label:
/// Health Score This Week
///
/// Next section:
/// Category breakdown.
///
/// Pie chart showing:
/// Food
/// Skincare
/// Beauty
///
/// Final section:
/// Tips card
///
/// Example tips:
/// Reduce sugar products
/// Choose fragrance free skincare
/// Increase natural ingredients
///
/// Design notes:
/// Clean cards
/// Rounded corners
/// Soft shadows
/// Minimal modern style
class HealthInsightDashboardWidget extends StatefulWidget {
  const HealthInsightDashboardWidget({super.key});

  static String routeName = 'HealthInsightDashboard';
  static String routePath = 'healthInsightDashboard';

  @override
  State<HealthInsightDashboardWidget> createState() =>
      _HealthInsightDashboardWidgetState();
}

class _HealthInsightDashboardWidgetState
    extends State<HealthInsightDashboardWidget> {
  late HealthInsightDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HealthInsightDashboardModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  String _classifyCategory(ScansRecord scan) {
    final source = '${scan.productName} ${scan.ingredients}'.toLowerCase();
    const skincareKeywords = [
      'serum',
      'cleanser',
      'lotion',
      'cream',
      'moistur',
      'retinol',
      'niacinamide',
      'spf',
      'sunscreen',
      'face wash',
      'toner'
    ];
    const beautyKeywords = [
      'lipstick',
      'mascara',
      'foundation',
      'concealer',
      'blush',
      'eyeliner',
      'makeup',
      'perfume',
      'fragrance'
    ];

    if (skincareKeywords.any(source.contains)) {
      return 'skincare';
    }
    if (beautyKeywords.any(source.contains)) {
      return 'beauty';
    }
    return 'food';
  }

  String _categorySummary(int count, int total) {
    if (total <= 0) return '0% · 0 items';
    final percent = ((count / total) * 100).round();
    return '$percent% · $count ${count == 1 ? 'item' : 'items'}';
  }

  String _categoryPercentLabel(int count, int total) {
    if (total <= 0) return '0%';
    final percent = ((count / total) * 100).round();
    return '$percent%';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = currentUserDisplayName.trim().isNotEmpty
        ? currentUserDisplayName.trim().split(' ').first
        : 'there';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F7FA),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 20.0,
            borderWidth: 0.0,
            buttonSize: 40.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1A2340),
              size: 22.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $displayName 👋',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: Color(0xFF8A94A6),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
              ),
              Text(
                'Your Health Insights',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.bold,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                      color: Color(0xFF1A2340),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 14.0,
                borderWidth: 0.0,
                buttonSize: 44.0,
                fillColor: Colors.white,
                icon: Icon(
                  Icons.notifications_none,
                  color: Color(0xFF1A2340),
                  size: 22.0,
                ),
                onPressed: () {
                  print('IconButton pressed ...');
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<ScansRecord>>(
          stream: queryScansRecord(
            queryBuilder: (q) => q
              .where('user_id', isEqualTo: currentUserUid),
            limit: 120,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final details = snapshot.error?.toString() ?? 'Unknown error';
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load insights right now. Please try again shortly.',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      if (kDebugMode)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 8.0, 0.0, 0.0),
                          child: Text(
                            details,
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF8A94A6),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              );
            }

            final scans = [...(snapshot.data ?? const <ScansRecord>[])]
              ..sort((a, b) => (b.scanDate ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(a.scanDate ?? DateTime.fromMillisecondsSinceEpoch(0)));
            int parseScore(ScansRecord scan) =>
              int.tryParse(scan.healthScore.trim()) ?? 0;
            final healthyCount =
              scans.where((s) => parseScore(s) >= 80).length;
            final moderateCount = scans
              .where((s) => parseScore(s) >= 60 && parseScore(s) < 80)
              .length;
            final unhealthyCount =
              scans.where((s) => parseScore(s) < 60).length;
            final avgScore = scans.isEmpty
              ? 0
              : (scans.map(parseScore).reduce((a, b) => a + b) /
                  scans.length)
                .round();
            final recent = scans.take(5).map(parseScore).toList();
            final previous = scans.skip(5).take(5).map(parseScore).toList();
            final recentAvg = recent.isEmpty
              ? avgScore.toDouble()
              : recent.reduce((a, b) => a + b) / recent.length;
            final previousAvg = previous.isEmpty
              ? recentAvg
              : previous.reduce((a, b) => a + b) / previous.length;
            final trendPercent = previousAvg == 0
              ? 0
              : (((recentAvg - previousAvg) / previousAvg) * 100).round();
            final latestScan = scans.isNotEmpty ? scans.first : null;
            final latestIngredients = (latestScan?.ingredients ?? '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .take(3)
              .toList();
            final latestWarnings = (latestScan?.warnings ?? const <String>[])
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .take(3)
              .toList();
            final latestProductName =
              (latestScan?.productName ?? '').trim().isNotEmpty
                ? latestScan!.productName.trim()
                : 'latest product';
            final today = DateTime.now();
            final weekStart = DateTime(today.year, today.month, today.day)
                .subtract(Duration(days: today.weekday - 1));
            const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final weeklyBuckets = List.generate(7, (_) => <int>[]);
            for (final scan in scans) {
              final date = scan.scanDate ?? scan.createdTime;
              if (date == null) continue;
              final day = DateTime(date.year, date.month, date.day);
              final dayOffset = day.difference(weekStart).inDays;
              if (dayOffset < 0 || dayOffset > 6) continue;
              weeklyBuckets[dayOffset].add(parseScore(scan));
            }
            final weeklyScores = List.generate(7, (index) {
              final values = weeklyBuckets[index];
              if (values.isEmpty) return 0;
              return (values.reduce((a, b) => a + b) / values.length).round();
            });
            List<Color> barColorsForScore(int score) {
              if (score >= 80) return [Color(0xFF4ADE80), Color(0xFF16A34A)];
              if (score >= 60) return [Color(0xFFFBBF24), Color(0xFFD97706)];
              if (score > 0) return [Color(0xFFFC6767), Color(0xFFDC2626)];
              return [Color(0xFFE5E7EB), Color(0xFFD1D5DB)];
            }

            final totalScans = scans.length;
            final foodCount = scans.where((scan) => _classifyCategory(scan) == 'food').length;
            final skincareCount =
                scans.where((scan) => _classifyCategory(scan) == 'skincare').length;
            final beautyCount = scans.where((scan) => _classifyCategory(scan) == 'beauty').length;
            final hasCategoryData = totalScans > 0;
            final foodRatio = hasCategoryData ? foodCount / totalScans : (1 / 3);
            final skincareRatio = hasCategoryData ? skincareCount / totalScans : (1 / 3);
            final beautyRatio = hasCategoryData ? beautyCount / totalScans : (1 / 3);
            final screenWidth = MediaQuery.sizeOf(context).width;
            final ringScale = (screenWidth / 430.0).clamp(0.82, 1.0);
            final ringSize = (130.0 * ringScale).toDouble();
            final ringLabelRadius = (58.0 * ringScale).toDouble();
            final ringBadgeWidth = (32.0 * ringScale).toDouble();
            final ringBadgeHeight = (18.0 * ringScale).toDouble();
            final ringBadgeRadius = (10.0 * ringScale).toDouble();
            final ringLabelFontSize = (9.0 * ringScale).clamp(8.0, 9.5).toDouble();
            final centerCircleSize = (80.0 * ringScale).toDouble();
            const ringLabelMinRatio = 0.08;
            final ringStartAngle = -math.pi / 2;
            final foodSweep = foodRatio * math.pi * 2;
            final skincareSweep = skincareRatio * math.pi * 2;
            final beautySweep = beautyRatio * math.pi * 2;
            final ringLabelData = [
              {
                'angle': ringStartAngle + (foodSweep / 2),
                'ratio': foodRatio,
                'label': _categoryPercentLabel(foodCount, totalScans),
                'color': const Color(0xFF166534),
                'bg': const Color(0xFFE8FCEB),
              },
              {
                'angle': ringStartAngle + foodSweep + (skincareSweep / 2),
                'ratio': skincareRatio,
                'label': _categoryPercentLabel(skincareCount, totalScans),
                'color': const Color(0xFFB45309),
                'bg': const Color(0xFFFFF7E6),
              },
              {
                'angle': ringStartAngle + foodSweep + skincareSweep + (beautySweep / 2),
                'ratio': beautyRatio,
                'label': _categoryPercentLabel(beautyCount, totalScans),
                'color': const Color(0xFF991B1B),
                'bg': const Color(0xFFFFECEC),
              },
            ];
            return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Container(
                            width: 100.0,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x1400C853),
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                )
                              ],
                              gradient: LinearGradient(
                                colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                                stops: [0.0, 1.0],
                                begin: AlignmentDirectional(1.0, 1.0),
                                end: AlignmentDirectional(-1.0, -1.0),
                              ),
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36.0,
                                  height: 36.0,
                                  decoration: BoxDecoration(
                                    color: Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                Text(
                                  healthyCount.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        fontSize: 34.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  'Healthy',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xCCFFFFFF),
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 8.0,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Container(
                            width: 100.0,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x14F59E0B),
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                )
                              ],
                              gradient: LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                stops: [0.0, 1.0],
                                begin: AlignmentDirectional(1.0, 1.0),
                                end: AlignmentDirectional(-1.0, -1.0),
                              ),
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36.0,
                                  height: 36.0,
                                  decoration: BoxDecoration(
                                    color: Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                Text(
                                  moderateCount.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        fontSize: 34.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  'Moderate',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xCCFFFFFF),
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 8.0,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Container(
                            width: 100.0,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x14EF4444),
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                )
                              ],
                              gradient: LinearGradient(
                                colors: [Color(0xFFFC6767), Color(0xFFDC2626)],
                                stops: [0.0, 1.0],
                                begin: AlignmentDirectional(1.0, 1.0),
                                end: AlignmentDirectional(-1.0, -1.0),
                              ),
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36.0,
                                  height: 36.0,
                                  decoration: BoxDecoration(
                                    color: Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                                Text(
                                  unhealthyCount.toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        fontSize: 34.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  'Unhealthy',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xCCFFFFFF),
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16.0,
                          color: Color(0x0D000000),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Score This Week',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A2340),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    scans.isEmpty
                                        ? 'No scans yet. Start scanning to build insights.'
                                        : 'Average score: $avgScore',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8A94A6),
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
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 0.0, 10.0, 0.0),
                                child: Container(
                                  height: 28.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '${trendPercent >= 0 ? '↑' : '↓'} ${trendPercent.abs()}%',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF16A34A),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              final score = weeklyScores[index];
                              final barHeight = score <= 0
                                  ? 24.0
                                  : (30.0 + (score.clamp(0, 100) * 0.9));
                              final barColors = barColorsForScore(score);
                              return Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32.0,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: barColors,
                                        stops: [0.0, 1.0],
                                        begin: AlignmentDirectional(0.0, -1.0),
                                        end: AlignmentDirectional(0.0, 1.0),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  Text(
                                    weekdayLabels[index],
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8A94A6),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ].divide(SizedBox(height: 6.0)),
                              );
                            }),
                          ),
                        ]
                            .divide(SizedBox(height: 16.0))
                            .addToStart(SizedBox(height: 20.0))
                            .addToEnd(SizedBox(height: 20.0)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16.0,
                          color: Color(0x0D000000),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category Breakdown',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF1A2340),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Stack(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  children: [
                                    SizedBox(
                                      width: ringSize,
                                      height: ringSize,
                                      child: CustomPaint(
                                        painter: _CategoryRingPainter(
                                          foodRatio: foodRatio,
                                          skincareRatio: skincareRatio,
                                          beautyRatio: beautyRatio,
                                        ),
                                      ),
                                    ),
                                    if (hasCategoryData)
                                      ...ringLabelData
                                          .where((entry) =>
                                              (entry['ratio'] as double) >=
                                              ringLabelMinRatio)
                                          .map((entry) {
                                        final angle = entry['angle'] as double;
                                        final label = entry['label'] as String;
                                        final color = entry['color'] as Color;
                                        final bg = entry['bg'] as Color;
                                        final x = (ringSize / 2) +
                                            (math.cos(angle) * ringLabelRadius);
                                        final y = (ringSize / 2) +
                                            (math.sin(angle) * ringLabelRadius);
                                        return Positioned(
                                          left: x - (ringBadgeWidth / 2),
                                          top: y - (ringBadgeHeight / 2),
                                          child: Container(
                                            width: ringBadgeWidth,
                                            height: ringBadgeHeight,
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius:
                                                  BorderRadius.circular(ringBadgeRadius),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                label,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: color,
                                                        fontSize: ringLabelFontSize,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    Container(
                                      width: centerCircleSize,
                                      height: centerCircleSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            '$totalScans\nTotal',
                                            textAlign: TextAlign.center,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 12.0,
                                        height: 12.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4ADE80),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Food',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            _categorySummary(foodCount, totalScans),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF8A94A6),
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 12.0,
                                        height: 12.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFBBF24),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Skincare',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            _categorySummary(skincareCount, totalScans),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF8A94A6),
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 12.0,
                                        height: 12.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFC6767),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Beauty',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            _categorySummary(beautyCount, totalScans),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF8A94A6),
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                ].divide(SizedBox(height: 12.0)),
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        ]
                            .divide(SizedBox(height: 16.0))
                            .addToStart(SizedBox(height: 20.0))
                            .addToEnd(SizedBox(height: 20.0)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16.0,
                          color: Color(0x0D000000),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 36.0,
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFF16A34A),
                                    size: 20.0,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Tips For You',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A2340),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Text(
                                    'Based on your scan history',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF8A94A6),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      width: 36.0,
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFEF3C7),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.local_cafe_outlined,
                                          color: Color(0xFFD97706),
                                          size: 18.0,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            latestIngredients.isEmpty
                                                ? 'Keep Scanning for Ingredient Insights'
                                                : 'Key ingredients in $latestProductName',
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            latestIngredients.isEmpty
                                                ? 'Scan at least one product to see dynamic ingredient insights here.'
                                                : latestIngredients.join(' | '),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF8A94A6),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ].divide(SizedBox(height: 2.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 12.0)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      width: 36.0,
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFF16A34A),
                                          size: 18.0,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current warnings',
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF1A2340),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            latestWarnings.isEmpty
                                                ? 'No warning data available from the latest scan yet.'
                                                : latestWarnings.join(' | '),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF8A94A6),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ].divide(SizedBox(height: 2.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 12.0)),
                                ),
                              ),
                            ),
                          ),
                        ]
                            .divide(SizedBox(height: 12.0))
                            .addToStart(SizedBox(height: 20.0))
                            .addToEnd(SizedBox(height: 20.0)),
                      ),
                    ),
                  ),
                ),
              ]
                  .divide(SizedBox(height: 20.0))
                  .addToStart(SizedBox(height: 16.0))
                  .addToEnd(SizedBox(height: 32.0)),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 10.0,
                color: Color(0x1A000000),
                offset: Offset(0.0, -2.0),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () async {
                    context.pushNamed(MainPageWidget.routeName);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        color: Color(0xFF57636C),
                        size: 28.0,
                      ),
                      Text(
                        'Home',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF57636C),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF57636C),
                        size: 28.0,
                      ),
                      Text(
                        'Scan',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF57636C),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    // Already on HealthInsightDashboard
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF1B5E20),
                        size: 28.0,
                      ),
                      Text(
                        'Insights',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF1B5E20),
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
                    context.pushNamed(HistoryPageWidget.routeName);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Color(0xFF57636C),
                        size: 28.0,
                      ),
                      Text(
                        'History',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF57636C),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: Color(0xFF57636C),
                        size: 28.0,
                      ),
                      Text(
                        'Profile',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF57636C),
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

class _CategoryRingPainter extends CustomPainter {
  const _CategoryRingPainter({
    required this.foodRatio,
    required this.skincareRatio,
    required this.beautyRatio,
  });

  final double foodRatio;
  final double skincareRatio;
  final double beautyRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final total = (foodRatio + skincareRatio + beautyRatio).clamp(0.0, double.infinity);
    final safeFood = total > 0 ? (foodRatio / total) : (1 / 3);
    final safeSkincare = total > 0 ? (skincareRatio / total) : (1 / 3);
    final safeBeauty = total > 0 ? (beautyRatio / total) : (1 / 3);

    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.20;
    final startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final foodSweep = safeFood * math.pi * 2;
    final skincareSweep = safeSkincare * math.pi * 2;
    final beautySweep = safeBeauty * math.pi * 2;

    paint.color = const Color(0xFF22C55E);
    canvas.drawArc(rect, startAngle, foodSweep, false, paint);

    paint.color = const Color(0xFFF59E0B);
    canvas.drawArc(rect, startAngle + foodSweep, skincareSweep, false, paint);

    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(
      rect,
      startAngle + foodSweep + skincareSweep,
      beautySweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryRingPainter oldDelegate) {
    return oldDelegate.foodRatio != foodRatio ||
        oldDelegate.skincareRatio != skincareRatio ||
        oldDelegate.beautyRatio != beautyRatio;
  }
}
