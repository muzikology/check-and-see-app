import '/flutter_flow/flutter_flow_icon_button.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'product_scanning_model.dart';
export 'product_scanning_model.dart';

/// Create a modern mobile app screen for scanning products.
///
/// App purpose:
/// Users scan food, skincare, hair, or beauty products to analyze ingredients
/// and health impact.
///
/// Design style:
/// Modern
/// Minimal
/// Premium
/// Inspired by Apple Health and Yuka
///
/// Layout:
///
/// Top App Bar
/// Title: Scan Product
///
/// Main section:
/// Large camera preview container
///
/// Inside the camera container:
/// Camera icon
/// Text: "Align product label within frame"
///
/// Below camera:
/// Primary button
/// Label: Scan Product
///
/// Secondary button
/// Label: Upload Photo
///
/// Footer section:
/// Tips card
///
/// Text:
/// Tips for best scan:
/// G�� Ensure good lighting
/// G�� Capture full ingredient list
/// G�� Avoid blurry images
///
/// Colors:
/// Primary: Deep green #1B5E20
/// Background: #F5F7F5
///
/// Use rounded cards and soft shadows.
class ProductScanningWidget extends StatefulWidget {
  const ProductScanningWidget({super.key});

  static String routeName = 'ProductScanning';
  static String routePath = 'productScanning';

  @override
  State<ProductScanningWidget> createState() => _ProductScanningWidgetState();
}

class _ProductScanningWidgetState extends State<ProductScanningWidget> {
  late ProductScanningModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  bool _isAnalyzing = false;
  ScanProductType _selectedProductType = ScanSession.productType;

  String get _scanLabel => _selectedProductType == ScanProductType.food
      ? 'Align food product label within frame'
      : 'Align beauty product label within frame';

    bool get _isBeautyMode => _selectedProductType == ScanProductType.beauty;
    Color get _accentColor =>
      _isBeautyMode ? const Color(0xFFB78466) : const Color(0xFFA07A5E);
    Color get _accentSoft =>
      _isBeautyMode ? const Color(0xFFE8D4C7) : const Color(0xFFE6D8CE);
    List<Color> get _heroGradient => _isBeautyMode
      ? const [Color(0xFFE1C5B3), Color(0xFFBE8F72)]
      : const [Color(0xFFDCCCBF), Color(0xFFB5967F)];

  String _bytesToDataUrl(Uint8List bytes) =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  Future<void> _saveScanRecord(ScanAnalysisResult result) async {
    final imageBytes = _selectedImageBytes;
    if (imageBytes == null || !loggedIn || currentUserUid.isEmpty) {
      return;
    }

    await ScansRecord.collection.add(
      createScansRecordData(
        owner: currentUserReference,
        productImage: _bytesToDataUrl(imageBytes),
        productName: result.productName,
        brandName: result.brandName,
        productType: result.productType.storageValue,
        ingredients: result.ingredients.join(', '),
        warnings: result.warnings,
        benefits: result.benefits,
        recommendation: result.recommendation,
        impactForUser: result.impactForUser,
        healthScore: result.healthScore.toString(),
        scanDate: getCurrentTimestamp,
        createdTime: getCurrentTimestamp,
        userId: currentUserUid,
        uid: currentUserUid,
        email: currentUserEmail,
        displayName: currentUserDisplayName,
        photoUrl: currentUserPhoto,
        phoneNumber: currentPhoneNumber,
      ),
    );
  }

  Future<void> _useImageForAnalysis() async {
    final imageBytes = _selectedImageBytes;
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please scan or upload an image first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isAnalyzing) {
      return;
    }

