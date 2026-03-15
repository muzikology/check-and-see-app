import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/beauty/banuba_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow runtime fetching on web unless all required font files are bundled.
  GoogleFonts.config.allowRuntimeFetching = true;
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  // Banuba setup note: pass tokens using --dart-define to avoid storing
  // secrets in source control.
  if (!BanubaConfig.hasClientToken) {
    debugPrint(
      '[Banuba] Client token missing. Run with '
      '--dart-define=BANUBA_CLIENT_TOKEN=... to enable AR flow. '
      'BANUBA_AR_CLOUD_TOKEN is optional.',
    );
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;
  bool _amoledDark = FlutterFlowTheme.amoledDarkEnabled;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = checkAndSeeFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();

    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  ThemeMode get currentThemeMode => _themeMode;
  bool get amoledDarkEnabled => _amoledDark;

  void setAmoledDark(bool enabled) => safeSetState(() {
        _amoledDark = enabled;
        FlutterFlowTheme.saveAmoledDarkEnabled(enabled);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CheckAndSee',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF5C4033),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Times New Roman MT',
            fontSize: 32,
            color: Color(0xFF3B2F2F),
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Times New Roman MT',
            fontSize: 24,
            color: Color(0xFF3B2F2F),
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Perandory SemiCondensed',
            fontSize: 20,
            color: Color(0xFF5C4033),
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Perandory SemiCondensed',
            fontSize: 18,
            color: Color(0xFF5C4033),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Color(0xFF3B2F2F),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF3B2F2F),
          ),
          labelSmall: TextStyle(
            fontFamily: 'Sloop Script Pro',
            fontSize: 14,
            color: Color(0xFFC8A97E),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F0E6),
        cardColor: const Color(0xFFEDE3D1),
        cardTheme: const CardThemeData(
          color: Color(0xFFEDE3D1),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC8A97E)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F0E6),
          foregroundColor: Color(0xFF3B2F2F),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5C4033),
          secondary: Color(0xFFC8A97E),
          surface: Color(0xFFF5F0E6),
        ),
      ),
      darkTheme: _amoledDark
          ? ThemeData(
              brightness: Brightness.dark,
              useMaterial3: false,
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: const Color(0xFF000000),
              cardColor: const Color(0xFF0A0A0A),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFD1A98A),
                secondary: Color(0xFFC8A97E),
                surface: Color(0xFF000000),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF000000),
              ),
            )
          : ThemeData(
              brightness: Brightness.dark,
              useMaterial3: false,
            ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
