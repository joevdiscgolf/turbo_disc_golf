import 'dart:async';
import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/auth/components/apple_sign_in_button.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/screens/auth/components/auth_input_field.dart';
import 'package:turbo_disc_golf/screens/auth/components/google_sign_in_button.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

enum ButtonState { normal, loading, success, retry }

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/sign-up';
  static const String screenName = 'Sign Up';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = locator.get<AuthService>();
  final formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final LoggingServiceBase _logger;

  ButtonState _buttonState = ButtonState.normal;
  Timer? checkUsernameOnStoppedTyping;
  String? displayName;
  String? _email;
  String? _password;
  String? _confirmPassword;
  String? _errorText;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': SignUpScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('SignUpScreen');

    if (kDebugMode) {
      _emailController.text = 'test@gmail.com';
      _passwordController.text = 'Testing123!';
      _confirmPasswordController.text = 'Testing123!';
      _email = 'test@gmail.com';
      _password = 'Testing123!';
      _confirmPassword = 'Testing123!';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Scaffold(
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: 'ScoreSensei',
          titleIcon: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/icon/app_icon_clear_bg.png',
              width: 32,
              height: 32,
            ),
          ),
          titleStyle: GoogleFonts.exo2(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            color: SenseiColors.gray.shade600,
          ),
          hasBackButton: false,
        ),
        resizeToAvoidBottomInset: false,
        backgroundColor: SenseiColors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: _mainBody(context),
        ),
      ),
    );
  }

  Widget _mainBody(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInputField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: FlutterRemix.mail_line,
              keyboardType: TextInputType.emailAddress,
              onChanged: (String? value) => setState(() {
                _email = value;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 8),
            AuthInputField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: FlutterRemix.lock_line,
              obscureText: true,
              externalObscured: _isPasswordObscured,
              onToggleVisibility: _togglePasswordVisibility,
              onChanged: (String? value) => setState(() {
                _password = value;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 8),
            AuthInputField(
              controller: _confirmPasswordController,
              hintText: 'Confirm password',
              prefixIcon: FlutterRemix.lock_line,
              obscureText: true,
              externalObscured: _isPasswordObscured,
              showVisibilityToggle: false,
              onChanged: (String? value) => setState(() {
                _confirmPassword = value;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 24),
            _signUpButton(context),
            const SizedBox(height: 12),
            GoogleSignInButton(onPressed: _handleGoogleSignIn),
            const SizedBox(height: 12),
            AppleSignInButton(onPressed: _handleAppleSignIn),
            const SizedBox(height: 16),
            if (_errorText != null)
              Center(
                child: AutoSizeText(
                  _errorText!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            Text(
              'Already have an account?',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: SenseiColors.gray[400]),
            ),
            const SizedBox(height: 12),
            _signInButton(context),
          ],
        ),
      ),
    );
  }

  Widget _signInButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          _logger.track('Sign In Link Tapped');
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.transparent,
          child: Text(
            'Sign in',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: SenseiColors.blue,
              decoration: TextDecoration.underline,
              decorationColor: SenseiColors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _signUpButton(BuildContext context) {
    return PrimaryButton(
      loading: _buttonState == ButtonState.loading,
      disabled: _checkDisabled(),
      label: 'Sign up',
      backgroundColor: SenseiColors.blue,
      height: 56,
      width: double.infinity,
      onPressed: _signupPressed,
    );
  }

  Future<void> _signupPressed() async {
    _logger.track('Sign Up Button Tapped');

    setState(() => _errorText = null);
    HapticFeedback.lightImpact();
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorText = 'Please fill in all fields';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match';
      });
      return;
    }

    setState(() => _buttonState = ButtonState.loading);
    final bool signUpSuccess = await _authService.attemptSignUpWithEmail(
      email,
      password,
    );
    debugPrint('sign up success: $signUpSuccess');
    if (!mounted) return;

    if (!signUpSuccess) {
      setState(() {
        _buttonState = ButtonState.retry;
        _errorText = _authService.errorMessage.isNotEmpty
            ? _authService.errorMessage
            : 'Something went wrong. Please try again';
      });
    } else {
      setState(() => _buttonState = ButtonState.success);
    }
  }

  bool _checkDisabled() {
    if (kDebugMode) {
      return false;
    }
    return _password == null ||
        _password!.length < 8 ||
        _email == null ||
        _email!.isEmpty ||
        _confirmPassword == null ||
        _confirmPassword!.isEmpty ||
        _password != _confirmPassword;
  }

  Future<void> _handleGoogleSignIn() async {
    _logger.track('Google Sign In Button Tapped');

    setState(() {
      _errorText = null;
    });

    try {
      final bool success = await _authService.attemptSignInWithGoogle();

      if (!success && mounted) {
        setState(() {
          _errorText = _authService.errorMessage;
        });
      }
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      if (mounted) {
        setState(() {
          _errorText = 'Google sign-in failed. Please try again.';
        });
      }
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[SignUpScreen][_handleGoogleSignIn] exception',
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    _logger.track('Apple Sign In Button Tapped');

    setState(() {
      _buttonState = ButtonState.loading;
      _errorText = null;
    });

    try {
      final bool success = await _authService.attemptSignInWithApple();

      if (!success && mounted) {
        setState(() {
          _buttonState = ButtonState.retry;
          _errorText = _authService.errorMessage;
        });
      } else if (mounted) {
        setState(() => _buttonState = ButtonState.success);
      }
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      if (mounted) {
        setState(() {
          _buttonState = ButtonState.retry;
          _errorText = 'Apple sign-in failed. Please try again.';
        });
      }
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[SignUpScreen][_handleAppleSignIn] exception',
      );
    }
  }
}
