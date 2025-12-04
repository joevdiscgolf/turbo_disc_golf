import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          locator.get<AuthService>().logout();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Text('Logout'),
        ),
      ),
    );
  }
}
