import 'package:flutter/material.dart';

class GenericStatsScreen extends StatelessWidget {
  const GenericStatsScreen({super.key, required this.statsWidget});

  final Widget statsWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: statsWidget,
    );
  }
}
