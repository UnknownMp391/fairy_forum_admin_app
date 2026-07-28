import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestPage extends ConsumerWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Title Data')),
      body: Center(
        child: Hero(
          tag: 'dick',
          child: Material(child: Text('Content')),
        ),
      ),
    );
  }
}