    safeSetState(() => _isAnalyzing = true);
    try {
      ProfilesRecord? profile;
      if (loggedIn && currentUserUid.isNotEmpty) {
        profile = await ProfilesRecord.getDocumentOnce(
          ProfilesRecord.collection.doc(currentUserUid),
        );
      }

      final analysis = await ScanAnalyzer.analyze(
        imageBytes: imageBytes,
        imagePath: _selectedImagePath,
        productType: _selectedProductType,
        profile: profile,
      );
      ScanSession.setProductType(_selectedProductType);
      ScanSession.updateAnalysis(imageBytes, analysis);
      if (!analysis.persistedByBackend) {
        await _saveScanRecord(analysis);
      }

      if (!mounted) return;
      context.pushNamed(ProductAnalysisWidget.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not analyze image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        safeSetState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _showRetakeReuploadOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('Retake with Camera'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Reupload from Device'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
          ],
        ),
      ),
    );

    if (action == 'camera') {
      await _showCameraModeOptions();
    } else if (action == 'gallery') {
      await _pickScanImage(ImageSource.gallery);
    }
  }

  Future<void> _showCameraModeOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_back_outlined),
              title: Text('Take product photo (rear camera)'),
              onTap: () => Navigator.of(context).pop('rear'),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_front_outlined),
              title: Text('Take selfie (front camera)'),
              onTap: () => Navigator.of(context).pop('front'),
            ),
          ],
        ),
      ),
    );

    if (action == 'rear') {
      await _pickScanImage(
        ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
    } else if (action == 'front') {
      await _pickScanImage(
        ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
    }
  }

  Future<void> _pickScanImage(
    ImageSource source, {
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 88,
      );
      if (pickedFile == null) {
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      safeSetState(() {
        _selectedImageBytes = imageBytes;
        _selectedImagePath = pickedFile.path;
      });
      ScanSession.setProductType(_selectedProductType);
      ScanSession.updateScan(imageBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image added to scan frame. Tap Use Image to analyze.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access camera/photos: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductScanningModel());
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
        backgroundColor: Color(0xFFF2F2F5),
        appBar: AppBar(
          backgroundColor: Color(0xFFF2F2F5),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 22.0,
            borderWidth: 0.0,
            buttonSize: 44.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1F2332),
              size: 24.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            'Scan Product',
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: Color(0xFF1F2332),
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
                  Icons.history_rounded,
                  color: Color(0xFF1F2332),
                  size: 24.0,
                ),
                onPressed: () async {
                  context.pushNamed(HistoryPageWidget.routeName);
                },
              ),
            ),
          ],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: const Color(0xFFE6E8EF),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FFButtonWidget(
                            onPressed: () {
                              safeSetState(
                                () => _selectedProductType = ScanProductType.food,
                              );
                              ScanSession.setProductType(ScanProductType.food);
                            },
                            text: 'Food products',
                            options: FFButtonOptions(
                              height: 42.0,
                              color: _selectedProductType == ScanProductType.food
                                  ? _accentColor
                                  : Colors.transparent,
                              textStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: _selectedProductType == ScanProductType.food
                                        ? Colors.white
                                        : const Color(0xFF475467),
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: FFButtonWidget(
                            onPressed: () {
                              safeSetState(
                                () => _selectedProductType = ScanProductType.beauty,
                              );
                              ScanSession.setProductType(ScanProductType.beauty);
                            },
                            text: 'Beauty products',
                            options: FFButtonOptions(
                              height: 42.0,
                              color: _selectedProductType == ScanProductType.beauty
                                  ? _accentColor
                                  : Colors.transparent,
                              textStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: _selectedProductType == ScanProductType.beauty
                                        ? Colors.white
                                        : const Color(0xFF475467),
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: Container(
                      width: double.infinity,
                      height: 380.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _heroGradient,
                          stops: [0.0, 1.0],
                          begin: AlignmentDirectional(-1.0, -1.0),
                          end: AlignmentDirectional(1.0, 1.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 28.0,
                            color: Color(0x1F1F2332),
                            offset: Offset(
                              0.0,
                              8.0,
                            ),
                          )
                        ],
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: _selectedImageBytes != null ? 0.9 : 0.45,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0.0),
                                child: _selectedImageBytes != null
                                    ? Image.memory(
                                        _selectedImageBytes!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        'https://images.unsplash.com/photo-1593699688785-f710412e7b21?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NzI3MjY2Njh8&ixlib=rb-4.1.0&q=80&w=1080',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _selectedImageBytes != null
                                      ? const [
                                          Color(0x1AFFFFFF),
                                          Color(0x331F2332),
                                          Color(0x5C1F2332),
                                        ]
                                      : (_isBeautyMode
                                          ? const [
                                              Color(0x52E1C5B3),
                                              Color(0x5EBE8F72),
                                              Color(0x731F2332),
                                            ]
                                          : const [
                                              Color(0x52DCCCBF),
                                              Color(0x5EB5967F),
                                              Color(0x731F2332),
                                            ]),
                                  stops: [0.0, 0.5, 1.0],
                                  begin: AlignmentDirectional(0.0, -1.0),
                                  end: AlignmentDirectional(0, 1.0),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52.0,
                                    height: 52.0,
                                    decoration: BoxDecoration(
                                      color: Color(0x66FFFFFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(0xCCFFFFFF),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 28.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _scanLabel,
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.openSans(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          shadows: const [
                                            Shadow(
                                              color: Color(0x661F2332),
                                              blurRadius: 8.0,
                                              offset: Offset(0.0, 2.0),
                                            ),
                                          ],
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ].divide(SizedBox(height: 12.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      FFButtonWidget(
                        onPressed: () async {
                          await _showCameraModeOptions();
                        },
                        text: _selectedProductType == ScanProductType.food
                            ? 'Scan Food Product'
                            : 'Scan Beauty Product',
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20.0,
                        ),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          iconColor: Colors.white,
                          color: _accentColor,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
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
                          await _pickScanImage(ImageSource.gallery);
                        },
                        text: _selectedProductType == ScanProductType.food
                            ? 'Upload Food Photo'
                            : 'Upload Beauty Photo',
                        icon: Icon(
                          Icons.upload_file_rounded,
                          size: 20.0,
                        ),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          iconColor: _accentColor,
                          color: Color(0xFFFFFFFF),
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: _accentColor,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: _accentColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      if (_selectedImageBytes != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: FFButtonWidget(
                                onPressed: _isAnalyzing
                                    ? null
                                    : () async {
                                        await _showRetakeReuploadOptions();
                                      },
                                text: 'Retake / Reupload',
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18.0,
                                ),
                                options: FFButtonOptions(
                                  height: 50.0,
                                  color: Color(0xFFF7F0EB),
                                  iconColor: _accentColor,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .fontStyle,
                                        ),
                                        color: _accentColor,
                                        letterSpacing: 0.0,
                                      ),
                                  borderSide: BorderSide(
                                    color: _accentSoft,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: FFButtonWidget(
                                onPressed: _isAnalyzing
                                    ? null
                                    : () async {
                                        await _useImageForAnalysis();
                                      },
                                text: _isAnalyzing
                                    ? 'Analyzing...'
                                    : 'Use Image',
                                icon: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18.0,
                                ),
                                options: FFButtonOptions(
                                  height: 50.0,
                                  color: _accentColor,
                                  iconColor: Colors.white,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .fontStyle,
                                        ),
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                      ),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ].divide(SizedBox(height: 12.0)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16.0,
                            color: Color(0x0F000000),
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
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF7F0EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.tips_and_updates_rounded,
                                      color: _accentColor,
                                      size: 18.0,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tips for best scan',
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF1F2332),
                                        fontSize: 15.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                            Divider(
                              height: 1.0,
                              thickness: 1.0,
                              color: Color(0xFFF0F0F0),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Ensure good lighting',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.openSans(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF333333),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 10.0)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  _selectedProductType == ScanProductType.food
                                      ? 'Capture full ingredient list'
                                      : 'Capture full product front and label',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.openSans(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF333333),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 10.0)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Avoid blurry images',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.openSans(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF333333),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 10.0)),
                            ),
                          ].divide(SizedBox(height: 10.0)),
                        ),
                      ),
                    ),
                  ),
                ]
                    .divide(SizedBox(height: 20.0))
                    .addToStart(SizedBox(height: 20.0))
                    .addToEnd(SizedBox(height: 32.0)),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 14.0),
          decoration: BoxDecoration(
            color: Colors.white,
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
            padding:
                const EdgeInsetsDirectional.fromSTEB(14.0, 10.0, 14.0, 10.0),
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
                              fontFamily: 'Inter',
                              color: const Color(0xFF667085),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
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
                          color: const Color(0xFFF2EBE5),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                          color: Color(0xFFB78466), size: 22.0),
                      ),
                      Text(
                        'Scan',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
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
