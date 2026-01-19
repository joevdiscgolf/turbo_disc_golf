import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLength = 32,
    this.externalObscured,
    this.onToggleVisibility,
    this.showVisibilityToggle = true,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Function(String?) onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLength;
  final bool? externalObscured;
  final VoidCallback? onToggleVisibility;
  final bool showVisibilityToggle;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(AuthInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalObscured != null &&
        widget.externalObscured != oldWidget.externalObscured) {
      _isObscured = widget.externalObscured!;
    }
  }

  void _toggleVisibility() {
    HapticFeedback.lightImpact();
    if (widget.onToggleVisibility != null) {
      widget.onToggleVisibility!();
    } else {
      setState(() {
        _isObscured = !_isObscured;
      });
    }
  }

  bool get _shouldObscure {
    return widget.externalObscured ?? _isObscured;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: widget.keyboardType,
      controller: widget.controller,
      autocorrect: false,
      obscureText: _shouldObscure,
      maxLines: 1,
      maxLength: widget.maxLength,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: SenseiColors.gray[50],
        hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Colors.grey[400],
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SenseiColors.gray[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: Icon(widget.prefixIcon, color: Colors.grey, size: 12),
        suffixIcon: widget.obscureText && widget.showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _shouldObscure
                      ? FlutterRemix.eye_off_line
                      : FlutterRemix.eye_line,
                  color: Colors.grey,
                  size: 18,
                ),
                onPressed: _toggleVisibility,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              )
            : null,
        counter: const Offstage(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
