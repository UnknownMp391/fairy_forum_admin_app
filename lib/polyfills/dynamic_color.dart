import 'package:flutter/material.dart';

class DynamicColorBuilder extends StatelessWidget {
  final Widget Function(ColorScheme?, ColorScheme?) builder;

  const DynamicColorBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(null, null);
  }
}
