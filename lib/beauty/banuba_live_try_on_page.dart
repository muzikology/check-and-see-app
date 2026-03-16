import 'package:banuba_sdk/banuba_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Live Banuba try-on screen backed by Banuba's native player widget.
class BanubaLiveTryOnPage extends StatefulWidget {
  const BanubaLiveTryOnPage({
    required this.clientToken,
    this.arCloudToken,
    this.overlayKeys = const <String>[],
    super.key,
  });

  final String clientToken;
  final String? arCloudToken;
  final List<String> overlayKeys;

  @override
  State<BanubaLiveTryOnPage> createState() => _BanubaLiveTryOnPageState();
}

class _BanubaLiveTryOnPageState extends State<BanubaLiveTryOnPage>
    with WidgetsBindingObserver {
  final BanubaSdkManager _banubaSdkManager = BanubaSdkManager();
  final EffectPlayerWidget _effectPlayerWidget = EffectPlayerWidget();

  String? _errorMessage;
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBanuba();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _banubaSdkManager.startPlayer();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _banubaSdkManager.stopPlayer();
    }
  }

  Future<void> _initBanuba() async {
    try {
      final token = widget.clientToken;
      if (token.trim().isEmpty) {
        throw StateError(
          'Banuba token is missing. Rebuild with --dart-define=BANUBA_CLIENT_TOKEN="<token>".',
        );
      }

      final granted = await _requestPermissions();
      if (!granted) {
        throw StateError('Camera and microphone permissions are required for AR.');
      }

      await _banubaSdkManager.initialize([], token, SeverityLevel.info);
      await _banubaSdkManager.openCamera();
      await _banubaSdkManager.attachWidget(_effectPlayerWidget.banubaId);
      await _banubaSdkManager.startPlayer();

      // Try common effect paths. Missing effects should not block camera launch.
      await _tryLoadEffect(widget.overlayKeys);

      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _tryLoadEffect(List<String> overlayKeys) async {
    final overlayEffectCandidates = overlayKeys
        .where((key) => key.trim().isNotEmpty)
        .map((key) => 'effects/${key.trim()}');

    final candidates = <String>[
      ...overlayEffectCandidates,
      'effects/Makeup',
      'effects/beauty',
      'effects/TrollGrandma',
    ];

    for (final effectPath in candidates) {
      try {
        await _banubaSdkManager.loadEffect(effectPath, false);
        return;
      } catch (_) {
        // Keep trying a fallback effect path.
      }
    }
  }

  Future<bool> _requestPermissions() async {
    final isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobileNative) {
      return false;
    }

    final requiredPermissions = <Permission>[
      Permission.camera,
      Permission.microphone,
    ];

    for (final permission in requiredPermissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
      }
      if (!status.isGranted) {
        return false;
      }
    }

    return true;
  }

  Future<void> _disposeBanuba() async {
    if (!_initialized) {
      return;
    }

    try {
      await _banubaSdkManager.stopPlayer();
    } catch (_) {}
    try {
      await _banubaSdkManager.closeCamera();
    } catch (_) {}
    try {
      await _banubaSdkManager.deinitialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeBanuba();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live AR Try-On'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _effectPlayerWidget),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xB0000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_errorMessage != null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xCC000000),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
