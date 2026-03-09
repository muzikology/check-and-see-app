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
/// • Ensure good lighting
/// • Capture full ingredient list
/// • Avoid blurry images
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
  bool _isAnalyzing = false;

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
        profile: profile,
      );
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
      safeSetState(() => _selectedImageBytes = imageBytes);
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
        backgroundColor: Color(0xFFF3FAF5),
        appBar: AppBar(
          backgroundColor: Color(0xFFF3FAF5),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 22.0,
            borderWidth: 0.0,
            buttonSize: 44.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1B5E20),
              size: 24.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            'Scan Product',
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: Color(0xFF1B5E20),
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
                  color: Color(0xFF1B5E20),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: Container(
                      width: double.infinity,
                      height: 380.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2FA34A), Color(0xFF1C7D33)],
                          stops: [0.0, 1.0],
                          begin: AlignmentDirectional(-1.0, -1.0),
                          end: AlignmentDirectional(1.0, 1.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 28.0,
                            color: Color(0x3D1C7D33),
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
                              opacity: _selectedImageBytes != null ? 1.0 : 0.6,
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
                                  colors: [
                                    _selectedImageBytes != null
                                    ? Color(0x55244A31)
                                    : Color(0x99307244),
                                    _selectedImageBytes != null
                                    ? Color(0x3338A850)
                                    : Color(0x6638A850),
                                    _selectedImageBytes != null
                                    ? Color(0x55244A31)
                                    : Color(0x99307244)
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                  begin: AlignmentDirectional(0.0, -1.0),
                                  end: AlignmentDirectional(0, 1.0),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, -0.2),
                              child: Container(
                                width: 260.0,
                                height: 260.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: Color(0xCCFFFFFF),
                                    width: 2.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment:
                                          AlignmentDirectional(-1.0, -1.0),
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 3.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment:
                                          AlignmentDirectional(1.0, -1.0),
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 3.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment:
                                          AlignmentDirectional(-1.0, 1.0),
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 3.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: AlignmentDirectional(1.0, 1.0),
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 3.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.7),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52.0,
                                    height: 52.0,
                                    decoration: BoxDecoration(
                                      color: Color(0x40FFFFFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(0x80FFFFFF),
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
                                    'Align product label within frame',
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
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
                        text: 'Scan Product',
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
                          color: Color(0xFF218E3B),
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.interTight(
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
                        text: 'Upload Photo',
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
                          iconColor: Color(0xFF1B5E20),
                          color: Color(0xFFFFFFFF),
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF1B5E20),
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: Color(0xFF1B5E20),
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
                                  color: Color(0xFFE8F5EE),
                                  iconColor: Color(0xFF1B5E20),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .fontStyle,
                                        ),
                                        color: Color(0xFF1B5E20),
                                        letterSpacing: 0.0,
                                      ),
                                  borderSide: BorderSide(
                                    color: Color(0xFF7EC8A0),
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
                                  color: Color(0xFF1B5E20),
                                  iconColor: Colors.white,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
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
                                    color: Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      Icons.tips_and_updates_rounded,
                                      color: Color(0xFF1B5E20),
                                      size: 18.0,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tips for best scan',
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF1B5E20),
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
                                    color: Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Ensure good lighting',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
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
                                    color: Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Capture full ingredient list',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
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
                                    color: Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Avoid blurry images',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
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
                    // Already on ProductScanning
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF1B5E20),
                        size: 28.0,
                      ),
                      Text(
                        'Scan',
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
                    context.pushNamed(HealthInsightDashboardWidget.routeName);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF57636C),
                        size: 28.0,
                      ),
                      Text(
                        'Insights',
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
