import 'package:flutter/material.dart';

/// Wraps a widget in a MaterialApp and Scaffold with a ListView.
/// This is useful for testing widgets that require a MaterialApp ancestor.
Widget buildWrappedWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        children: [
          child,
        ],
      ),
    ),
  );
}
