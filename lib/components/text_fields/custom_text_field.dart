import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.obscureText = false,
    this.hint,
    this.iconData,
    this.onInput,
    this.keyboardType,
    this.innerPadding = const EdgeInsets.only(
      left: 12,
      right: 12,
      top: 20,
      bottom: 8,
    ),
  });

  final TextEditingController controller;
  final bool obscureText;
  final String? hint;
  final IconData? iconData;
  final Function? onInput;
  final TextInputType? keyboardType;
  final EdgeInsets innerPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: TextFormField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        controller: controller,
        autocorrect: false,
        maxLines: 1,
        maxLength: 32,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: innerPadding,
          hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Colors.grey[400],
            fontSize: 18,
          ),
          enabledBorder: Theme.of(context).inputDecorationTheme.border,
          focusedBorder: Theme.of(context).inputDecorationTheme.border,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: iconData == null
                ? null
                : Icon(iconData, color: Colors.grey, size: 22),
          ),
          counter: const Offstage(),
        ),
        onChanged: (String text) {
          if (onInput != null) {
            onInput!(text);
          }
        },
      ),
    );
  }
}
