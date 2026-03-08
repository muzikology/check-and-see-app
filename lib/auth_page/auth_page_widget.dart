import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPageWidget extends StatefulWidget {
  const AuthPageWidget({super.key});

  static String routeName = 'AuthPage';
  static String routePath = 'authPage';

  @override
  State<AuthPageWidget> createState() => _AuthPageWidgetState();
}

class _AuthPageWidgetState extends State<AuthPageWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  String _skinType = 'Combination';
  String _dietType = 'Regular';
  String _goal = 'General Health';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: const Color(0xFF1B5E20), width: 1.2),
        ),
      );

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) {
      return;
    }

    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithEmail(
      context,
      _signInEmailController.text,
      _signInPasswordController.text,
    );
    if (user == null || !mounted) {
      return;
    }

    context.goNamedAuth(MainPageWidget.routeName, context.mounted);
  }

  Future<void> _createAccount() async {
    if (!_signUpFormKey.currentState!.validate()) {
      return;
    }
    if (_saving) {
      return;
    }

    safeSetState(() => _saving = true);
    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.createAccountWithEmail(
      context,
      _signUpEmailController.text,
      _signUpPasswordController.text,
    );

    if (user != null) {
      final now = getCurrentTimestamp;
      await currentUserReference?.set(
        createUsersRecordData(
          email: _signUpEmailController.text.trim(),
          name: _signUpNameController.text.trim(),
          displayName: _signUpNameController.text.trim(),
          userId: currentUserUid,
          uid: currentUserUid,
          createdAt: now,
          createdTime: now,
        ),
        SetOptions(merge: true),
      );

      await ProfilesRecord.collection.doc(currentUserUid).set(
            createProfilesRecordData(
              displayName: _signUpNameController.text.trim(),
              email: _signUpEmailController.text.trim(),
              userId: currentUserUid,
              uid: currentUserUid,
              skinType: _skinType,
              dietType: _dietType,
              weightGoal: _goal,
              allergies: 'None',
              skinConcerns: 'General care',
              createdTime: now,
            ),
            SetOptions(merge: true),
          );
    }

    if (!mounted) {
      return;
    }
    safeSetState(() => _saving = false);

    if (user == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created and profile saved.')),
    );
    context.goNamedAuth(MainPageWidget.routeName, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        body: SafeArea(
          top: true,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 16,
                            color: Color(0x14000000),
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Text(
                      'Use your account to test real Firebase persistence.',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontStyle:
                                  FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: const Color(0xFF4A5568),
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF1B5E20),
                      labelColor: const Color(0xFF1B5E20),
                      unselectedLabelColor: const Color(0xFF718096),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Create Account'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Form(
                            key: _signInFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _signInEmailController,
                                  decoration: _fieldDecoration('Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) => (value == null ||
                                          value.trim().isEmpty ||
                                          !value.contains('@'))
                                      ? 'Enter a valid email.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _signInPasswordController,
                                  decoration: _fieldDecoration('Password'),
                                  obscureText: true,
                                  validator: (value) =>
                                      (value == null || value.length < 6)
                                          ? 'Password must be at least 6 characters.'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                FFButtonWidget(
                                  onPressed: _signIn,
                                  text: 'Sign In',
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 48,
                                    color: const Color(0xFF1B5E20),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontStyle: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .fontStyle,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0,
                                        ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Form(
                            key: _signUpFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _signUpNameController,
                                  decoration: _fieldDecoration('Full Name'),
                                  validator: (value) => (value == null ||
                                          value.trim().length < 2)
                                      ? 'Enter your name.'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _signUpEmailController,
                                  decoration: _fieldDecoration('Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) => (value == null ||
                                          value.trim().isEmpty ||
                                          !value.contains('@'))
                                      ? 'Enter a valid email.'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _signUpPasswordController,
                                  decoration: _fieldDecoration('Password'),
                                  obscureText: true,
                                  validator: (value) =>
                                      (value == null || value.length < 6)
                                          ? 'Password must be at least 6 characters.'
                                          : null,
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: _skinType,
                                  decoration: _fieldDecoration('Skin Type'),
                                  items: const [
                                    DropdownMenuItem(value: 'Oily', child: Text('Oily')),
                                    DropdownMenuItem(value: 'Dry', child: Text('Dry')),
                                    DropdownMenuItem(
                                        value: 'Combination',
                                        child: Text('Combination')),
                                    DropdownMenuItem(
                                        value: 'Sensitive', child: Text('Sensitive')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      safeSetState(() => _skinType = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: _dietType,
                                  decoration: _fieldDecoration('Diet Type'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Regular', child: Text('Regular')),
                                    DropdownMenuItem(
                                        value: 'Vegetarian', child: Text('Vegetarian')),
                                    DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
                                    DropdownMenuItem(
                                        value: 'Low Carb', child: Text('Low Carb')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      safeSetState(() => _dietType = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: _goal,
                                  decoration: _fieldDecoration('Health Goal'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'General Health',
                                        child: Text('General Health')),
                                    DropdownMenuItem(
                                        value: 'Weight Loss', child: Text('Weight Loss')),
                                    DropdownMenuItem(
                                        value: 'Muscle Gain', child: Text('Muscle Gain')),
                                    DropdownMenuItem(
                                        value: 'Clear Skin', child: Text('Clear Skin')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      safeSetState(() => _goal = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                FFButtonWidget(
                                  onPressed: _saving ? null : _createAccount,
                                  text: 'Create Account',
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 48,
                                    color: const Color(0xFF1B5E20),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontStyle: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .fontStyle,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0,
                                        ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
