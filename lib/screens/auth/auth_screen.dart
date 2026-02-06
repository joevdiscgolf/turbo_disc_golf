import 'dart:developer';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turbo_disc_golf/components/backgrounds/animated_particle_background.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/liquid_glass_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/auth/components/google_sign_in_button.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

enum AuthMode { login, signUp }

enum ButtonState { normal, loading, success, retry }

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth';
  static const String screenName = 'Auth';

  const AuthScreen({super.key, this.initialMode = AuthMode.signUp});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = locator.get<AuthService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final LoggingServiceBase _logger;

  late AuthMode _currentMode;
  ButtonState _buttonState = ButtonState.normal;
  String? _email;
  String? _password;
  String? _confirmPassword;
  String? _errorText;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': AuthScreen.screenName,
    });

    _logger.logScreenImpression('AuthScreen');

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

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMode = _currentMode == AuthMode.login
          ? AuthMode.signUp
          : AuthMode.login;
      _errorText = null;
      _buttonState = ButtonState.normal;
    });
    _logger.track(
      _currentMode == AuthMode.login
          ? 'Switched To Login Mode'
          : 'Switched To Sign Up Mode',
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,

          body: Stack(
            fit: StackFit.expand,
            children: [const AnimatedParticleBackground(), _mainBody(context)],
          ),
        ),
      ),
    );
  }

  Widget _mainBody(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).viewPadding.top + 12,
          bottom: autoBottomPadding(context),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildGlassCard(context),
            const Spacer(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isLogin = _currentMode == AuthMode.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/app_icon_clear_bg.png',
                height: 64,
                width: 64,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ScoreSensei',
              style: GoogleFonts.exo2(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
                color: SenseiColors.gray[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isLogin ? 'Sign in' : 'Create your account',
            key: ValueKey(isLogin),
            style: TextStyle(color: SenseiColors.gray[600], fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    final bool isLogin = _currentMode == AuthMode.login;

    return LiquidGlassCard(
      opacity: 0.65,
      blurSigma: 24,
      borderOpacity: 0.4,
      accentColor: const Color(0xFF4ECDC4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassInputField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: FlutterRemix.mail_line,
            keyboardType: TextInputType.emailAddress,
            onChanged: (String? value) => setState(() {
              _email = value;
              _errorText = null;
            }),
          ),
          const SizedBox(height: 12),
          _buildGlassInputField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: FlutterRemix.lock_line,
            obscureText: true,
            showVisibilityToggle: true,
            onChanged: (String? value) => setState(() {
              _password = value;
              _errorText = null;
            }),
          ),
          if (!isLogin) ...[
            const SizedBox(height: 12),
            _buildGlassInputField(
              controller: _confirmPasswordController,
              hintText: 'Confirm password',
              prefixIcon: FlutterRemix.lock_line,
              obscureText: true,
              showVisibilityToggle: false,
              onChanged: (String? value) => setState(() {
                _confirmPassword = value;
                _errorText = null;
              }),
            ),
          ],
          if (isLogin) ...[
            const SizedBox(height: 8),
            _forgotPasswordButton(context),
          ],
          const SizedBox(height: 16),
          _primaryActionButton(context),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          GoogleSignInButton(onPressed: _handleGoogleSignIn),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Center(
              child: AutoSizeText(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required Function(String?) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showVisibilityToggle = false,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      controller: controller,
      autocorrect: false,
      obscureText: obscureText ? _isPasswordObscured : false,
      maxLines: 1,
      maxLength: 32,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: SenseiColors.darkGray,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: SenseiColors.gray[50],
        hintStyle: TextStyle(
          color: SenseiColors.gray[400],
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SenseiColors.gray[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
        ),
        prefixIcon: Icon(prefixIcon, color: SenseiColors.gray[400], size: 18),
        suffixIcon: obscureText && showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _isPasswordObscured
                      ? FlutterRemix.eye_off_line
                      : FlutterRemix.eye_line,
                  color: SenseiColors.gray[400],
                  size: 18,
                ),
                onPressed: _togglePasswordVisibility,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              )
            : null,
        counter: const Offstage(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _forgotPasswordButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _showForgotPasswordDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.transparent,
          child: Text(
            'Forgot password?',
            style: TextStyle(
              color: SenseiColors.gray[500],
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: SenseiColors.gray[500],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    _logger.track('Forgot Password Button Tapped');
    HapticFeedback.lightImpact();

    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text,
    );

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              title: Text(
                'Reset password',
                style: TextStyle(
                  color: SenseiColors.gray[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your email and we'll send you a link to reset your password.",
                    style: TextStyle(
                      color: SenseiColors.gray[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "If you don't see it, check your spam folder.",
                    style: TextStyle(
                      color: SenseiColors.gray[400],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: SenseiColors.gray[50],
                      hintStyle: TextStyle(
                        color: SenseiColors.gray[400],
                        fontSize: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: SenseiColors.gray[200]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF4ECDC4),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        FlutterRemix.mail_line,
                        color: SenseiColors.gray[400],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: SenseiColors.gray[500]),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final String email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            return;
                          }

                          HapticFeedback.lightImpact();
                          setDialogState(() => isLoading = true);

                          final bool success = await _authService
                              .sendPasswordResetEmail(email);

                          if (context.mounted) {
                            Navigator.pop(context, success);
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SenseiColors.gray[400],
                          ),
                        )
                      : const Text(
                          'Send link',
                          style: TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    // Defer dispose to allow dialog animation to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetEmailController.dispose();
    });

    if (result == true && mounted) {
      _logger.track('Password Reset Email Sent');
      locator.get<ToastService>().showSuccess(
        'Reset link sent! Check your inbox or spam folder.',
      );
    } else if (result == false && mounted) {
      _logger.track('Password Reset Email Failed');
      locator.get<ToastService>().showError(
        'Failed to send reset email. Please try again.',
      );
    }
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: SenseiColors.gray[200])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: SenseiColors.gray[400], fontSize: 14),
          ),
        ),
        Expanded(child: Container(height: 1, color: SenseiColors.gray[200])),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final bool isLogin = _currentMode == AuthMode.login;

    return GestureDetector(
      onTap: _toggleMode,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLogin ? "Don't have an account?" : 'Already have an account?',
              textAlign: TextAlign.center,
              style: TextStyle(color: SenseiColors.gray[500], fontSize: 15),
            ),
            const SizedBox(width: 4),
            Text(
              isLogin ? 'Sign up' : 'Sign in',
              style: TextStyle(
                color: SenseiColors.gray[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: SenseiColors.gray[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryActionButton(BuildContext context) {
    final bool isLogin = _currentMode == AuthMode.login;

    return PrimaryButton(
      loading: _buttonState == ButtonState.loading,
      disabled: _checkDisabled(),
      label: isLogin ? 'Sign in' : 'Sign up',
      labelColor: Colors.white,
      height: 56,
      width: double.infinity,
      gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
      onPressed: isLogin ? _handleLogin : _handleSignUp,
    );
  }

  bool _checkDisabled() {
    if (kDebugMode) {
      return false;
    }

    final bool baseCheck =
        _password == null ||
        _password!.length < 8 ||
        _email == null ||
        _email!.isEmpty;

    if (_currentMode == AuthMode.login) {
      return baseCheck;
    }

    return baseCheck ||
        _confirmPassword == null ||
        _confirmPassword!.isEmpty ||
        _password != _confirmPassword;
  }

  Future<void> _handleLogin() async {
    _logger.track('Sign In Button Tapped');

    if (_email == null || _password == null) {
      setState(() {
        _errorText = 'Missing email or password';
      });
      return;
    }

    setState(() {
      _buttonState = ButtonState.loading;
    });

    try {
      final bool success = await _authService.attemptSignInWithEmail(
        _email!,
        _password!,
      );

      if (!success && mounted) {
        setState(() {
          _buttonState = ButtonState.retry;
          _errorText = _authService.errorMessage.isNotEmpty
              ? _authService.errorMessage
              : 'Something went wrong. Please try again';
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
          _errorText = 'Something went wrong. Please try again';
        });
      }
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[AuthScreen][_handleLogin] exception',
      );
    }
  }

  Future<void> _handleSignUp() async {
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
        reason: '[AuthScreen][_handleGoogleSignIn] exception',
      );
    }
  }
}
