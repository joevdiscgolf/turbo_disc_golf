import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/auth/components/apple_sign_in_button.dart';
import 'package:turbo_disc_golf/screens/auth/components/auth_input_field.dart';
import 'package:turbo_disc_golf/screens/auth/components/google_sign_in_button.dart';
import 'package:turbo_disc_golf/screens/auth/sign_up_screen.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.isFirstRun = false});

  final bool isFirstRun;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = locator.get<AuthService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _email;
  String? _password;
  String _errorText = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _emailController.text = 'test@gmail.com';
      _passwordController.text = 'Testing123!';
      _email = 'test@gmail.com';
      _password = 'Testing123!';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Turbo Disc Golf',
        hasBackButton: false,
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: _mainBody(context),
    );
  }

  Widget _mainBody(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Padding(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).viewPadding.bottom,
          left: 16,
          right: 16,
        ),
        child: Column(
          children: [
            AuthInputField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: FlutterRemix.mail_line,
              keyboardType: TextInputType.emailAddress,
              onChanged: (String? value) => setState(() {
                _errorText = '';
                _email = value;
              }),
            ),
            const SizedBox(height: 8),
            AuthInputField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: FlutterRemix.lock_line,
              obscureText: true,
              onChanged: (String? value) => setState(() {
                _errorText = '';
                _password = value;
              }),
            ),
            const SizedBox(height: 24),
            _signInButton(context, true),
            const SizedBox(height: 12),
            const GoogleSignInButton(),
            const SizedBox(height: 12),
            const AppleSignInButton(),
            const SizedBox(height: 8),
            _forgotPasswordButton(context),
            const SizedBox(height: 36),
            Expanded(
              child: Center(
                child: Text(
                  _errorText,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            Text(
              "Don't have an account?",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: TurbColors.gray[400]),
            ),
            const SizedBox(height: 12),
            _signUpButton(context),
          ],
        ),
      ),
    );
  }

  Widget _forgotPasswordButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          // todo: implement
          // showDialog(
          //   context: context,
          //   builder: (dialogContext) => const ResetPasswordDialog(),
          // );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.transparent,
          child: Text(
            'Forgot password?',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: TurbColors.blue,
              decoration: TextDecoration.underline,
              decorationColor: TurbColors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _signUpButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => const SignUpScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.transparent,
          child: Text(
            'Sign up',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: TurbColors.blue,
              decoration: TextDecoration.underline,
              decorationColor: TurbColors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInButton(BuildContext context, bool signIn) {
    return PrimaryButton(
      disabled: _checkDisabled(),
      label: 'Sign in',
      labelColor: TurbColors.white,
      backgroundColor: Colors.blue,
      iconColor: TurbColors.white,
      height: 56,
      width: double.infinity,
      loading: _loading,
      onPressed: _signInPressed,
    );
  }

  bool _checkDisabled() {
    return _password == null ||
        _password!.length < 8 ||
        _email == null ||
        _email!.isEmpty;
  }

  void _signInPressed() async {
    if (_email == null || _password == null) {
      setState(() {
        _errorText = 'Missing username or password';
      });
      return;
    }
    setState(() {
      _loading = true;
    });

    bool signinSuccess;
    try {
      signinSuccess = await _authService.attemptSignInWithEmail(
        _email!,
        _password!,
      );
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      signinSuccess = false;
      setState(
        () => _errorText = _authService.errorMessage.isNotEmpty
            ? _authService.errorMessage
            : 'Something went wrong. Please try again',
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason:
            '[LoginScreen][_signinPressed] signinService.attemptSignInWithEmail() exception',
      );
    }

    if (!signinSuccess) {
      setState(() {
        _loading = false;
        _errorText = _authService.errorMessage;
      });
      return;
    }
    if (!mounted) return;
    // reloadCubits(context);
  }
}
